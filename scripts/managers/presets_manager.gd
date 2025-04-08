extends Node

# DANGER: Must match the database TimerTypes
enum TimerTypes
{
	Session = 1,
	Break = 2
}

# NOTE: I was trying to make each manager independent, 
# but i was getting a lot of code repetition in the breaks and sessions manager
# since both rely on presets, so im breaking this rule just for this manager 

func is_in_session(preset_id: int)-> bool:
	if not is_preset_id_buffered(preset_id):
		return false
	
	DatabaseManager.db.query("
		select CurrentSessionID, CurrentBreakID from Presets_Buffer where PresetID = " 
		+ str(preset_id))
	if DatabaseManager.db.query_result[0].get("CurrentSessionID"):
		if DatabaseManager.db.query_result[0].get("CurrentBreakID"):
			push_error("DANGER: Preset is in session and in break at the same time!")
			return false
		return true 
	return false

func is_in_break(preset_id: int)-> bool:
	if not is_preset_id_buffered(preset_id):
		return false
	
	DatabaseManager.db.query("
		select CurrentSessionID, CurrentBreakID from Presets_Buffer where PresetID = " 
		+ str(preset_id))	
	if DatabaseManager.db.query_result[0].get("CurrentBreakID"):
		if DatabaseManager.db.query_result[0].get("CurrentSessionID"):
			push_error("DANGER: Preset is in session and in break at the same time!")
			return false
		return true 
	return false

func is_preset_id_exists(preset_id: int, is_push_error: bool = true):
	DatabaseManager.db.query("select ID from Presets where ID = " + str(preset_id))
	if DatabaseManager.db.query_result.is_empty():
		if is_push_error:
			push_error("Cannot find preset ID ", preset_id)
		return false
	return true

func is_preset_id_buffered(preset_id: int, is_push_error: bool = true):
	DatabaseManager.db.query("
		select ID from Presets_Buffer where PresetID = " + str(preset_id))
	if DatabaseManager.db.query_result.is_empty():
		if is_push_error:
			push_warning("Preset ID ", preset_id, " is not buffered")
		return false
	return true

func get_presets() -> Array[Preset]:
	var presets: Array[Preset] = []
	DatabaseManager.db.query("select ID from Presets")
	for p in DatabaseManager.db.query_result:
		presets.append(get_preset(p.get("ID")))
	return presets

func get_preset(preset_id: int, is_check_buffered: bool = true)-> Preset:
	if is_check_buffered:
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
				DatabaseManager.db.query_result[0].get("CurrentSessionID"),
				DatabaseManager.db.query_result[0].get("CurrentBreakID"),
				DatabaseManager.db.query_result[0].get("NextTimerTypeID")
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
			0,
			0,
			0
		)
	push_error("Cant find preset with ID " + str(preset_id))
	return null

func get_preset_from_buffer_id(preset_buffer_id: int)-> Preset:
	DatabaseManager.db.query("select * from Presets_Buffer where ID = " + str(preset_buffer_id))
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
			DatabaseManager.db.query_result[0].get("CurrentSessionID"),
			DatabaseManager.db.query_result[0].get("CurrentBreakID"),
			DatabaseManager.db.query_result[0].get("NextTimerTypeID")
		)
	push_error("Cant find buffered preset with ID " + str(preset_buffer_id))
	return null

func set_default_values(preset_id: int)-> Preset:
	if not is_preset_id_buffered(preset_id):
		return null
	DatabaseManager.db.query("select * from Presets where ID = " + str(preset_id))
	@warning_ignore("shadowed_global_identifier")
	var preset = DatabaseManager.db.query_result[0]
	DatabaseManager.db.query("
		update Presets_Buffer set
			DefaultTagID = " + preset.get("DefaultTagID") + ",
			CurrentSessionID = 0,
			CurrentBreakID = 0,
			NextTimerTypeID = 0,
			SessionLength = " + preset.get("SessionLength") + ",
			AddedSessionLenght = 0,
			BreakLength = " + preset.get("BreakLength") + ",
			isAutoStartBreak = " + preset.get("isAutoStartBreak") + ",
			isAutoStartSession = " + preset.get("isAutoStartSession")
	)
	return get_preset(preset_id)

# SUMMARY:
# creates a new preset with the provided values and returns its id
# if the id is provided in the preset, then it will update
@warning_ignore("shadowed_global_identifier")
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
		return DatabaseManager.db.last_insert_rowid

# SUMMARY:
# creates a new buffered preset with the provided values and returns its id
# if the id is provided in the preset, then it will update
@warning_ignore("shadowed_global_identifier")
func save_buffered_preset(preset: Preset)-> int:
	if preset.current_session_id and preset.current_break_id:
		push_error("Cannot save buffered preset with ID ", preset.ID, " that is is session and in break at the same time!")
	if preset.buffer_ID: # Update
		DatabaseManager.db.query("select ID from Presets_Buffer where PresetID = " + str(preset.ID))
		if DatabaseManager.db.query_result.is_empty():
			push_error("Preset ID " + str(preset.ID) + " not found in buffer.")
			return 0
		if preset.current_session_id != 0:
			DatabaseManager.db.query("select ID from Sessions_Buffer where SessionID = " + str(preset.current_session_id))
			if DatabaseManager.db.query_result.is_empty():
				push_error("Current Session ID " + str(preset.current_session_id) + " not found in sessions buffer.")
				return 0
			
		var query = "
			update Presets_Buffer
			set "\
				+ "PresetID = " + str(preset.ID) + ", "\
				+ "DefaultTagID = " + str(preset.default_tag_id) + ", "\
				+ "CurrentSessionID = " + str(preset.current_session_id) + ", "\
				+ "CurrentBreakID = " + str(preset.current_break_id) + ", "\
				+ "NextTimerTypeID = " + str(preset.next_timer_type_id) + ", "\
				+ "Name = '" + preset.name_ + "', "\
				+ "SessionsCount = " + str(preset.sessions_count)  + ", "\
				+ "SessionsDone = " + str(preset.sessions_done)  + ", "\
				+ "SessionLength = " + str(preset.session_length) + ", "\
				+ "AddedSessionLength = " + str(preset.added_session_length) + ", "\
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
				(PresetID, DefaultTagID, CurrentSessionID, CurrentBreakID, NextTimerTypeID, 
				Name, SessionsCount, SessionsDone, SessionLength, AddedSessionLength, 
				BreakLength, isAutoStartBreak, isAutoStartSession)
			values ("\
				+ str(preset.ID) + ", "\
				+ str(preset.default_tag_id) + ", "\
				+ str(preset.current_session_id) + ", "\
				+ str(preset.current_break_id) + ", "\
				+ str(preset.next_timer_type_id) + ", "\
				+ "'" + preset.name_ + "', "\
				+ str(preset.sessions_count) + ", "\
				+ str(preset.sessions_done) + ", "\
				+ str(preset.session_length) + ", "\
				+ str(preset.added_session_length) + ", "\
				+ str(preset.break_length) + ", "\
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
