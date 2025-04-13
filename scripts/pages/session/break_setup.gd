extends Page

@export var label_preset_name: Label
@export var label_sessions_count: Label
@export var session_length_parent: Control
@export var spin_box_session_length: SpinBox
@export var spin_box_break_length: SpinBox
@export var button_auto_session: CheckBox

var update_preset: Callable = func(): parent.preset = PresetsManager.get_preset(parent.preset.ID)

func enter():
	if AudioManager.is_playing_notification():
		AudioManager.stop_notification()
	
	update_preset.call()
	_update_titles_text()
	button_auto_session.set_pressed_no_signal(parent.preset.is_auto_start_session)
	spin_box_break_length.value = parent.preset.break_length
	spin_box_session_length.value = parent.preset.session_length
	session_length_parent.visible = parent.preset.is_auto_start_session

func _toggle_next_session_length_visibility(toggle: bool):
	session_length_parent.visible = toggle

func _start_break():
	var break_length: int = spin_box_break_length.value
	var session_length: int = spin_box_session_length.value\
		if button_auto_session.button_pressed else parent.preset.session_length
	parent.preset.break_length = break_length
	parent.preset.session_length = session_length
	parent.preset.is_auto_start_session = button_auto_session.button_pressed
	parent.preset = PresetsManager.get_preset_from_buffer_id(PresetsManager.save_buffered_preset(parent.preset))
	parent.set_page(parent.page_break_timer)

func _reset_break_edit_values():
	button_auto_session.set_pressed_no_signal(parent.preset.is_auto_start_session)
	session_length_parent.visible = parent.preset.is_auto_start_session
	spin_box_break_length.value = parent.preset.break_length
	spin_box_session_length.value = parent.preset.session_length

func _update_titles_text():
	label_preset_name.text = parent.preset.name_
	var count: String = str(parent.preset.sessions_count) if parent.preset.sessions_count else "∞"
	label_sessions_count.text = str(parent.preset.sessions_done) + "/" + count

func _add_sessions_done(count: int)-> void:
	PresetsManager.add_session_done(parent.preset.ID, count)
	parent.preset = PresetsManager.get_preset(parent.preset.ID)
	_update_titles_text()
