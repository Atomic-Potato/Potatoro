extends Page
@export var cbt_label_finish_hour: Label
@export var cbt_label_timer: Label

func _skip_break():
	_toggle_break_timer_pause() 
	_set_content(content_break_finish)
	
func _restart_break():
	break_ = BreaksManager.restart_break_id(break_.ID)
	break_.break_finish.connect(_end_break)
	_set_content(content_break_timer)
	_update_break_finish_hour_label()
	_update_break_timer_label()

func _add_break_time(minutes: int):
	var new_datetime: String = DatabaseManager.get_datetime(
		('+' if minutes > 0 else '') + str(minutes) + ' minutes', 
		break_.end_datetime)
	if DatabaseManager.get_datetimes_seconds_difference(
	new_datetime, DatabaseManager.get_datetime()) < 0:
		return
	break_.end_datetime = new_datetime
	BreaksManager.save_break(break_)
	_update_break_finish_hour_label()
	_update_break_timer_label()

func _update_break_timer_label():
	if not PresetsManager.is_in_break(preset.ID):
		return
	
	var remaining_seconds: int = BreaksManager.get_break_id_remaining_seconds(break_.ID)
	var minutes = remaining_seconds / 60
	var seconds = remaining_seconds % 60
	cbt_label_timer.text = (("0" + str(minutes)) if minutes < 10 else str(minutes)) \
		+ ":" \
		+ (("0" + str(seconds)) if seconds < 10 else str(seconds))

func _update_break_finish_hour_label():
	if not PresetsManager.is_in_break(preset.ID):
		return
	
	var remaining_seconds =  BreaksManager.get_break_id_remaining_seconds(break_.ID)
	var current_time = Time.get_datetime_dict_from_datetime_string(DatabaseManager.get_datetime(), false)
	var finish_hour: int = (current_time["hour"] + (current_time["minute"] + (remaining_seconds / 60)) / 60) % 24 
	var finish_minute: int = (current_time["minute"] + (remaining_seconds / 60) % 60) % 60
	var finish_minute_str: String = str(finish_minute)
	
	if is_use_24_hour_format:
		var finish_hour_str = str(finish_hour)
		cbt_label_finish_hour.text = \
			(("0" + finish_hour_str) if finish_hour < 10 else finish_hour_str) \
			+ ":" \
			+ (("0" + finish_minute_str) if finish_minute < 10 else finish_minute_str)
	else:
		var day_period = "am"
		if finish_hour > 12: 
			finish_hour -= 12
			day_period = "pm"
		var finish_hour_str = str(finish_hour)
		
		cbt_label_finish_hour.text = \
			(("0" + finish_hour_str) if finish_hour < 10 else finish_hour_str) \
			+ ":" \
			+ (("0" + finish_minute_str) if finish_minute < 10 else finish_minute_str) \
			+ " " + day_period

func _toggle_break_timer_pause():
	if not break_:
		push_error("Break is null!")
		return
	
	if BreaksManager.is_break_id_paused(break_.ID):
		break_ = BreaksManager.resume_break_id(break_.ID)
	else:
		break_ = BreaksManager.pause_break_id(break_.ID)

func _end_break():
	break_ = null
	update_preset.call()
	if preset.is_auto_start_session:
		_start_session()
	else:
		_set_content(content_session_setup)
		_initialize_content_session_setup()
