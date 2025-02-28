extends Node

func is_in_session(preset_id: int)-> bool:
	if not is_preset_id_buffered(preset_id):
		return false
	
	DatabaseManager.db.query("
		select CurrentSessionID, BreakEndDateTime from Presets_Buffer where PresetID = " 
		+ str(preset_id))
	if DatabaseManager.db.query_result[0].get("CurrentSessionID"):
		if DatabaseManager.db.query_result[0].get("BreakEndDateTime"):
			push_error("DANGER: Preset is in session and in break at the same time!")
			return false
		return true 
	return false

func is_in_break(preset_id: int)-> bool:
	if not is_preset_id_buffered(preset_id):
		return false
	
	DatabaseManager.db.query("
		select CurrentSessionID, BreakEndDateTime from Presets_Buffer where PresetID = " 
		+ str(preset_id))	
	if DatabaseManager.db.query_result[0].get("BreakEndDateTime"):
		if DatabaseManager.db.query_result[0].get("CurrentSessionID"):
			push_error("DANGER: Preset is in session and in break at the same time!")
			return false
		return true 
	return false

func is_preset_break_paused(preset: Preset)-> bool:
	if not preset:
		push_warning("Cant check pause status for a null preset")
		return false
	# NOTE: if the break end datetime contains an int, then it is paused and the remaining time
	# in seconds is stored in its place
	return preset.break_end_datetime.is_valid_int()

func is_preset_id_break_paused(preset_id: int)-> bool:
	if not is_preset_id_buffered(preset_id):
		return false
	
	DatabaseManager.db.query("
		select BreakEndDateTime from Presets_Buffer where PresetID = " + str(preset_id))
	return DatabaseManager.db.query_result[0].get("BreakEndDateTime").is_valid_int()

func is_preset_id_exists(preset_id: int, is_push_error: bool = true):
	DatabaseManager.db.query("select ID from Presets where ID = " + str(preset_id))
	if DatabaseManager.db.query_result.is_empty():
		if is_push_error:
			push_error("Cannot find preset ID ", preset_id)
		return false
	return true

func is_preset_id_buffered(preset_id: int, is_push_error: bool = true):
	if not is_preset_id_exists(preset_id, is_push_error):
		return false
	
	DatabaseManager.db.query("
		select ID from Presets_Buffer where PresetID = " + str(preset_id))
	if DatabaseManager.db.query_result.is_empty():
		push_warning("Preset ID ", preset_id, " is not buffered")
		return false
	return true

func start_preset_id_break(preset_id: int, break_length_minutes: int = -1, next_session_length: int = -1)-> Preset:
	if not is_preset_id_buffered(preset_id):
		return null
	if is_in_session(preset_id):
		push_error("Preset is still in session, end buffered session to start break!")
		return get_preset(preset_id)
	if is_in_break(preset_id):
		push_error("Preset is already in break!")
		return get_preset(preset_id)
	
	if break_length_minutes < 0:
		DatabaseManager.db.query(
			"select BreakLength from Presets where ID = " + str(preset_id))
		break_length_minutes = DatabaseManager.db.query_result[0].get("BreakLength")
	if next_session_length < 0:
		DatabaseManager.db.query(
			"select SessionLength from Presets where ID = " + str(preset_id))
		next_session_length = DatabaseManager.db.query_result[0].get("SessionLength")
		
	DatabaseManager.db.query("
		update Presets_Buffer
		set 
			BreakEndDateTime = '" + DatabaseManager.get_datetime('+' + str(break_length_minutes) + ' minutes') + "',
			SessionLength = " + str(next_session_length) + "
		where PresetID = " + str(preset_id)
	)
	
	return get_preset(preset_id)

func pause_preset_id_break(preset_id: int)-> Preset:
	if not is_preset_id_buffered(preset_id):
		return null
	if is_preset_id_break_paused(preset_id):
		push_error("Cannot pause preset ID ", preset_id, " break, since it is already paused!")
		return get_preset(preset_id)
	
	DatabaseManager.db.query(
		"select BreakEndDateTime from Presets_Buffer where PresetID = " + str(preset_id)
	)
	var end_datetime = DatabaseManager.db.query_result[0].get("BreakEndDateTime")
	var remaining_seconds: int = DatabaseManager.get_datetimes_seconds_difference(
		end_datetime, DatabaseManager.get_datetime()
	) 
	if remaining_seconds < 0: 
		remaining_seconds = 0
		push_warning(
			"Paused break has a negative remaining time, setting remaining time to 0 instead.")
	
	DatabaseManager.db.query("
		update Presets_Buffer
		set BreakEndDateTime = " + str(remaining_seconds) + "
		where PresetID = " + str(preset_id)
	)
	return get_preset(preset_id)

func resume_preset_id_break(preset_id: int)-> Preset:
	if not is_preset_id_buffered(preset_id):
		return null
	if not is_preset_id_break_paused(preset_id):
		push_error("Cannot resume preset ID ", preset_id, " break, since it is already running!")
		return get_preset(preset_id)
	
	# Remaining seconds, when paused, is stored in BreakEndDateTime
	DatabaseManager.db.query(
		"select BreakEndDateTime from Presets_Buffer where PresetID = " + str(preset_id)
	)
	var remaining_seconds: int = int(DatabaseManager.db.query_result[0].get("BreakEndDateTime"))
	var new_end_datetime: String = DatabaseManager.get_datetime(
		'+' + str(remaining_seconds) + ' seconds')
	DatabaseManager.db.query(
		"update Presets_Buffer
		set BreakEndDateTime = '" + new_end_datetime + "'
		where PresetID = " + str(preset_id)
	)
	return get_preset(preset_id)
	

func get_presets() -> Array[Preset]:
	DatabaseManager.db.query("
		SELECT 
			p.ID,
			pb.ID AS BufferID,
			COALESCE(pb.DefaultTagID, p.DefaultTagID) AS DefaultTagID,
			COALESCE(pb.Name, p.Name) AS Name,
			COALESCE(pb.SessionsCount, p.SessionsCount) AS SessionsCount,
			pb.SessionsDone AS SessionsDone,
			COALESCE(pb.SessionLength, p.SessionLength) AS SessionLength,
			pb.AddedSessionLength AddedSessionLength,
			COALESCE(pb.BreakLength, p.BreakLength) AS BreakLength,
			pb.BreakEndDateTime as BreakEndDateTime,
			COALESCE(pb.isAutoStartBreak, p.isAutoStartBreak) AS isAutoStartBreak,
			COALESCE(pb.isAutoStartSession, p.isAutoStartSession) AS isAutoStartSession
		FROM 
			Presets p
			LEFT JOIN Presets_Buffer pb ON p.ID = pb.PresetID
	")
	
	var presets: Array[Preset] = []
	for i in DatabaseManager.db.query_result:
		var preset = Preset.new(
			i.get("ID", 0),
			i.get("BufferID", 0) if i.get("BufferID") else 0,
			i.get("DefaultTagID", 0) if i.get("DefaultTagID") else  0,
			str(i.get("Name", "[UNKNOWN]")),
			i.get("SessionsCount", 0),
			i.get("SessionsDone", 0) if i.get("SessionsDone") else 0,
			i.get("SessionLength", 0),
			i.get("BreakLength", 0),
			i.get("isAutoStartBreak", false),
			i.get("isAutoStartSession", false),
			i.get("AddedSessionLength", 0) if i.get("AddedSessionLength") else 0,
			i.get("BreakEndDateTime", "") if i.get("BreakEndDateTime") else "",
		)
		presets.append(preset)
	return presets

#func set_preset_current_session_ID(preset: Preset, session: Session)-> Preset:
	#var query = "
		#update Presets_Buffer
		#set CurrentSessionID = " + str(session.ID) + " 
		#where PresetID = " + str(preset.ID)
	#preset.current_session_ID = session.ID
	#return preset 

func get_preset_current_session_ID(preset: Preset)-> int:
	var query = "
		select CurrentSessionID 
		from Presets_Buffer 
		where ID = " + str(preset.buffer_ID)
	DatabaseManager.db.query(query)
	if not DatabaseManager.db.query_result.is_empty():
		var current_session_id = DatabaseManager.db.query_result[0].get("CurrentSessionID")
		return current_session_id if current_session_id else 0
	return 0

func get_preset(preset_id: int)-> Preset:
	DatabaseManager.db.query("select * from Presets_Buffer where PresetID = " + str(preset_id))
	if not DatabaseManager.db.query_result.is_empty():
		return Preset.new(
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
			DatabaseManager.db.query_result[0].get("AddedSessionLength"),
			DatabaseManager.db.query_result[0].get("BreakEndDateTime"),
		)
	DatabaseManager.db.query("select * from Presets where ID = " + str(preset_id))
	if not DatabaseManager.db.query_result.is_empty():
		return Preset.new(
			DatabaseManager.db.query_result[0].get("ID"),
			0,
			DatabaseManager.db.query_result[0].get("DefaultTagID"),
			DatabaseManager.db.query_result[0].get("Name"),
			DatabaseManager.db.query_result[0].get("SessionsCount"),
			0,
			DatabaseManager.db.query_result[0].get("SessionLength"),
			DatabaseManager.db.query_result[0].get("BreakLength"),
			DatabaseManager.db.query_result[0].get("isAutoStartBreak"),
			DatabaseManager.db.query_result[0].get("isAutoStartSession"),
			0,
			''
		)
	push_error("Cant find preset with ID " + str(preset_id))
	return null

# creates a new preset with the provided values and returns its id
# if the id is provided in the preset, then it will update
func save_preset(preset: Preset)-> int: # use save_buffered_preset to create a new buffered preset
	if preset.ID: # Update
		DatabaseManager.db.query("select ID from Presets where ID = " + str(preset.ID))
		if DatabaseManager.db.query_result.is_empty():
			push_error("Preset ID " + str(preset.ID) + " not found.")
			return 0
		
		var query = "
			update Presets
			set "\
				+ "DefaultTagID = " + str(preset.default_tag_id) + ", "\
				+ "Name = '" + preset.name_ + "', "\
				+ "SessionsCount = " + str(preset.sessions_count)  + ", "\
				+ "SessionLength = " + str(preset.session_length) + ", "\
				+ "BreakLength = " + str(preset.break_length) + ", "\
				+ "isAutoStartBreak = " + str(int(preset.is_auto_start_break)) + ", "\
				+ "isAutoStartSession = " + str(int(preset.is_auto_start_session)) + " " +\
			"where ID = " + str(preset.ID)
		DatabaseManager.db.query(query)
		#print(query)
		return preset.ID
	else: # Insert
		var query = "
			insert into Presets
				(DefaultTagID, Name, SessionsCount, SessionLength, BreakLength, isAutoStartBreak, isAutoStartSession)
			values ("\
				+ str(preset.default_tag_id) + ", "\
				+ "'" + preset.name_ + "', "\
				+ str(preset.sessions_count) + ", "\
				+ str(preset.session_length) + ", "\
				+ str(preset.break_length) + ", "\
				+ str(preset.is_auto_start_break) + ", "\
				+ str(preset.is_auto_start_session) \
		+ ")"
		DatabaseManager.db.query(query)
		#print(query)
		return DatabaseManager.db.last_insert_rowid

# creates a new buffered preset with the provided values and returns its id
# if the id is provided in the preset, then it will update
func save_buffered_preset(preset: Preset, current_session_id: int)-> int:
	if preset.buffer_ID: # Update
		DatabaseManager.db.query("select ID from Presets_Buffer where PresetID = " + str(preset.ID))
		if DatabaseManager.db.query_result.is_empty():
			push_error("Preset ID " + str(preset.ID) + " not found in buffer.")
			return 0
		if current_session_id != 0:
			DatabaseManager.db.query("select ID from Sessions_Buffer where SessionID = " + str(current_session_id))
			if DatabaseManager.db.query_result.is_empty():
				push_error("Current Session ID " + str(current_session_id) + " not found in sessions buffer.")
				return 0
			
		var query = "
			update Presets_Buffer
			set "\
				+ "PresetID = " + str(preset.ID) + ", "\
				+ "DefaultTagID = " + str(preset.default_tag_id) + ", "\
				+ "CurrentSessionID = " + str(current_session_id) + ", "\
				+ "Name = '" + preset.name_ + "', "\
				+ "SessionsCount = " + str(preset.sessions_count)  + ", "\
				+ "SessionsDone = " + str(preset.sessions_done)  + ", "\
				+ "SessionLength = " + str(preset.session_length) + ", "\
				+ "AddedSessionLength = " + str(preset.added_session_length) + ", "\
				+ "BreakLength = " + str(preset.break_length) + ", "\
				+ "BreakEndDateTime = '" + str(preset.break_end_datetime) + "', "\
				+ "isAutoStartBreak = " + str(int(preset.is_auto_start_break)) + ", "\
				+ "isAutoStartSession = " + str(int(preset.is_auto_start_session)) + " " +\
			"where ID = " + str(preset.buffer_ID)
		DatabaseManager.db.query(query)
		#print(query)
		return preset.buffer_ID
	else: # Insert
		var query = "
			insert into Presets_Buffer
				(PresetID, DefaultTagID, CurrentSessionID, Name, SessionsCount, SessionsDone,
				SessionLength, AddedSessionLength, BreakLength, BreakEndDateTime,
				isAutoStartBreak, isAutoStartSession)
			values ("\
				+ str(preset.ID) + ", "\
				+ str(preset.default_tag_id) + ", "\
				+ str(current_session_id) + ", "\
				+ "'" + preset.name_ + "', "\
				+ str(preset.sessions_count) + ", "\
				+ str(preset.sessions_done) + ", "\
				+ str(preset.session_length) + ", "\
				+ str(preset.added_session_length) + ", "\
				+ str(preset.break_length) + ", "\
				+ "'" + preset.break_end_datetime + "',"\
				+ str(preset.is_auto_start_break) + ", "\
				+ str(preset.is_auto_start_session) + " " \
		+ ")"
		DatabaseManager.db.query(query)
		#print(query)
		return DatabaseManager.db.last_insert_rowid

# force deleting deletes any running session that belongs to this preset
func delete_preset(preset_id: int, is_force_delete: bool = false):
	if not is_force_delete:
		DatabaseManager.db.query("
			select ID from Presets_Buffer where PresetID = " + str(preset_id))
		if not DatabaseManager.db.query_result.is_empty():
			push_error("Cannot delete preset that is buffered. Use force delete or question your life choices :D")
			return
		DatabaseManager.db.query("delete from Presets where ID = " + str(preset_id))
	else:
		DatabaseManager.db.query("
			select CurrentSessionID from Presets_Buffer where PresetID = " + str(preset_id))
		var current_session_id = DatabaseManager.db.query_result[0].get("CurrentSessionID")
		if current_session_id:
			DatabaseManager.db.query("
				delete from SessionPauses_Buffer 
				where SessionID = " + str(current_session_id) + ";
				delete from Sessions_Buffer
				where SessionID = " + str(current_session_id) + ";
				delete from Sessions
				where ID = " + str(current_session_id) + ";"
			)
		DatabaseManager.db.query("
			delete from Presets_Buffer
			where PresetID = " + str(preset_id) + ";
			delete from Presets
			where ID = " + str(preset_id) + ";"
		)

# DEPRECATED i was gonna use this, but then i came up with this bullshit rule of separating
# each manager logic to remove dependency, so now a lot of preset related stuff are now coded
# into the session manage, i may 
# this function resets all the values except SessionsDone
func reset_preset_buffer_non_temp_values(preset_id: int)-> Preset:
	DatabaseManager.db.query("select ID from Presets_Buffer where PresetID = " + str(preset_id))
	if DatabaseManager.db.query_result.is_empty():
		push_error("Cannot reset preset buffer. ID ", preset_id, " not found!")
		return null
	
	DatabaseManager.db.query("
		update Presets_Buffer
		set
			DefaultTagID = p.DefaultTagID,
			CurrentSessionID = null,
			Name = p.Name,
			SessionsCount = p.SessionsCount,
			SessionLength = p.SessionLength,
			BreakLength = p.BreakLength,
			isAutoStartBreak = p.isAutoStartBreak, 
			isAutoStartSession = p.isAutoStartSession 
		from Presets p
		where PresetID = " + str(preset_id) 
	)
	
	return get_preset(preset_id)


















