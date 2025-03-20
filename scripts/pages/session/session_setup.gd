extends Page

@export var css_break_length_parent: Control
@export var css_edit_session_length: LineEdit
@export var css_edit_break_length: LineEdit
@export var css_button_auto_break: CheckButton

func _initialize_content_session_setup():
	preset = PresetsManager.get_preset(preset.ID)
	css_edit_session_length.placeholder_text = str(preset.session_length) + 'm'
	css_edit_break_length.placeholder_text = str(preset.break_length) + 'm'
	css_button_auto_break.button_pressed = preset.is_auto_start_break
	css_break_length_parent.visible = preset.is_auto_start_break

func _reset_session_edit_values():
	css_button_auto_break.button_pressed = preset.is_auto_start_break
	css_break_length_parent.visible = preset.is_auto_start_break
	css_edit_break_length.text = ""
	css_edit_session_length.text = ""

func _toggle_next_break_length_visibility(toggle: bool):
	css_break_length_parent.visible = toggle

func _start_session():
	preset.break_length = int(css_edit_break_length.text) \
		if css_button_auto_break.button_pressed and css_edit_break_length.text else preset.break_length
	preset.session_length = int(css_edit_session_length.text) \
		if cbs_edit_session_length.text else preset.session_length
	
	session = SessionsManager.start_buffered_session(preset)
	connect_session_finish_subscribers(session)
	
	if current_content == content_session_setup:
		preset.is_auto_start_break = css_button_auto_break.button_pressed
	preset.current_session_id = session.ID
	PresetsManager.save_buffered_preset(preset) 
	
	_set_content(content_session_timer)
	
