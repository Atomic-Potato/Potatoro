extends Node

var buffered_sessions: Array[Session]

func _ready():
	update_buffered_sessions()

func _process(delta):
	for session: Session in buffered_sessions:
		# TODO: Process each buffer
		if is_session_paused(session.ID):
			continue
		var remaining_time: int = get_session_id_remaining_time_in_seconds(session.ID)
		if remaining_time <= 0:
			end_buffered_session(session.ID)
			session.session_finish.emit()
			update_buffered_sessions()
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

func is_session_paused(session_id: int)-> bool:
	DatabaseManager.db.query("select EndDateTime from Sessions_Buffer where SessionID = " + str(session_id))
	if DatabaseManager.db.query_result.is_empty():
		push_error("Could not find session in buffer with ID " + str(session_id))
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
		select * from Presets_Buffer where CurrentSessionID = " + str(session_id)
	)
	if DatabaseManager.db.query_result.is_empty():
		push_error("Could not find buffered preset with the CurrentSessionID " + str(session_id))
		return null
	var preset: Preset = Preset.new(
		DatabaseManager.db.query_result[0].get("PresetID"),
		DatabaseManager.db.query_result[0].get("ID"),
		DatabaseManager.db.query_result[0].get("DefaultTagID"),
		DatabaseManager.db.query_result[0].get("Name"),
		DatabaseManager.db.query_result[0].get("SessionsCount"),
		DatabaseManager.db.query_result[0].get("SessionsDone"),
		DatabaseManager.db.query_result[0].get("SessionLength"),
		DatabaseManager.db.query_result[0].get("BreakLength"),
		DatabaseManager.db.query_result[0].get("isAutoStartBreak"),
		DatabaseManager.db.query_result[0].get("isAutoStartSession"),
	)
	return preset

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
	
	var start_time = DatabaseManager.db.query_result[0].get("StartDateTime")
	var current_time = DatabaseManager.get_datetime()
	DatabaseManager.db.query("
		select unixepoch('" + current_time + "') 
			- unixepoch('" + start_time + "') as ElapsedTime" 
	)
	var elapsed_time: int = DatabaseManager.db.query_result[0].get("ElapsedTime")
	return elapsed_time - get_pauses_length_in_seconds_buffered(session_id)

func get_session_id_remaining_time_in_seconds(session_id: int)-> int:
	var preset: Preset = get_session_buffered_preset(session_id)
	if preset == null:
		return 0
	var elapsed_time: int = get_session_id_elapsed_time_in_seconds(session_id)
	var remaining_time: int = preset.session_length * 60 - elapsed_time
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

# Retunrs the the session from the global array of buffered_sessions
func get_loaded_buffered_session(session_id)-> Session:
	for bs in buffered_sessions:
		if bs.ID == session_id:
			return bs # RETURN BULLSHIT YEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
	push_error("Session ID ", session_id, " not found loaded buffered sessions!")
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
	buffered_sessions = []
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
		buffered_sessions.append(session)

func start_buffered_session(preset: Preset)-> Session:
	var session: Session = Session.new()
	session.tag_ID = preset.default_tag_id
	session.start_date_time = DatabaseManager.get_datetime()
	session.end_date_time = DatabaseManager.get_datetime('+' + str(preset.session_length) + ' minutes')
	session.ID = SessionsManager.save_session(session)
	session.buffered_ID = SessionsManager.save_buffered_session(session) 
	return session

func end_buffered_session(session_id: int)-> Session:
	DatabaseManager.db.query("select ID from Sessions_Buffer where SessionID = " + str(session_id))
	if DatabaseManager.db.query_result.is_empty():
		push_error("Session ID " + str(session_id) + " not found in buffer.")
		return null
	
	# Saving the session from buffer
	var query = "
		update Sessions
		set "\
			+ "TagID = sb.TagID, "\
			+ "StartDateTime = sb.StartDateTime, "\
			+ "EndDateTime = '" + DatabaseManager.get_datetime() + "' " +\
		"from Sessions_Buffer sb 
		where Sessions.ID = " + str(session_id)
	print(query)
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
	
	# Add done session to preset buffer and reset non temp values
	query = "
		update Presets_Buffer
		set
			DefaultTagID = p.DefaultTagID,
			CurrentSessionID = null,
			SessionsDone = SessionsDone + 1,
			Name = p.Name,
			SessionsCount = p.SessionsCount,
			SessionLength = p.SessionLength,
			BreakLength = p.BreakLength,
			isAutoStartBreak = p.isAutoStartBreak, 
			isAutoStartSession = p.isAutoStartSession 
		from Presets p
		where CurrentSessionID = " + str(session_id)
	DatabaseManager.db.query(query)
	
	update_buffered_sessions()
	return get_session(session_id)

func restart_buffered_session(session_id: int)-> Session:
	DatabaseManager.db.query("select ID from Sessions_Buffer where SessionID = " + str(session_id))
	if DatabaseManager.db.query_result.is_empty():
		push_error("Session ID " + str(session_id) + " not found in buffer.")
		return null
	
	# Reseting start and end time
	#DatabaseManager.db.query("
		#update Sessions_Buffer
		#set 
			#StartDateTime = s.StartDateTime,
			#EndDateTime = s.EndDateTime
		#from Sessions s
		#where SessionID = " + str(session_id)
	#)
	
	# Deleting pauses
	DatabaseManager.db.query("
		delete from SessionPauses_Buffer
		where SessionID = " + str(session_id)
	)
	
	# Reseting preset buffer session length
	DatabaseManager.db.query("
		update Presets_Buffer
		set SessionLength = p.SessionLength
		from Presets p
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
	
	return updated_session

func save_session(session: Session):
	if session.ID: #Update
		DatabaseManager.db.query("select ID from Sessions where ID = " + str(session.ID))
		if DatabaseManager.db.query_result.is_empty():
			push_error("Session ID " + str(session.ID) + " not found.")
			return 0
			
		var query = "
			update Sessions_Buffer
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
