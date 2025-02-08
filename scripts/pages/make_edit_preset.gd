class_name MakeEditPreset extends Control

var preset_id: int  = 3 # If null, it will be saved, otherwise updated if exists

@export var preset_edit: LineEdit
@export var tag_edit: LineEdit
@export var session_count_edit: LineEdit
@export var session_length_edit: LineEdit
@export var break_length_edit: LineEdit
@export var auto_break_toggle: BaseButton
@export var auto_session_toggle: BaseButton

func _save_preset_data(is_start: bool = false):
	if not preset_edit.text:
		push_warning("Preset name not set")
		return
	
	var preset = Preset.new()
	preset.name_ = preset_edit.text
	# preset.default_tag_id = # to be done
	preset.sessions_count = int(session_count_edit.text)
	preset.session_length = int(session_length_edit.text)
	preset.break_length = int(break_length_edit.text)
	preset.is_auto_start_break = auto_break_toggle.button_pressed
	preset.is_auto_start_session = auto_session_toggle.button_pressed
	PresetsManager.save_preset(preset) 
	
	# TODO: Return to preset screen or start session
