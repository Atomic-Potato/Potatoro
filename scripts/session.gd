class_name Session extends Label

@export var length_in_minutes: int = 60
var remaining_length_in_seconds: int
@export var pause_toggle: CheckButton
@export var finish_hour_label: Label
@export var is_use_24_hour_format: bool = false
@export var finish_text: String = "FIN!"
@export var is_alert_os: bool = false

var is_active: bool = true
var is_finished: bool = false
var start_time: int = 0
var elapased_time_in_seconds: int = 0

signal session_finish

func _ready():
	start_time = Time.get_ticks_msec()
	remaining_length_in_seconds = length_in_minutes * 60
	_set_time(length_in_minutes, 0)
	is_active = not pause_toggle.button_pressed
	if is_active:
		_update_finish_hour()
	else:
		finish_hour_label.text = ""
	print(Time.get_time_dict_from_system())
	
func _process(delta):
	if not is_active:
		return
	elapased_time_in_seconds = (Time.get_ticks_msec() - start_time) * 0.001
	if (elapased_time_in_seconds < remaining_length_in_seconds):
		_update_text()
	else:
		is_active = false
		is_finished = true
		text = "FIN!"
		pause_toggle.disabled = true
		if is_alert_os:
			OS.alert("Session finished!", "Potatoro")
		session_finish.emit()

func add_seconds_to_remaining_length(seconds: int):
	if is_finished or (seconds < 0 and remaining_length_in_seconds <= 0):
		return 
	remaining_length_in_seconds += seconds
	if remaining_length_in_seconds < 0:
		remaining_length_in_seconds = 0
	_update_text()
	if is_active: _update_finish_hour()

func add_minutes_to_remaining_length(minutes: int):
	if is_finished or (minutes < 0 and remaining_length_in_seconds <= 0):
		return
	remaining_length_in_seconds += minutes * 60
	if remaining_length_in_seconds < 0:
		remaining_length_in_seconds = 0
	_update_text()
	if is_active: _update_finish_hour()

func toggle_pause(state: bool):
	if state:
		is_active = false
		remaining_length_in_seconds -= elapased_time_in_seconds
		finish_hour_label.text = ""
	else:
		is_active = true
		start_time = Time.get_ticks_msec()
		_update_finish_hour()

func restart():
	_reset()

func skip():
	_reset()

func _reset():
	is_active = false
	is_finished = false
	pause_toggle.disabled = false
	pause_toggle.button_pressed = true
	finish_hour_label.text = ""
	start_time = Time.get_ticks_msec()
	remaining_length_in_seconds = length_in_minutes * 60
	elapased_time_in_seconds = 0
	_set_time(length_in_minutes, 0)

func _update_text():
	var minutes = (remaining_length_in_seconds - elapased_time_in_seconds) / 60
	var seconds = (remaining_length_in_seconds  - elapased_time_in_seconds) % 60
	_set_time(minutes, seconds)

func _set_time(minutes: int, seconds: int):
	var minutes_str = type_convert(minutes, TYPE_STRING)
	var seconds_str = type_convert(seconds, TYPE_STRING)
	text = (("0" + minutes_str) if minutes < 10 else minutes_str) \
		+ ":" \
		+ (("0" + seconds_str) if seconds < 10 else seconds_str)

func _update_finish_hour():
	var current_time = Time.get_time_dict_from_system()
	print((remaining_length_in_seconds / 60) / 60)
	var finish_hour: int = (current_time["hour"] + (current_time["minute"] + (remaining_length_in_seconds / 60)) / 60) % 24 
	var finish_minute: int = (current_time["minute"] + (remaining_length_in_seconds / 60) % 60) % 60
	var finish_minute_str: String = type_convert(finish_minute, TYPE_STRING) 
	
	if is_use_24_hour_format:
		var finish_hour_str = type_convert(finish_hour, TYPE_STRING)
		finish_hour_label.text = \
			(("0" + finish_hour_str) if finish_hour < 10 else finish_hour_str) \
			+ ":" \
			+ (("0" + finish_minute_str) if finish_minute < 10 else finish_minute_str)
	else:
		var day_period = "am"
		if finish_hour > 12: 
			finish_hour -= 12
			day_period = "pm"
		var finish_hour_str = type_convert(finish_hour, TYPE_STRING)
		
		finish_hour_label.text = \
			(("0" + finish_hour_str) if finish_hour < 10 else finish_hour_str) \
			+ ":" \
			+ (("0" + finish_minute_str) if finish_minute < 10 else finish_minute_str) \
			+ " " + day_period
