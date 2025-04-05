extends Page

@export var label_preset_name: Label
@export var label_sessions_count: Label
@export var break_length_parent: Control
@export var edit_session_length: LineEdit
@export var edit_break_length: LineEdit
@export var button_auto_break: CheckButton

func enter():
	if AudioManager.is_playing_notification():
		AudioManager.stop_notification()
	
	parent.preset = PresetsManager.get_preset(parent.preset.ID)
	edit_session_length.placeholder_text = str(parent.preset.session_length) + 'm'
	edit_session_length.text = ""
	edit_break_length.placeholder_text = str(parent.preset.break_length) + 'm'
	edit_break_length.text = ""
	button_auto_break.button_pressed = parent.preset.is_auto_start_break
	break_length_parent.visible = parent.preset.is_auto_start_break
	_update_titles_text()

func _reset_session_edit_values():
	button_auto_break.button_pressed = parent.preset.is_auto_start_break
	break_length_parent.visible = parent.preset.is_auto_start_break
	edit_break_length.text = ""
	edit_session_length.text = ""

func _toggle_next_break_length_visibility(toggle: bool):
	break_length_parent.visible = toggle

func _start_session():
	parent.preset.break_length = int(edit_break_length.text) \
		if button_auto_break.button_pressed and edit_break_length.text else parent.preset.break_length
	parent.preset.session_length = int(edit_session_length.text) \
		if edit_session_length.text else parent.preset.session_length
		
	parent.preset.is_auto_start_break = button_auto_break.button_pressed
	PresetsManager.save_buffered_preset(parent.preset) 
	
	parent.set_page(parent.page_session_timer)

func _update_titles_text():
	label_preset_name.text = parent.preset.name_
	label_sessions_count.text = str(parent.preset.sessions_done) + "/" + str(parent.preset.sessions_count)
