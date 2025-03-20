extends Page

@export var label_preset_name: Label
@export var label_sessions_count: Label
@export var session_length_parent: Control
@export var edit_session_length: LineEdit
@export var edit_break_length: LineEdit
@export var button_auto_session: CheckButton

var update_preset: Callable = func(): parent.preset = PresetsManager.get_preset(parent.preset.ID)

func enter():
	update_preset.call()
	_update_titles_text()
	button_auto_session.button_pressed = parent.preset.is_auto_start_session
	edit_break_length.placeholder_text = str(parent.preset.break_length) + "m" 
	edit_session_length.placeholder_text = str(parent.preset.session_length) + "m"
	session_length_parent.visible = parent.preset.is_auto_start_session

func _toggle_next_session_length_visibility(toggle: bool):
	session_length_parent.visible = toggle

func _start_break():
	var break_length: int = int(edit_break_length.text) if edit_break_length.text else -1
	var session_length: int = int(edit_session_length.text) \
		if button_auto_session.button_pressed and edit_session_length.text else -1
	parent.preset.break_length = break_length
	parent.preset.session_length = session_length
	parent.preset.is_auto_start_session = button_auto_session.button_pressed
	parent.preset = PresetsManager.get_preset_from_buffer_id(PresetsManager.save_buffered_preset(parent.preset))
	parent.set_page(parent.page_break_timer)

func _reset_break_edit_values():
	button_auto_session.button_pressed = parent.preset.is_auto_start_session
	session_length_parent.visible = not parent.preset.is_auto_start_session
	edit_break_length.text = ""
	edit_session_length.text = ""

func _update_titles_text():
	label_preset_name.text = parent.preset.name_
	label_sessions_count.text = str(parent.preset.sessions_done) + "/" + str(parent.preset.sessions_count)
