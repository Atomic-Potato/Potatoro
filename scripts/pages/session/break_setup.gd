extends Page

@export var cbs_session_length_parent: Control
@export var cbs_edit_session_length: LineEdit
@export var cbs_edit_break_length: LineEdit
@export var cbs_button_auto_session: CheckButton

func _set_content_break_setup():
	_set_content(content_break_setup)
	cbs_button_auto_session.button_pressed = preset.is_auto_start_session
	cbs_edit_break_length.placeholder_text = str(preset.break_length) + "m" 
	cbs_edit_session_length.placeholder_text = str(preset.session_length) + "m"
	cbs_session_length_parent.visible = preset.is_auto_start_session

func _toggle_next_session_length_visibility(toggle: bool):
	cbs_session_length_parent.visible = toggle

func _start_break():
	var break_length: int = int(cbs_edit_break_length.text) if cbs_edit_break_length.text else -1
	var session_length: int = int(cbs_edit_session_length.text) \
		if cbs_button_auto_session.button_pressed and cbs_edit_session_length.text else -1
	
	break_ = BreaksManager.start_break(preset.ID, break_length, session_length)
	break_.break_finish.connect(_end_break)
	
	update_preset.call()
	if current_content == content_break_setup:
		preset.is_auto_start_session = cbs_button_auto_session.button_pressed
	preset = PresetsManager.get_preset_from_buffer_id(PresetsManager.save_buffered_preset(preset))

	_set_content(content_break_timer)
	_update_break_finish_hour_label()

func _reset_break_edit_values():
	cbs_button_auto_session.button_pressed = preset.is_auto_start_session
	cbs_session_length_parent.visible = not preset.is_auto_start_session
	cbs_edit_break_length.text = ""
	cbs_edit_session_length.text = ""
