# NOTE: this class also includes the info table in the database
extends Node

@export var theme_title_bar: Theme
@export var theme_main: Theme

# DANGER: Remember to update and restore default database settings if this was modified
enum DBSettings ## Names and IDs
{
	## DEFAULT VALUES
	SessionsCount, SessionLength, BreakLength,
	
	## TIMER SETTINGS
	IsUse12HourFormat, 
	HideSessionTimerTimeChangeButtons, HideBreakTimerTimeChangeButtons,
	
	## SOUND SETTINGS
	PathSessionEndNotification, PathBreakEndNotification,
	VolumeSessionEndNotification, VolumeBreakEndNotification,
	
	## THEME
	# background
	BackgroundPrimaryColor,
	# main
	PrimaryColor, SecondaryColor, ThirdColor,
	# danger
	DangerPrimaryColor, DangerSecondaryColor,
	# titlebar
	IsUseCustomTitleBar,
	TitleBarPrimaryColor, TitleBarSecondaryColor,
	
	## UI
	UIScale,
}

func get_DBSettings_name(key: DBSettings)-> String:
	return DBSettings.find_key(key)

# SETTINGS
var info_app_version: String:
	get: return _get_info(1)

var default_sessions_count: int:
	get: return int(_get_value(DBSettings.SessionsCount))
	set(value): _set_value(DBSettings.SessionsCount, value)

var default_session_length: int:
	get: return int(_get_value(DBSettings.SessionLength))
	set(value): _set_value(DBSettings.SessionLength, value)

var default_break_length: int:
	get: return int(_get_value(DBSettings.BreakLength))
	set(value): _set_value(DBSettings.BreakLength, value)

var is_use_12_hour_format: bool:
	get: return bool(int(_get_value(DBSettings.IsUse12HourFormat)))
	set(value): _set_value(DBSettings.IsUse12HourFormat, int(value))

var is_hide_session_timer_controls: bool:
	get: return bool(int(_get_value(DBSettings.HideSessionTimerTimeChangeButtons)))
	set(value): _set_value(DBSettings.HideSessionTimerTimeChangeButtons, int(value))

var is_hide_break_timer_controls: bool:
	get: return bool(int(_get_value(DBSettings.HideBreakTimerTimeChangeButtons)))
	set(value): _set_value(DBSettings.HideBreakTimerTimeChangeButtons, int(value))

var path_session_end_notification_timer: String:
	get: return _get_value(DBSettings.PathSessionEndNotification)
	set(value): _set_value(DBSettings.PathSessionEndNotification, value, true)

var path_break_end_notification_timer: String:
	get: return _get_value(DBSettings.PathBreakEndNotification)
	set(value): _set_value(DBSettings.PathBreakEndNotification, value, true)

var volume_session_end_notification: float:
	get: return float(_get_value(DBSettings.VolumeSessionEndNotification))
	set(value): _set_value(DBSettings.VolumeSessionEndNotification, value)

var volume_break_end_notification: float:
	get: return float(_get_value(DBSettings.VolumeBreakEndNotification))
	set(value): _set_value(DBSettings.VolumeBreakEndNotification, value)

# THEME SETTINGS
## BACKGROUND
signal color_background_primary_changed
var color_background_primary: String:
	get: return _get_value(DBSettings.BackgroundPrimaryColor)
	set(value): 
		_set_value(DBSettings.BackgroundPrimaryColor, value, true)
		color_background_primary_changed.emit()

## MAIN
signal color_primary_changed
var color_primary: String:
	get: return _get_value(DBSettings.PrimaryColor)
	set(value): 
		_set_value(DBSettings.PrimaryColor, value, true)
		color_primary_changed.emit()

signal color_secondary_changed
var color_secondary: String:
	get: return _get_value(DBSettings.SecondaryColor)
	set(value): 
		_set_value(DBSettings.SecondaryColor, value, true)
		color_secondary_changed.emit()

signal color_third_changed
var color_third: String:
	get: return _get_value(DBSettings.ThirdColor)
	set(value): 
		_set_value(DBSettings.ThirdColor, value, true)
		color_third_changed.emit()

signal color_danger_primary_changed
var color_danger_primary: String:
	get: return _get_value(DBSettings.DangerPrimaryColor)
	set(value): 
		_set_value(DBSettings.DangerPrimaryColor, value, true)
		color_danger_primary_changed.emit()

signal color_danger_secondary_changed
var color_danger_secondary: String:
	get: return _get_value(DBSettings.DangerSecondaryColor)
	set(value): 
		_set_value(DBSettings.DangerSecondaryColor, value, true)
		color_danger_secondary_changed.emit()

## TITLE BAR
signal is_use_custom_title_bar_changed
var is_use_custom_title_bar: bool:
	get: return bool(int(_get_value(DBSettings.IsUseCustomTitleBar)))
	set(value): 
		_set_value(DBSettings.IsUseCustomTitleBar, int(value))
		is_use_custom_title_bar_changed.emit()

signal color_title_bar_primary_changed
var color_title_bar_primary: String:
	get: return _get_value(DBSettings.TitleBarPrimaryColor)
	set(value): 
		_set_value(DBSettings.TitleBarPrimaryColor, value, true)
		color_title_bar_primary_changed.emit()

signal color_title_bar_secondary_changed
var color_title_bar_secondary: String:
	get: return _get_value(DBSettings.TitleBarSecondaryColor)
	set(value): 
		_set_value(DBSettings.TitleBarSecondaryColor, value, true)
		color_title_bar_secondary_changed.emit()

# UI
signal ui_scale_changed
var ui_scale: float:
	get: return float(_get_value(DBSettings.UIScale))
	set(value):
		_set_value(DBSettings.UIScale, value)
		ui_scale_changed.emit()

func _get_value(id: int):
	DatabaseManager.db.query("select Value from Settings where ID = " + str(id))
	return DatabaseManager.db.query_result[0].get("Value")

func _set_value(id: int, value, is_string: bool = false):
	var query: String = "update Settings set Value = '" + str(value) + "' where ID = " + str(id)\
		if is_string else "update Settings set Value = " + str(value) + " where ID = " + str(id)
	DatabaseManager.db.query(query)

func _get_info(id: int):
	DatabaseManager.db.query("select Value from Information where ID = " + str(id))
	return DatabaseManager.db.query_result[0].get("Value")

func _ready():
	_update_theme_title_bar()
	color_title_bar_primary_changed.connect(_update_theme_title_bar)
	color_title_bar_secondary_changed.connect(_update_theme_title_bar)
	DatabaseManager.restored_defaults.connect(_emit_all_signals)

# Theme Settings
func _update_theme_title_bar():
	# Setting Primary
	var primary_color: Color = Color.from_string(color_title_bar_primary, Color.MAGENTA)
	var panel_style_box: StyleBoxFlat = theme_title_bar.get_stylebox("panel", "PanelContainer")
	panel_style_box.bg_color = primary_color
	theme_title_bar.set_color("font_hover_color", "Button", primary_color)
	theme_title_bar.set_color("font_hover_pressed_color", "Button", primary_color)
	
	# Setting Secondary
	var secondary_color: Color = Color.from_string(color_title_bar_secondary, Color.MAGENTA)
	var button_hover_style_box: StyleBoxFlat = theme_title_bar.get_stylebox("hover", "Button")
	button_hover_style_box.bg_color = secondary_color
	theme_title_bar.set_color("font_color", "Button", secondary_color)
	theme_title_bar.set_color("font_focus_color", "Button", secondary_color)
	theme_title_bar.set_color("font_pressed_color", "Button", secondary_color)

func _emit_all_signals():
	color_background_primary_changed.emit()
	
	color_primary_changed.emit()
	color_secondary_changed.emit()
	color_third_changed.emit()
	
	color_danger_primary_changed.emit()
	color_danger_secondary_changed.emit()
	
	is_use_custom_title_bar_changed.emit()
	color_title_bar_primary_changed.emit()
	color_title_bar_secondary_changed.emit()
