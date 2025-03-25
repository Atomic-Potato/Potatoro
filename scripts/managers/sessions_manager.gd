extends Node

var buffered_sessions: Array[Session]

func _ready():
	update_buffered_sessions()

func _process(_delta):
	for session: Session in buffered_sessions:
		if not is_session_buffered(session.ID) or is_session_paused(session.ID):
			continue
		var remaining_time: int = get_session_id_remaining_time_in_seconds(session.ID)
		if remaining_time <= 0:
			end_buffered_session(session.ID, true)
			#OS.alert("Session " + str(session.ID) + " has finished!", "Session " + str(session.ID))

func add_seconds_to_buffered_session_end_datetime(session_id: int, seconds: int):
	DatabaseManager.db.query("select EndDateTime from Sessions_Buffer where SessionID = " + str(session_id))
	if DatabaseManager.db.query_result.is_empty():
		push_error("Could not find session ID ", session_id, " in sessions buffer")
		return
	var new_datetime: String = DatabaseManager.get_datetime(
		('+' if seconds > 0 else '') + str(seconds) + ' seconds',
		DatabaseManager.db.query_result[0].get("EndDateTime"))
	var query = "
		update Sessions_Buffer
		set EndDateTime = case when datetime() >= '" + str(new_datetime) + "' 
			then datetime() else '" + str(new_datetime) + "' end
		where SessionID = '" + str(session_id) + "'"
	DatabaseManager.db.query(query)
	update_buffered_sessions()

func is_session_paused(session_id: int)-> bool:
	DatabaseManager.db.query("select EndDateTime from Sessions_Buffer where SessionID = " + str(session_id))
	if DatabaseManager.db.query_result.is_empty():
		push_warning("Could not find session in buffer with ID " + str(session_id))
		return false # idk if i should return true
	return DatabaseManager.db.query_result[0].get("EndDateTime") == null

func pause_session(session_id: int):
	DatabaseManager.db.query("select ID from Sessions_Buffer where SessionID  = " + str(session_id))
	if DatabaseManager.db.query_result.is_empty():
		push_error("Cannot pause session " + str(session_id) + ". It is not running or does not exist!")
		return
	
	var query = "
		update Sessions_Buffer
		set EndDateTime = null
		where SessionID = " + str(session_id) + ";
		
		insert into SessionPauses_Buffer(SessionID, StartDateTime, EndDateTime)
		values (" +\
			str(session_id) + ", "\
			+ "'" + DatabaseManager.get_datetime() + "', "\
			+ "NULL
		);
	"
	DatabaseManager.db.query(query)

func resume_session(session_id: int, preset_id: int):
	DatabaseManager.db.query("select ID from Sessions_Buffer where SessionID  = " + str(session_id))
	if DatabaseManager.db.query_result.is_empty():
		push_error("Cannot resume session " + str(session_id) + ". It is not running or does not exist!")
		return
	DatabaseManager.db.query("select ID from Presets_Buffer where PresetID  = " + str(preset_id))
	if DatabaseManager.db.query_result.is_empty():
		push_error("Cannot resume session " + str(session_id) + ". 
			Could not find its preset " + str(preset_id) + "in the presets buffer!")
		return
	
	var query = "
		update SessionPauses_Buffer
		set EndDateTime = '" + DatabaseManager.get_datetime() + "'
		where SessionID = " + str(session_id) + " and EndDateTime is NULL;
	"
	DatabaseManager.db.query(query)
	
	var remaining_time: int = get_session_id_remaining_time_in_seconds(session_id)
	query = "
		update Sessions_Buffer
		set EndDateTime = '" + DatabaseManager.get_datetime('+' + str(remaining_time) + ' seconds') + "'
		where SessionID = " + str(session_id) + ";
	"
	DatabaseManager.db.query(query)

func get_session_buffered_preset(session_id: int)-> Preset:
	DatabaseManager.db.query("
		select PresetID from Presets_Buffer where CurrentSessionID = " + str(session_id)
	)
	if DatabaseManager.db.query_result.is_empty():
		push_error("Could not find buffered preset with the CurrentSessionID " + str(session_id))
		return null
	return PresetsManager.get_preset(DatabaseManager.db.query_result[0].get("PresetID"))

func get_session_elapsed_time_in_seconds(session: Session)-> int:
	DatabaseManager.db.query("
		select unixepoch('" + DatabaseManager.get_datetime() +"') 
			- unixepoch('" + session.start_date_time + "') as ElapsedTime" 
	)
	var elapsed_time: int = DatabaseManager.db.query_result[0].get("ElapsedTime")
	return elapsed_time - get_pauses_length_in_seconds_buffered(session.ID)

func get_session_id_elapsed_time_in_seconds(session_id: int)-> int:
	var query = "select StartDateTime from Sessions_Buffer where SessionID = " + str(session_id)
	DatabaseManager.db.query(query)
	if DatabaseManager.db.query_result.is_empty():
		push_error("Cannot find session " + str(session_id) + "in the sessions buffer!")
		return 0 
	
	var session_start_time = DatabaseManager.db.query_result[0].get("StartDateTime")
	
	if is_session_paused(session_id):
		DatabaseManager.db.query("select * from SessionPauses_Buffer where SessionID = " + str(session_id))
		var pauses: Array[Dictionary] = DatabaseManager.db.query_result
		DatabaseManager.db.query("
			select 
				unixepoch('" + pauses[0].get("StartDateTime") + "')
				- unixepoch('" + session_start_time + "')
				as ElapsedTime
		")
		var elpased_time: int = DatabaseManager.db.query_result[0].get("ElapsedTime")
		for i in pauses.size() - 1: # NOTE: we skip the last pause since theres no session time after it
			DatabaseManager.db.query("
				select 
					unixepoch('" + pauses[i+1].get("StartDateTime") + "')
					- unixepoch('" + pauses[i].get("EndDateTime") + "')
					as ElapsedTime
			")
		return elpased_time
	else:
		var current_time = DatabaseManager.get_datetime()
		DatabaseManager.db.query("
			select unixepoch('" + current_time + "') 
				- unixepoch('" + session_start_time + "') as ElapsedTime" 
		)
		var elapsed_time: int = DatabaseManager.db.query_result[0].get("ElapsedTime")
		return elapsed_time - get_pauses_length_in_seconds_buffered(session_id)

func get_session_id_remaining_time_in_seconds(session_id: int)-> int:
	var preset: Preset = get_session_buffered_preset(session_id)
	if preset == null:
		return 0
	var elapsed_time: int = get_session_id_elapsed_time_in_seconds(session_id)
	# NOTE: i changed added_session_length to be in seconds for debugging, so i cant bother refactoring
	var remaining_time: int = (preset.session_length * 60 + preset.added_session_length) - elapsed_time
	return remaining_time

func get_pauses_length_in_seconds_buffered(session_id: int)-> int:
	DatabaseManager.db.query("select ID from SessionPauses_Buffer where SessionID = " + str(session_id))
	if DatabaseManager.db.query_result.is_empty():
		return 0
		
	DatabaseManager.db.query("
		select sum(unixepoch(EndDateTime) - unixepoch(StartDateTime)) as length
		from SessionPauses_Buffer 
		where SessionID = " + str(session_id)
	)
	if not DatabaseManager.db.query_result.is_empty():
		return DatabaseManager.db.query_result[0].get("length")
	return 0

func get_session(session_id: int)-> Session:
	DatabaseManager.db.query("select * from Sessions where ID = " + str(session_id))
	if DatabaseManager.db.query_result.is_empty():
		push_error("Session ID " + str(session_id) + " not found.")
		return null
		
	var result = DatabaseManager.db.query_result[0]
	var session: Session = Session.new(
		result.get("ID", 0),
		0,
		result.get("TagID", 0),
		result.get("StartDateTime", ""),
		result.get("EndDateTime", "")
	)
	
	DatabaseManager.db.query("select * from Sessions_Buffer where SessionID = " + str(session_id))
	if not DatabaseManager.db.query_result.is_empty():
		session.buffered_ID = DatabaseManager.db.query_result[0].get("ID")
	
	return session

# SUMMARY: Retunrs the the session from the global array of buffered_sessions
func get_loaded_buffered_session(session_id)-> Session:
	for bs in buffered_sessions:
		if bs.ID == session_id:
			return bs # RETURN BULLSHIT YEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
	push_warning("Session ID ", session_id, " not found loaded buffered sessions!")
	return null

func get_buffered_session(session_id: int)-> Session:
	DatabaseManager.db.query("select * from Sessions_Buffer where SessionID = " + str(session_id))
	if DatabaseManager.db.query_result.is_empty():
		push_error("Session ID " + str(session_id) + " not found in buffer.")
		return null
		
	var result = DatabaseManager.db.query_result[0]
	var session: Session = Session.new(
		result.get("SessionID", 0),
		result.get("ID", 0),
		result.get("TagID", 0),
		result.get("StartDateTime", ""),
		result.get("EndDateTime", "")
	)
	return session

func is_session_buffered(session_id: int)-> bool:
	DatabaseManager.db.query("select * from Sessions where ID = " + str(session_id))
	if DatabaseManager.db.query_result.is_empty():
		push_error("Session ID " + str(session_id) + " not found.")
		return false
		
	DatabaseManager.db.query("select * from Sessions_Buffer where SessionID = " + str(session_id))
	return not DatabaseManager.db.query_result.is_empty()

func update_buffered_sessions():
	# NOTE: I have done the update this way, 
	# since replacing the session objects disconnects any signals done to that object as well
	
	var new_buffered_sessions: Array[Session] = []
	var query = "select * from Sessions_Buffer"
	DatabaseManager.db.query(query)
	for i in DatabaseManager.db.query_result:
		var session: Session = Session.new(
			i.get("SessionID", 0),
			i.get("ID", 0),
			i.get("TagID", 0),
			i.get("StartDateTime", ""),
			i.get("EndDateTime", ""),
		)
		new_buffered_sessions.append(session)
	
	var removed_sessions: Array[Session] = []
	for bs in buffered_sessions:
		var is_found: bool
		for nbs in new_buffered_sessions:
			if nbs.ID == bs.ID:
				is_found = true
				break
		if not is_found:
			removed_sessions.append(bs)
	for rs in removed_sessions:
		buffered_sessions.remove_at(buffered_sessions.find(rs))
	
	for nbs in new_buffered_sessions:
		var is_updated: bool
		for bs in buffered_sessions:
			if bs.ID == nbs.ID:
				bs.buffered_ID = nbs.buffered_ID
				bs.tag_ID = bs.tag_ID
				bs.start_date_time = nbs.start_date_time
				bs.end_date_time = nbs.end_date_time
				is_updated = true
		if not is_updated:
			buffered_sessions.append(nbs)
		
func start_buffered_session(preset: Preset)-> Session:
	var session: Session = Session.new()
	session.tag_ID = preset.default_tag_id
	session.start_date_time = DatabaseManager.get_datetime()
	session.end_date_time = DatabaseManager.get_datetime('+' + str(preset.session_length) + ' minutes')
	session.ID = SessionsManager.save_session(session)
	session.buffered_ID = SessionsManager.save_buffered_session(session) 
	
	preset.current_session_id = session.ID
	preset.next_timer_type_id = PresetsManager.TimerTypes.Break
	PresetsManager.save_buffered_preset(preset)
	
	update_buffered_sessions()
	return get_loaded_buffered_session(session.ID)

func end_buffered_session(session_id: int, is_notify_timers_tracker: bool = false)-> Session:
	if not is_session_buffered(session_id):
		return null
	
	if is_session_paused(session_id): # i know this is a lazy solution, but why not 
		resume_session(session_id, get_session_buffered_preset(session_id).ID)
	
	# Saving the session from buffer
	var session: Session = get_buffered_session(session_id)
	var query = "
		update Sessions
		set
			TagID = "+ str(session.tag_ID) +",
			StartDateTime = '"+ str(session.start_date_time) +"',
			EndDateTime = '" + DatabaseManager.get_datetime() + "' 
		where Sessions.ID = " + str(session_id)
	DatabaseManager.db.query(query)
	query = "
		delete from Sessions_Buffer
		where SessionID = " + str(session_id)
	DatabaseManager.db.query(query)
	
	# Saving session pauses from buffer
	query = "
		insert into SessionPauses(SessionID, StartDateTime, EndDateTime)
		select SessionID, StartDateTime, EndDateTime
		from SessionPauses_Buffer
		where SessionID = " + str(session_id)
	DatabaseManager.db.query(query)
	query = "
		delete from SessionPauses_Buffer
		where SessionID = " + str(session_id)
	DatabaseManager.db.query(query)
	
	DatabaseManager.db.query("select PresetID from Presets_Buffer where CurrentSessionID =" + str(session_id))
	var preset: Preset = PresetsManager.get_preset(DatabaseManager.db.query_result[0].get("PresetID"), false)
	# Add done session to preset buffer and reset non temp values
	# NOTE: session length resets when a new session starts
	# it is kept in case of a restart at the finish screen
	query = "
		update Presets_Buffer
		set
			DefaultTagID = " + str(preset.default_tag_id) + ",
			CurrentSessionID = 0,
			SessionsDone = SessionsDone + 1,
			Name = '" + str(preset.name_) + "',
			SessionsCount = "+ str(preset.sessions_count) +",
			AddedSessionLength = 0,
			SessionLength = "+ str(preset.session_length) +",
			isAutoStartSession = "+ str(preset.is_auto_start_session) +" 
		where CurrentSessionID = " + str(session_id)
	DatabaseManager.db.query(query)
	
	session = get_loaded_buffered_session(session_id)
	if is_notify_timers_tracker:
		TimersTrackingManager.end_session(session, preset.ID)
	else:
		session.session_finish.emit()
	update_buffered_sessions()
	return get_session(session_id)

func restart_session(session_id: int, preset_id: int)-> Session:
	DatabaseManager.db.query("select ID from Sessions_Buffer where SessionID = " + str(session_id))
	if DatabaseManager.db.query_result.is_empty():
		DatabaseManager.db.query("select ID from Sessions where ID = " + str(session_id))
		if DatabaseManager.db.query_result.is_empty():
			push_error("Session ID " + str(session_id) + " not found.")
			return null
		DatabaseManager.db.query("select ID from Presets where ID = " + str(preset_id))
		if DatabaseManager.db.query_result.is_empty():
			push_error("Preset ID " + str(session_id) + " not found.")
			return null
		DatabaseManager.db.query("select ID from Presets_Buffer where PresetID = " + str(preset_id))
		if DatabaseManager.db.query_result.is_empty():
			push_error("Preset ID " + str(session_id) + " is not buffered (running).")
			return null
	else:
		push_error("Session ID " + str(session_id) + " is already buffered. Use restart_buffered_session().")
		return null
		
	# Deleting pauses
	DatabaseManager.db.query("
		delete from SessionPauses
		where SessionID = " + str(session_id)
	)
	
	# Reseting preset buffer session length and removing a finished session
	DatabaseManager.db.query("
		update Presets_Buffer
		set 
			AddedSessionLength = 0,
			SessionsDone = SessionsDone - 1
		where PresetID = " + str(preset_id)
	)

	# Updating session start and end times
	DatabaseManager.db.query("
		select SessionLength from Presets_Buffer where PresetID = " + str(preset_id))
	var session_length = str(DatabaseManager.db.query_result[0].get("SessionLength"))
	var updated_session = get_session(session_id)
	updated_session.start_date_time = DatabaseManager.get_datetime()
	updated_session.end_date_time = DatabaseManager.get_datetime('+' + session_length + ' minutes')
	save_session(updated_session)
	save_buffered_session(updated_session)
	
	# Setting the current session for the preset buffer
	DatabaseManager.db.query("
		update Presets_Buffer
		set CurrentSessionID = " + str(updated_session.ID) + "
		where PresetID = " + str(preset_id)
	)
	
	update_buffered_sessions()
	return get_loaded_buffered_session(updated_session.ID)

func restart_buffered_session(session_id: int)-> Session:
	if not is_session_buffered(session_id):
		return null
	
	if is_session_paused(session_id): # i know this is a lazy solution, but why not 
		resume_session(session_id, get_session_buffered_preset(session_id).ID)
	
	# Deleting pauses
	DatabaseManager.db.query("
		delete from SessionPauses_Buffer
		where SessionID = " + str(session_id)
	)
	
	# Reseting preset buffer session length
	DatabaseManager.db.query("
		update Presets_Buffer
		set AddedSessionLength = 0
		where CurrentSessionID = " + str(session_id)
	)
	
	# Updating session start and end times
	DatabaseManager.db.query("
		select SessionLength from Presets_Buffer where CurrentSessionID = " + str(session_id))
	var session_length = str(DatabaseManager.db.query_result[0].get("SessionLength"))
	
	var updated_session = get_session(session_id)
	updated_session.start_date_time = DatabaseManager.get_datetime()
	updated_session.end_date_time = DatabaseManager.get_datetime('+' + session_length + ' minutes')
	save_session(updated_session)
	save_buffered_session(updated_session) 
	
	update_buffered_sessions()
	return get_loaded_buffered_session(updated_session.ID)

func save_session(session: Session):
	if session.ID: #Update
		DatabaseManager.db.query("select ID from Sessions where ID = " + str(session.ID))
		if DatabaseManager.db.query_result.is_empty():
			push_error("Session ID " + str(session.ID) + " not found.")
			return 0
			
		var query = "
			update Sessions
			set "\
				+ "TagID = " + str(session.tag_ID)+ ", "\
				+ "StartDateTime = '" + str(session.start_date_time) + "', "\
				+ "EndDateTime = '" + str(session.end_date_time) + "' " +\
			"where ID = " + str(session.ID)
		
		DatabaseManager.db.query(query)
		return session.ID
	else: #Insert
		var query = "
			insert into Sessions(TagID, StartDateTime, EndDateTime)
			values("\
				+ str(session.tag_ID)+ ", "\
				+ "'" + str(session.start_date_time) + "', "\
				+ "'" + str(session.end_date_time) + "'" +\
			")
		"
		#print(query)
		DatabaseManager.db.query(query)
		return DatabaseManager.db.last_insert_rowid

func save_buffered_session(session: Session)-> int:
	var buffered_ID: int
	if session.buffered_ID: #Update
		DatabaseManager.db.query("select ID from Sessions_Buffer where ID = " + str(session.buffered_ID))
		if DatabaseManager.db.query_result.is_empty():
			push_error("Buffered session ID " + str(session.buffered_ID) + " not found in buffer.")
			return 0
			
		var query = "
			update Sessions_Buffer
			set "\
				+ "TagID = " + str(session.tag_ID)+ ", "\
				+ "StartDateTime = '" + str(session.start_date_time) + "', "\
				+ "EndDateTime = '" + str(session.end_date_time) + "' " +\
			"where ID = " + str(session.buffered_ID)
		DatabaseManager.db.query(query)
		buffered_ID = session.buffered_ID
	else: #Insert
		var query = "
			insert into Sessions_Buffer(SessionID, TagID, StartDateTime, EndDateTime)
			values("\
				+ str(session.ID) + ", "\
				+ str(session.tag_ID)+ ", "\
				+ "'" + str(session.start_date_time) + "', "\
				+ "'" + str(session.end_date_time) + "'" +\
			")
		"
		#print(query)
		DatabaseManager.db.query(query)
		buffered_ID = DatabaseManager.db.last_insert_rowid
	
	update_buffered_sessions()
	return buffered_ID
