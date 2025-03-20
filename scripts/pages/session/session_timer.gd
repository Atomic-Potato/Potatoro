extends Page

@export var is_use_24_hour_format: bool = false # TODO: Get this data from the config table
@export var label_preset_name: Label
@export var label_sessions_count: Label
@export var label_finish_hour: Label
@export var label_timer: Label
@export var button_pause_toggle: CheckButton

var update_preset: Callable = func(): parent.preset = PresetsManager.get_preset(parent.preset.ID)
var update_session: Callable = func(): parent.session = SessionsManager.get_loaded_buffered_session(parent.session.ID)

func enter():
	update_preset.call()
	update_session.call()
	if button_pause_toggle.button_pressed:
		SessionsManager.pause_session(parent.session.ID)
		_update_finish_hour()
	_update_titles_text()
	connect_session_finish_subscribers(parent.session)

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
	parent.preset.added_session_length += minutes
	PresetsManager.save_buffered_preset(parent.preset)
	SessionsManager.add_seconds_to_buffered_session_end_datetime(parent.session.ID, minutes * 60)
	parent.preset = PresetsManager.get_preset(parent.preset.ID)
	parent.session = SessionsManager.get_session(parent.session.ID)
	_update_finish_hour()
	_update_timer_text()
	
func toggle_pause():
	if not SessionsManager.is_session_paused(parent.session.ID):
		SessionsManager.pause_session(parent.session.ID)
	else:
		SessionsManager.resume_session(parent.session.ID, parent.preset.ID)
	_update_finish_hour()
	# TODO: Play blinking animations

func _restart():
	if SessionsManager.is_session_buffered(parent.session.ID):
		parent.session = SessionsManager.restart_buffered_session(parent.session.ID)
	else:
		parent.session = SessionsManager.restart_session(parent.session.ID, parent.preset.ID)
		parent.set_page(parent.page_session_timer)
	connect_session_finish_subscribers(parent.session)
	update_preset.call()
	_update_finish_hour()
	_update_titles_text()

func _skip():
	# DEPRECATED
	#cache_remaining_session_time = SessionsManager.get_session_id_remaining_time_in_seconds(session.ID)
	parent.session = SessionsManager.end_buffered_session(parent.session.ID)

func _update_titles_text():
	label_preset_name.text = parent.preset.name_
	label_sessions_count.text = str(parent.preset.sessions_done) + "/" + str(parent.preset.sessions_count)

func _update_timer_text():
	if not SessionsManager.is_session_buffered(parent.session.ID)\
	or SessionsManager.get_session_id_remaining_time_in_seconds(parent.session.ID) <= 0\
	or SessionsManager.is_session_paused(parent.session.ID):
		return 
	var remaining_time_in_seconds = SessionsManager.get_session_id_remaining_time_in_seconds(parent.session.ID)
	_set_time(remaining_time_in_seconds / 60, remaining_time_in_seconds % 60)

func _set_time(minutes: int, seconds: int):
	var minutes_str = str(minutes)
	var seconds_str = str(seconds)
	label_timer.text = (("0" + minutes_str) if minutes < 10 else minutes_str) \
		+ ":" \
		+ (("0" + seconds_str) if seconds < 10 else seconds_str)

func _update_finish_hour():
	if SessionsManager.is_session_paused(parent.session.ID) \
	or SessionsManager.get_session_id_remaining_time_in_seconds(parent.session.ID) <= 0:
		label_finish_hour.text = ""
		return
	
	var remaining_length_in_seconds = SessionsManager.get_session_id_remaining_time_in_seconds(parent.session.ID)
	var current_time = Time.get_datetime_dict_from_datetime_string(DatabaseManager.get_datetime(), false)
	#print(( remaining_length_in_seconds/ 60) / 60)
	var finish_hour: int = (current_time["hour"] + (current_time["minute"] + (remaining_length_in_seconds / 60)) / 60) % 24 
	var finish_minute: int = (current_time["minute"] + (remaining_length_in_seconds / 60) % 60) % 60
	var finish_minute_str: String = str(finish_minute)
	
	if is_use_24_hour_format:
		var finish_hour_str = str(finish_hour)
		label_finish_hour.text = \
			(("0" + finish_hour_str) if finish_hour < 10 else finish_hour_str) \
			+ ":" \
			+ (("0" + finish_minute_str) if finish_minute < 10 else finish_minute_str)
	else:
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

func _end_session_timer():
	# DEPRECATED
	#if parent.preset.is_auto_start_break and cache_remaining_session_time == 0 :
		#_start_break()
	#else:
	#cache_remaining_session_time = 0
	parent.set_page(parent.page_session_finish)
