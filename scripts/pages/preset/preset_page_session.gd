extends Control

var preset: Preset
var session: Session

@export var is_use_24_hour_format: bool = false # TODO: Get this data from the config table
@export_category("Nodes")
@export var label_preset_name: Label
@export var label_sessions_count: Label
@export var label_finish_hour: Label
@export var label_timer: Label

@export_category("Controls")
@export var pause_toggle: CheckButton

@export_category("Content")
@export var content_default: Control
@export var content_timer: Control
@export var content_finish: Control

var current_content: Control

var update_preset: Callable = func(): preset = PresetsManager.get_preset(preset.ID)
var set_finish_content: Callable = func(): _set_content(content_finish)

func initialize(data: Dictionary):
	preset = data.get("preset")
	session = SessionsManager.get_loaded_buffered_session(PresetsManager.get_preset_current_session_ID(preset))
	session.session_finish.connect(update_preset)
	session.session_finish.connect(_update_titles_text)
	session.session_finish.connect(set_finish_content)

func _ready():
	if SessionsManager.is_session_buffered(session.ID) \
	and SessionsManager.get_session_id_remaining_time_in_seconds(session.ID) <= 0:
		_set_content(content_finish)
		return
	
	_set_content(content_default)
	_update_titles_text()
	_update_timer_text()
	if pause_toggle.button_pressed:
		SessionsManager.pause_session(session.ID)
	_update_finish_hour()

func _process(_delta):
	if not (preset and PresetsManager.get_preset_current_session_ID(preset))\
	or not (session and SessionsManager.is_session_buffered(session.ID)):
		return
	if not SessionsManager.is_session_paused(session.ID):
		_update_timer_text()

func load_preset_page_presets():
	Global.AppMan.load_gui_page(Global.SceneCont.preset_page_presets)

func add_session_length(minutes: int):
	preset.added_session_length += minutes
	PresetsManager.save_buffered_preset(preset, PresetsManager.get_preset_current_session_ID(preset))
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
		_set_content(content_timer)
	preset = PresetsManager.get_preset(preset.ID)
	_update_finish_hour()
	_update_titles_text()

func _skip_session():
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
	label_timer.text = (("0" + minutes_str) if minutes < 10 else minutes_str) \
		+ ":" \
		+ (("0" + seconds_str) if seconds < 10 else seconds_str)

func _update_finish_hour():
	if SessionsManager.is_session_paused(session.ID) \
	or SessionsManager.get_session_id_remaining_time_in_seconds(session.ID) <= 0:
		label_finish_hour.text = ""
		return
	
	var remaining_length_in_seconds = SessionsManager.get_session_id_remaining_time_in_seconds(session.ID)
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

func _set_content(content: Control):
	if not content:
		push_error("Cannot set null content!") 
	if current_content:
		current_content.visible = false
	current_content = content
	current_content.visible = true
