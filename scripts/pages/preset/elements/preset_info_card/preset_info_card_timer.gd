extends Page

@export var label_timer_type: Label
@export var label_timer: Label
@export var label_session: Label
@export var button_pause_toggle: CheckButton
@export var reset_container: Control

var is_session: bool

func enter():
	is_session = PresetsManager.is_in_session(parent.preset.ID)
	update_titles()
	update_pause_toggle()
	if is_session:
		SessionsManager.get_loaded_buffered_session(parent.preset.current_session_id)\
		.session_finish.connect(set_message_page)
	else:
		BreaksManager.get_loaded_break(parent.preset.current_break_id)\
		.break_finish.connect(set_message_page)
	reset_container.show()

func exit():
	reset_container.hide()


func update():
	if not (is_session and SessionsManager.is_session_paused(parent.preset.current_session_id))\
	or not (not is_session and BreaksManager.is_break_id_paused(parent.preset.current_break_id)):
		_update_timer_text()

func update_titles():
	label_session.text = str(parent.preset.sessions_done) + "/" + str(parent.preset.sessions_count) 
	label_timer_type.text = "session" if is_session else "break"

func update_pause_toggle():
	button_pause_toggle.set_pressed_no_signal(
		SessionsManager.is_session_paused(parent.preset.current_session_id) if is_session\
		else BreaksManager.is_break_id_paused(parent.preset.current_break_id)
	)

func _update_timer_text():
	var remaining_time_in_seconds =\
		SessionsManager.get_session_id_remaining_time_in_seconds(parent.preset.current_session_id)\
		if is_session else BreaksManager.get_break_id_remaining_seconds(parent.preset.current_break_id)
	if remaining_time_in_seconds <= 0:
		return 
		
	@warning_ignore("integer_division")
	_set_time(remaining_time_in_seconds / 60, remaining_time_in_seconds % 60)

func _set_time(minutes: int, seconds: int):
	var minutes_str = str(minutes)
	var seconds_str = str(seconds)
	label_timer.text = (("0" + minutes_str) if minutes < 10 else minutes_str) \
		+ ":" \
		+ (("0" + seconds_str) if seconds < 10 else seconds_str)

func toggle_pause_timer(toggle: bool):
	if toggle:
		if is_session:
			SessionsManager.pause_session(parent.preset.current_session_id)
		else:
			BreaksManager.pause_break_id(parent.preset.current_break_id)
	else:
		if is_session:
			SessionsManager.resume_session(parent.preset.current_session_id, parent.preset.ID)
		else:
			BreaksManager.resume_break_id(parent.preset.current_break_id)

func set_message_page():
	parent.set_page(parent.page_message)

func _add_sessions_done(count: int)-> void:
	PresetsManager.add_session_done(parent.preset.ID, count)
	parent.preset = PresetsManager.get_preset(parent.preset.ID)
	update_titles()
