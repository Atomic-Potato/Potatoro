# NOTE: if you say to me "acshually u can make this script better this x way"
# I know, fuk off

extends Control

var preset: Preset
var session: Session

@export var is_use_24_hour_format: bool = false # TODO: Get this data from the config table

# NOTE: Naming abbreviation rule:
# for nodes that are contained in content control nodes
# i put the first letter for each word in the content node name
# e.g: cst_lable_timer is a node in content_session_timer(_label_timer)
@export_category("General Nodes")
@export var label_preset_name: Label
@export var label_sessions_count: Label
@export var content_parent: Control

@export_category("Content Elements: Session Timer")
@export var cst_label_finish_hour: Label
@export var cst_label_timer: Label
@export var cst_button_pause_toggle: CheckButton

@export_category("Content Elements: Break Setup")
@export var cbs_session_length_parent: Control
@export var cbs_edit_session_length: LineEdit
@export var cbs_edit_break_length: LineEdit
@export var cbs_button_auto_session: CheckButton

@export_category("Content Elements: Break Timer")
@export var cbt_label_finish_hour: Label
@export var cbt_label_timer: Label

@export_category("Content")
@export var content_default: Control
@export var content_session_setup: Control
@export var content_session_timer: Control
@export var content_session_finish: Control
@export var content_break_setup: Control
@export var content_break_timer: Control
@export var content_break_finish: Control

var current_content: Control

var update_preset: Callable = func(): preset = PresetsManager.get_preset(preset.ID)
var set_finish_content: Callable = func(): _set_content(content_session_finish)

func initialize(data: Dictionary):
	preset = data.get("preset")
	session = SessionsManager.get_loaded_buffered_session(PresetsManager.get_preset_current_session_ID(preset))
	session.session_finish.connect(update_preset)
	session.session_finish.connect(_update_titles_text)
	session.session_finish.connect(set_finish_content)

func _ready():
	if SessionsManager.is_session_buffered(session.ID) \
	and SessionsManager.get_session_id_remaining_time_in_seconds(session.ID) <= 0:
		_set_content(content_session_finish)
		return
	
	_hide_all_content()
	_set_content(content_default)
	
	_update_titles_text()
	_update_timer_text()
	if cst_button_pause_toggle.button_pressed:
		SessionsManager.pause_session(session.ID)
	_update_finish_hour()

func _process(_delta):
	# Process session timer
	if preset and PresetsManager.is_in_session(preset.ID):
		if not (preset and PresetsManager.get_preset_current_session_ID(preset))\
		or not (session and SessionsManager.is_session_buffered(session.ID)):
			return
		if not SessionsManager.is_session_paused(session.ID):
			_update_timer_text()
	# Process break timer
	elif preset and PresetsManager.is_in_break(preset.ID):
		if not PresetsManager.is_preset_break_paused(preset):
			_update_break_timer_label()

func _set_content(content: Control):
	if not content:
		push_error("Cannot set null content!") 
	if current_content:
		current_content.visible = false
	current_content = content
	current_content.visible = true

func _hide_all_content():
	for child in content_parent.get_children():
		child.visible = false

func load_preset_page_presets():
	Global.AppMan.load_gui_page(Global.SceneCont.preset_page_presets)

# SECTION_TITLE: Session Timer
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
		_set_content(content_session_timer)
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

# SECTION_TITLE: Content Break Setup
func _set_content_break_setup():
	_set_content(content_break_setup)
	cbs_button_auto_session.button_pressed = preset.is_auto_start_session
	cbs_session_length_parent.visible = not preset.is_auto_start_session
	cbs_edit_break_length.placeholder_text = str(preset.break_length) + "m" 
	cbs_edit_session_length.placeholder_text = str(preset.session_length) + "m"

func _toggle_next_session_length_visibility(not_toggle: bool):
	cbs_session_length_parent.visible = not not_toggle

func _start_break():
	var break_length: int = int(cbs_edit_break_length.text) if cbs_edit_break_length.text else -1
	var session_length: int = int(cbs_edit_session_length.text) \
		if not cbs_button_auto_session.button_pressed and cbs_edit_break_length.text else -1
	preset = PresetsManager.start_preset_id_break(preset.ID, break_length, session_length)
	_set_content(content_break_timer)
	_update_break_finish_hour_label()

func _reset_break_edit_values():
	cbs_button_auto_session.button_pressed = preset.is_auto_start_session
	cbs_session_length_parent.visible = not preset.is_auto_start_session
	cbs_edit_break_length.text = ""
	cbs_edit_session_length.text = ""

# SECTION_TITLE: Content Break Timer
func _restart_break():
	preset = PresetsManager.restart_preset_id_break(preset.ID)
	_update_break_finish_hour_label()
	_update_break_timer_label()

func _add_break_time(minutes: int):
	var new_datetime: String = DatabaseManager.get_datetime(
		('+' if minutes > 0 else '') + str(minutes) + ' minutes', 
		preset.break_end_datetime)
	if DatabaseManager.get_datetimes_seconds_difference(
	new_datetime, DatabaseManager.get_datetime()) < 0:
		return
	preset.break_end_datetime = new_datetime
	PresetsManager.save_buffered_preset(preset, 0)
	preset = PresetsManager.get_preset(preset.ID)
	_update_break_finish_hour_label()
	_update_break_timer_label()

func _update_break_timer_label():
	if not (preset and preset.break_end_datetime): # i.e. no break started
		return
	
	var remaining_seconds: int = DatabaseManager.get_datetimes_seconds_difference(
		preset.break_end_datetime, 
		DatabaseManager.get_datetime()
	)
	
	var minutes = remaining_seconds / 60
	var seconds = remaining_seconds % 60
	cbt_label_timer.text = (("0" + str(minutes)) if minutes < 10 else str(minutes)) \
		+ ":" \
		+ (("0" + str(seconds)) if seconds < 10 else str(seconds))

func _update_break_finish_hour_label():
	if not (preset and preset.break_end_datetime): # not in break state
		return
	
	var remaining_seconds =  DatabaseManager.get_datetimes_seconds_difference(
		preset.break_end_datetime, 
		DatabaseManager.get_datetime()
	)
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
	if not preset:
		push_error("Preset is null!")
		return
	
	if PresetsManager.is_preset_break_paused(preset):
		preset = PresetsManager.resume_preset_id_break(preset.ID)
	else:
		preset = PresetsManager.pause_preset_id_break(preset.ID)
		


















