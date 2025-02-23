extends Node


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


















