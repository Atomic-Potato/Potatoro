class_name MakeEditPreset extends Control

var preset_id: int  = 3 # If null, it will be saved, otherwise updated if exists

@export var preset_edit: LineEdit
@export var tag_edit: LineEdit

@export var session_count_edit: LineEdit
@export var session_length_edit: LineEdit
@export var break_length_edit: LineEdit

func _save_preset_data(is_start: bool = false):
	if not preset_edit.text:
		push_warning("Preset name not set")
		return
	
	if preset_id: # Update
		DatabaseManager.db.query("select ID from Presets where ID = " + str(preset_id))
		if DatabaseManager.db.query_result.is_empty():
			push_error("Preset ID " + str(preset_id) + " not found.")
			return
		
		DatabaseManager.db.query("
			update Presets
			set "\
				+ "Name = '" + preset_edit.text + "', "\
				+ "SessionsCount = " + session_count_edit.text + ", "\
				+ "SessionLength = " + session_length_edit.text + ", "\
				+ "BreakLength = " + break_length_edit.text + "
			where ID = " + type_convert(preset_id, TYPE_STRING)
		)
	else: # Insert
		DatabaseManager.db.query("
			insert into Presets(Name, SessionsCount, SessionLength, BreakLength)
			values ("\
				+ "'" + preset_edit.text + "', "\
				+ session_count_edit.text + ", "\
				+ session_length_edit.text + ", "\
				+ break_length_edit.text + ")"\
		)
	print(DatabaseManager.db.query_result)
	
	# TODO: Return to preset screen or start session
