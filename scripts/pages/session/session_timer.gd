extends Page

@export var cst_label_finish_hour: Label
@export var cst_label_timer: Label
@export var cst_button_pause_toggle: CheckButton

func add_session_length(minutes: int):
	preset.added_session_length += minutes
	PresetsManager.save_buffered_preset(preset)
	SessionsManager.add_seconds_to_buffered_session_end_datetime(session.ID, minutes * 60)
	preset = PresetsManager.get_preset(preset.ID)
	session = SessionsManager.get_session(session.ID)
	_update_finish_hour()
	_update_timer_text()
	
func toggle_timer_pause():
	if not SessionsManager.is_session_paused(session.ID):
		SessionsManager.pause_session(session.ID)
	else:
		SessionsManager.resume_session(session.ID, preset.ID)
	_update_finish_hour()
	# TODO: Play blinking animations

func _restart_session():
	if SessionsManager.is_session_buffered(session.ID):
		session = SessionsManager.restart_buffered_session(session.ID)
	else:
		session = SessionsManager.restart_session(session.ID, preset.ID)
		_set_content(content_session_timer)
	connect_session_finish_subscribers(session)
	update_preset.call()
	_update_finish_hour()
	_update_titles_text()

func _skip_session():
	cache_remaining_session_time = SessionsManager.get_session_id_remaining_time_in_seconds(session.ID)
	session = SessionsManager.end_buffered_session(session.ID)

func _update_titles_text():
	label_preset_name.text = preset.name_
	label_sessions_count.text = str(preset.sessions_done) + "/" + str(preset.sessions_count)

func _update_timer_text():
	if not SessionsManager.is_session_buffered(session.ID)\
	or SessionsManager.get_session_id_remaining_time_in_seconds(session.ID) <= 0\
	or SessionsManager.is_session_paused(session.ID):
		return 
	var remaining_time_in_seconds = SessionsManager.get_session_id_remaining_time_in_seconds(session.ID)
	_set_time(remaining_time_in_seconds / 60, remaining_time_in_seconds % 60)

func _set_time(minutes: int, seconds: int):
	var minutes_str = str(minutes)
	var seconds_str = str(seconds)
	cst_label_timer.text = (("0" + minutes_str) if minutes < 10 else minutes_str) \
		+ ":" \
		+ (("0" + seconds_str) if seconds < 10 else seconds_str)

func _update_finish_hour():
	if SessionsManager.is_session_paused(session.ID) \
	or SessionsManager.get_session_id_remaining_time_in_seconds(session.ID) <= 0:
		cst_label_finish_hour.text = ""
		return
	
	var remaining_length_in_seconds = SessionsManager.get_session_id_remaining_time_in_seconds(session.ID)
	var current_time = Time.get_datetime_dict_from_datetime_string(DatabaseManager.get_datetime(), false)
	#print(( remaining_length_in_seconds/ 60) / 60)
	var finish_hour: int = (current_time["hour"] + (current_time["minute"] + (remaining_length_in_seconds / 60)) / 60) % 24 
	var finish_minute: int = (current_time["minute"] + (remaining_length_in_seconds / 60) % 60) % 60
	var finish_minute_str: String = str(finish_minute)
	
	if is_use_24_hour_format:
		var finish_hour_str = str(finish_hour)
		cst_label_finish_hour.text = \
			(("0" + finish_hour_str) if finish_hour < 10 else finish_hour_str) \
			+ ":" \
			+ (("0" + finish_minute_str) if finish_minute < 10 else finish_minute_str)
	else:
		var day_period = "am"
		if finish_hour > 12: 
			finish_hour -= 12
			day_period = "pm"
		var finish_hour_str = str(finish_hour)
		
		cst_label_finish_hour.text = \
			(("0" + finish_hour_str) if finish_hour < 10 else finish_hour_str) \
			+ ":" \
			+ (("0" + finish_minute_str) if finish_minute < 10 else finish_minute_str) \
			+ " " + day_period

func _end_session_timer():
	if preset.is_auto_start_break and cache_remaining_session_time == 0 :
		_start_break()
	else:
		_set_content(content_session_finish)
		cache_remaining_session_time = 0
