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
			COALESCE(pb.BreakLength, p.BreakLength) AS BreakLength,
			COALESCE(pb.isAutoStartBreak, p.isAutoStartBreak) AS isAutoStartBreak,
			COALESCE(pb.isAutoStartSession, p.isAutoStartSession) AS isAutoStartSession
		FROM 
			Presets p
			LEFT JOIN Presets_Buffer pb ON p.ID = pb.PresetID
	")
	
	var presets: Array[Preset]
	for i in DatabaseManager.db.query_result:
		var preset = Preset.new()
		preset.ID = i.get("ID", 0)
		preset.buffer_ID = i.get("BufferID", 0) if i.get("BufferID") else 0
		preset.default_tag_id = i.get("DefaultTagID", 0) if i.get("DefaultTagID") else  0
		preset.name_ = str(i.get("Name", "[UNKNOWN]"))
		preset.sessions_count = i.get("SessionsCount", 0)
		preset.sessions_done = i.get("SessionsDone", 0) if i.get("SessionsDone") else 0
		preset.session_length = i.get("SessionLength", 0)
		preset.break_length = i.get("BreakLength", 0)
		preset.is_auto_start_break = i.get("isAutoStartBreak", false)
		preset.is_auto_start_session = i.get("isAutoStartSession", false)
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
		return DatabaseManager.db.query_result[0].get("CurrentSessionID")
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
				+ "BreakLength = " + str(preset.break_length) + ", "\
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
				SessionLength, BreakLength, isAutoStartBreak, isAutoStartSession)
			values ("\
				+ str(preset.ID) + ", "\
				+ str(preset.default_tag_id) + ", "\
				+ str(current_session_id) + ", "\
				+ "'" + preset.name_ + "', "\
				+ str(preset.sessions_count) + ", "\
				+ str(preset.sessions_done) + ", "\
				+ str(preset.session_length) + ", "\
				+ str(preset.break_length) + ", "\
				+ str(preset.is_auto_start_break) + ", "\
				+ str(preset.is_auto_start_session) \
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
