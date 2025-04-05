extends Page

@export var is_use_24_hour_format: bool = false # TODO: Get this data from the config table
@export var label_finish_hour: Label
@export var label_timer: Label
@export var label_preset_name: Label
@export var label_sessions_count: Label
@export var button_pause_toggle: CheckButton
@export var button_auto_session_toggle: CheckButton

# NOTE: I kept them separated because i couldnt figure out 
# how to give them one parent without messing up the UI
@export var add_time_controls_parent: Control
@export var deduct_time_controls_parent: Control

var break_time_left_cache: int

func enter():
	if AudioManager.is_playing_notification():
		AudioManager.stop_notification()
		
	var is_new_break: bool

	parent.preset = PresetsManager.get_preset(parent.preset.ID)
	
	if parent.preset.current_break_id != 0: 
		parent.break_ = BreaksManager.get_loaded_break(parent.preset.current_break_id)
	
	if not parent.break_ or not BreaksManager.is_break_id_buffered(parent.break_.ID, false):
		parent.break_ = BreaksManager.start_break(parent.preset.ID)
		is_new_break = true
		
	parent.preset = PresetsManager.get_preset(parent.preset.ID)
	
	if not is_new_break:
		if BreaksManager.is_break_id_paused(parent.break_.ID):
			button_pause_toggle.set_pressed_no_signal(true)
			
	if button_pause_toggle.button_pressed and not BreaksManager.is_break_id_paused(parent.break_.ID):
		BreaksManager.pause_break_id(parent.break_.ID)
	
	parent.break_.break_finish.connect(_end_break)
	button_auto_session_toggle.set_pressed_no_signal(parent.preset.is_auto_start_session)
	
	_update_titles_text()
	_update_break_finish_hour_label()
	_update_break_timer_label()
	_update_things_from_settings()
	self.visibility_changed.connect(_update_things_from_settings)
	
	break_time_left_cache = -1

func exit():
	parent.break_ = null

func update():
	if parent.preset and PresetsManager.is_in_break(parent.preset.ID):
		if not BreaksManager.is_break_id_paused(parent.break_.ID):
			_update_break_timer_label()

func _skip_break():
	break_time_left_cache = BreaksManager.get_break_id_remaining_seconds(parent.break_.ID)
	BreaksManager.end_break_id(parent.break_.ID)
	button_pause_toggle.set_pressed_no_signal(false)
	parent.preset = PresetsManager.get_preset(parent.preset.ID)
	parent.set_page(parent.page_break_finish)
	
func _restart_break():
	parent.break_ = BreaksManager.restart_break_id(parent.break_.ID)
	parent.break_.break_finish.connect(_end_break)
	button_pause_toggle.set_pressed_no_signal(false)
	_update_break_finish_hour_label()
	_update_break_timer_label()

func _add_break_time(minutes: int):
	BreaksManager.add_seconds_to_break(minutes * 60, parent.break_.ID)
	parent.break_ = BreaksManager.get_loaded_break(parent.break_.ID)
	_update_break_finish_hour_label()
	_update_break_timer_label()

func _add_break_time_seconds(seconds: int):
	BreaksManager.add_seconds_to_break(seconds, parent.break_.ID)
	parent.break_ = BreaksManager.get_loaded_break(parent.break_.ID)
	_update_break_finish_hour_label()
	_update_break_timer_label()

func _toggle_auto_session(toggle: bool):
	parent.preset.is_auto_start_session = toggle
	PresetsManager.save_buffered_preset(parent.preset)

func _update_break_timer_label():
	if not PresetsManager.is_in_break(parent.preset.ID):
		return
	
	var remaining_seconds: int = BreaksManager.get_break_id_remaining_seconds(parent.break_.ID)
	var minutes = remaining_seconds / 60
	var seconds = remaining_seconds % 60
	label_timer.text = (("0" + str(minutes)) if minutes < 10 else str(minutes)) \
		+ ":" \
		+ (("0" + str(seconds)) if seconds < 10 else str(seconds))

func _update_break_finish_hour_label():
	if not parent.break_ or not PresetsManager.is_in_break(parent.preset.ID):
		return
	
	var remaining_seconds =  BreaksManager.get_break_id_remaining_seconds(parent.break_.ID)
	var current_time = Time.get_datetime_dict_from_datetime_string(DatabaseManager.get_datetime(), false)
	var finish_hour: int = (current_time["hour"] + (current_time["minute"] + (remaining_seconds / 60)) / 60) % 24 
	var finish_minute: int = (current_time["minute"] + (remaining_seconds / 60) % 60) % 60
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

func _toggle_break_timer_pause():
	if not parent.break_:
		push_error("Break is null!")
		return
	
	if BreaksManager.is_break_id_paused(parent.break_.ID):
		parent.break_ = BreaksManager.resume_break_id(parent.break_.ID)
	else:
		parent.break_ = BreaksManager.pause_break_id(parent.break_.ID)

func _update_titles_text():
	label_preset_name.text = parent.preset.name_
	label_sessions_count.text = str(parent.preset.sessions_done) + "/" + str(parent.preset.sessions_count)
	
func _end_break():
	if break_time_left_cache > 0:
		return # i.e. break was skipped 
	parent.preset = PresetsManager.get_preset(parent.preset.ID)
	if parent.preset.is_auto_start_session:
		parent.set_page(parent.page_session_timer)
	else:
		parent.set_page(parent.page_break_finish)
		

func _update_things_from_settings():
	_update_break_finish_hour_label()
	if SettingsManager.is_hide_break_timer_controls:
		add_time_controls_parent.hide()
		deduct_time_controls_parent.hide()
	else:
		add_time_controls_parent.show()
		deduct_time_controls_parent.show()
