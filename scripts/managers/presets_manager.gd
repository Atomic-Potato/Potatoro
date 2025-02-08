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
		preset.name_ = i.get("Name", "[UNKNOWN]")
		preset.sessions_count = i.get("SessionsCount", 0)
		preset.sessions_done = i.get("SessionsDone", 0) if i.get("SessionsDone") else 0
		preset.session_length = i.get("SessionLength", 0)
		preset.break_length = i.get("BreakLength", 0)
		preset.is_auto_start_break = i.get("isAutoStartBreak", false)
		preset.is_auto_start_session = i.get("isAutoStartSession", false)
		presets.append(preset)
	return presets

# creates a new preset with the provided values and returns its id
# if the id is provided in the preset, then it will update
func save_preset(preset: Preset)-> int: # use save_buffered_preset to create a new buffered preset
	if preset.ID: # Update
		DatabaseManager.db.query("select ID from Presets where ID = " + str(preset.ID))
		if DatabaseManager.db.query_result.is_empty():
			push_error("Preset ID " + str(preset.ID) + " not found.")
			return 0
		
		DatabaseManager.db.query("
			update Presets
			set "\
				+ "DefaultTagID = " + str(preset.default_tag_id) + ", "\
				+ "Name = '" + preset.name_ + "', "\
				+ "SessionsCount = " + str(preset.sessions_count)  + ", "\
				+ "SessionLength = " + str(preset.session_length) + ", "\
				+ "BreakLength = " + str(preset.break_length) + ", "\
				+ "BreakLength = " + str(int(preset.is_auto_start_break)) + ", "\
				+ "BreakLength = " + str(int(preset.is_auto_start_session)) +\
			"where ID = " + str(preset.ID)
		)
		return preset.ID
	else: # Insert
		DatabaseManager.db.query("
			insert into Presets
				(DefaultTagID, Name, SessionsCount, SessionLength, BreakLength, isAutoStartBreak, isAutoStartSession)
			values ("\
				+ str(preset.default_tag_id) + ", "\
				+ "'" + preset.name_ + "', "\
				+ str(preset.sessions_count) + ", "\
				+ str(preset.session_length) + ", "\
				+ str(preset.break_length) + ", "\
				+ str(preset.is_auto_start_break) + ", "\
				+ str(preset.is_auto_start_session)
		+ ")")
		return DatabaseManager.db.last_insert_rowid

# creates a new buffered preset with the provided values and returns its id
# if the id is provided in the preset, then it will update
func save_buffered_preset(preset: Preset)-> int:
	# TODO: i dont really need it now 
	return 0








