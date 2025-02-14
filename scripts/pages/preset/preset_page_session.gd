extends Control

var preset: Preset
var session: Session

@export var is_use_24_hour_format: bool = false # TODO: Get this data from the config table
@export_category("Nodes")
@export var label_preset_name: Label
@export var label_sessions_count: Label
@export var label_finish_hour: Label
@export var label_timer: Label

func initialize(data: Dictionary):
	preset = data.get("preset")
	session = SessionsManager.get_session(PresetsManager.get_preset_current_session_ID(preset))
	_update_text()

func _process(delta):
	# TODO: update time text if running
	_update_text()
	pass

func load_preset_page_presets():
	Global.AppMan.load_gui_page(Global.SceneCont.preset_page_presets)

func _update_text():
	label_preset_name.text = preset.name_
	label_sessions_count.text = str(preset.sessions_done) + "/" + str(preset.sessions_count)
	_update_finish_hour()
	var remaining_time_in_seconds = SessionsManager.get_session_remaining_time_in_seconds(session)
	_set_time(remaining_time_in_seconds / 60, remaining_time_in_seconds % 60)
	

func _set_time(minutes: int, seconds: int):
	var minutes_str = type_convert(minutes, TYPE_STRING)
	var seconds_str = type_convert(seconds, TYPE_STRING)
	label_timer = (("0" + minutes_str) if minutes < 10 else minutes_str) \
		+ ":" \
		+ (("0" + seconds_str) if seconds < 10 else seconds_str)

func _update_finish_hour():
	var remaining_length_in_seconds = SessionsManager.get_session_remaining_time_in_seconds(session)
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
