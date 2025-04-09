extends Page

@export var label_preset_name: Label
@export var label_sessions_count: Label
@export var break_length_parent: Control
@export var spin_box_session_length: SpinBox
@export var spin_box_break_length: SpinBox
@export var button_auto_break: CheckButton

func enter():
	if AudioManager.is_playing_notification():
		AudioManager.stop_notification()
	
	parent.preset = PresetsManager.get_preset(parent.preset.ID)
	spin_box_session_length.value = parent.preset.session_length
	spin_box_break_length.value = parent.preset.break_length
	button_auto_break.set_pressed_no_signal(parent.preset.is_auto_start_break)
	break_length_parent.visible = parent.preset.is_auto_start_break
	_update_titles_text()

func _reset_session_edit_values():
	button_auto_break.set_pressed_no_signal(parent.preset.is_auto_start_break)
	break_length_parent.visible = parent.preset.is_auto_start_break
	spin_box_break_length.value = parent.preset.break_length
	spin_box_session_length.value = parent.preset.session_length

func _toggle_next_break_length_visibility(toggle: bool):
	break_length_parent.visible = toggle

func _start_session():
	parent.preset.break_length = spin_box_break_length.value \
		if button_auto_break.button_pressed else parent.preset.break_length
	parent.preset.session_length = spin_box_session_length.value \
		if spin_box_session_length.text else parent.preset.session_length
		
	parent.preset.is_auto_start_break = button_auto_break.button_pressed
	PresetsManager.save_buffered_preset(parent.preset) 
	
	parent.set_page(parent.page_session_timer)

func _update_titles_text():
	label_preset_name.text = parent.preset.name_
	label_sessions_count.text = str(parent.preset.sessions_done) + "/" + str(parent.preset.sessions_count)
