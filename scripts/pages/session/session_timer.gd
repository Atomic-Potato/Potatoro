extends Page

@export var label_preset_name: Label
@export var label_sessions_count: Label
@export var label_finish_hour: Label
@export var label_timer: BlinkCanvasItem
@export var button_pause_toggle: CheckButton
@export var button_auto_break_toggle: CheckButton

# NOTE: I kept them separated because i couldnt figure out 
# how to give them one parent without messing up the UI
@export var add_time_controls_parent: Control
@export var deduct_time_controls_parent: Control

var update_preset: Callable = func(): parent.preset = PresetsManager.get_preset(parent.preset.ID)
var update_session: Callable = func(): parent.session = SessionsManager.get_loaded_buffered_session(parent.session.ID)

var session_time_left_cache: int

func enter():
	if AudioManager.is_playing_notification():
		AudioManager.stop_notification()
	
	var is_new_session: bool
	
	update_preset.call()
	
	if parent.preset.current_session_id != 0:
		parent.session = SessionsManager.get_loaded_buffered_session(parent.preset.current_session_id)
	
	if not parent.session or not SessionsManager.is_session_buffered(parent.session.ID):
		parent.session = SessionsManager.start_buffered_session(parent.preset)
		is_new_session = true
		
	update_preset.call()
	
	if not is_new_session:
		if SessionsManager.is_session_paused(parent.session.ID):
			button_pause_toggle.set_pressed_no_signal(true)
			
	if button_pause_toggle.button_pressed and not SessionsManager.is_session_paused(parent.session.ID):
		SessionsManager.pause_session(parent.session.ID)
		
	button_auto_break_toggle.set_pressed_no_signal(parent.preset.is_auto_start_break)
	
	_update_finish_hour()
	_update_titles_text()
	_update_timer_text()
	_update_things_from_settings()
	if not self.visibility_changed.is_connected(_update_things_from_settings):
		self.visibility_changed.connect(_update_things_from_settings)
	
	connect_session_finish_subscribers(SessionsManager.get_loaded_buffered_session(parent.session.ID))

	parent.session_cache = parent.session
	session_time_left_cache = -1

func exit():
	parent.session = null

func update():
	if parent.preset and PresetsManager.is_in_session(parent.preset.ID):
		if not SessionsManager.is_session_paused(parent.session.ID):
			_update_timer_text()

func connect_session_finish_subscribers(s: Session):
	if not s:
		push_error("Cannot connect subscribers to a null session")
	s.session_finish.connect(update_preset)
	s.session_finish.connect(_update_titles_text)
	s.session_finish.connect(_end_session_timer)

func add_session_length(minutes: int):
	var remaining_secs = SessionsManager.get_session_id_remaining_time_in_seconds(parent.session.ID)
	if remaining_secs + (minutes * 60) < 0:
		return
		
	parent.preset.added_session_length += minutes * 60
	PresetsManager.save_buffered_preset(parent.preset)
	if not SessionsManager.is_session_paused(parent.session.ID):
		SessionsManager.add_seconds_to_buffered_session_end_datetime(parent.session.ID, minutes * 60)
		update_preset.call()
		update_session.call()
	_update_finish_hour()
	_update_timer_text()
	
func add_session_length_seconds(seconds: int):
	var remaining_secs = SessionsManager.get_session_id_remaining_time_in_seconds(parent.session.ID)
	if remaining_secs + seconds < 0:
		return
		
	parent.preset.added_session_length += seconds
	PresetsManager.save_buffered_preset(parent.preset)
	if not SessionsManager.is_session_paused(parent.session.ID):
		SessionsManager.add_seconds_to_buffered_session_end_datetime(parent.session.ID, seconds)
		update_preset.call()
		update_session.call()
	_update_finish_hour()
	_update_timer_text()

	
func toggle_pause():
	if not SessionsManager.is_session_paused(parent.session.ID):
		SessionsManager.pause_session(parent.session.ID)
		label_timer.set_active()
	else:
		SessionsManager.resume_session(parent.session.ID, parent.preset.ID)
		label_timer.set_inactive()
	_update_finish_hour()

func _toggle_auto_break(toggle: bool):
	parent.preset.is_auto_start_break = toggle
	PresetsManager.save_buffered_preset(parent.preset)

func _restart():
	if SessionsManager.is_session_buffered(parent.session.ID):
		parent.session = SessionsManager.restart_buffered_session(parent.session.ID)
	else:
		parent.session = SessionsManager.restart_session(parent.session.ID, parent.preset.ID)
	connect_session_finish_subscribers(parent.session)
	update_preset.call()
	button_pause_toggle.set_pressed_no_signal(false)
	_update_finish_hour()
	_update_titles_text()

func _skip():
	session_time_left_cache = SessionsManager.get_session_id_remaining_time_in_seconds(parent.session.ID)
	update_preset.call()
	parent.session = SessionsManager.end_buffered_session(parent.session.ID)
	button_pause_toggle.set_pressed_no_signal(false)
	parent.set_page(parent.page_session_finish)

func _update_titles_text():
	label_preset_name.text = parent.preset.name_
	label_sessions_count.text = str(parent.preset.sessions_done) + "/" + str(parent.preset.sessions_count)

func _update_timer_text():
	if not SessionsManager.is_session_buffered(parent.session.ID):
		return
	var remaining_time_in_seconds = SessionsManager.get_session_id_remaining_time_in_seconds(parent.session.ID)
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

func _update_finish_hour():
	if not parent.session:
		return
		
	if SessionsManager.is_session_paused(parent.session.ID) \
	or SessionsManager.get_session_id_remaining_time_in_seconds(parent.session.ID) <= 0:
		label_finish_hour.text = ""
		return
	
	var remaining_length_in_seconds = SessionsManager.get_session_id_remaining_time_in_seconds(parent.session.ID)
	var current_time = Time.get_datetime_dict_from_datetime_string(DatabaseManager.get_datetime(), false)
	#print(( remaining_length_in_seconds/ 60) / 60)
	@warning_ignore("integer_division")
	var finish_hour: int = (current_time["hour"] + (current_time["minute"] + (remaining_length_in_seconds / 60)) / 60) % 24 
	@warning_ignore("integer_division")
	var finish_minute: int = (current_time["minute"] + (remaining_length_in_seconds / 60) % 60) % 60
	var finish_minute_str: String = str(finish_minute)
	
	if SettingsManager.is_use_12_hour_format:
		var day_period = "am"
		if finish_hour > 12: 
			finish_hour -= 12
			day_period = "pm"
		var finish_hour_str = str(finish_hour)
		
		label_finish_hour.text = \
			(("0" + finish_hour_str) if finish_hour < 10 else finish_hour_str) \
			+ ":" \
			+ (("0" + finish_minute_str) if finish_minute < 10 else finish_minute_str) \
			+ " " + day_period
	else:
		var finish_hour_str = str(finish_hour)
		label_finish_hour.text = \
			(("0" + finish_hour_str) if finish_hour < 10 else finish_hour_str) \
			+ ":" \
			+ (("0" + finish_minute_str) if finish_minute < 10 else finish_minute_str)

func _end_session_timer():
	if session_time_left_cache > 0:
		return # i.e. session was skipped
	if parent.preset.is_auto_start_break:
		parent.set_page(parent.page_break_timer)
	else:
		parent.set_page(parent.page_session_finish)

func _update_things_from_settings():
	_update_finish_hour()
	if SettingsManager.is_hide_session_timer_controls:
		add_time_controls_parent.hide()
		deduct_time_controls_parent.hide()
	else:
		add_time_controls_parent.show()
		deduct_time_controls_parent.show()

func _add_sessions_done(count: int)-> void:
	PresetsManager.add_session_done(parent.preset.ID, count)
	parent.preset = PresetsManager.get_preset(parent.preset.ID)
	_update_titles_text()
