extends Page

@export_category("Info")
@export var label_app_version: Label
@export var label_database_path: Label

@export_category("Default Values")
@export var edit_sessions_count: LineEdit
@export var edit_session_length: LineEdit
@export var edit_break_length: LineEdit

@export_category("Timer Settings")
@export var check_hour_format: CheckBox
@export var check_hide_session_controls: CheckBox
@export var check_hide_break_controls: CheckBox

@export_category("Sound Settings")
@export var edit_session_notification_path: LineEdit
@export var edit_break_notification_path: LineEdit
@export var slider_session_notification_volume: HSlider
@export var slider_break_notification_volume: HSlider

@export_category("Theme")
@export var color_background: ColorPickerButton
@export var color_primary: ColorPickerButton
@export var color_secondary: ColorPickerButton
@export var color_danger: ColorPickerButton
@export var check_custom_title_bar: CheckBox
@export var color_title_bar_primary: ColorPickerButton
@export var color_title_bar_secondary: ColorPickerButton

#@export_category("Other") # in case i do need it later

func _ready():
	# INFO: Infromation
	label_app_version.text = Global.APP_VERSION
	label_database_path.text = str(DatabaseManager.db.path)
	
	# INFO: Default Values
	edit_sessions_count.text = str(SettingsManager.default_sessions_count)
	edit_sessions_count.text_changed.connect(
		func(value): SettingsManager.default_sessions_count = int(value))
	
	edit_session_length.text = str(SettingsManager.default_session_length)
	edit_session_length.text_changed.connect(
		func(value): SettingsManager.default_session_length = int(value))
	
	edit_break_length.text = str(SettingsManager.default_break_length)
	edit_break_length.text_changed.connect(
		func(value): SettingsManager.default_break_length = int(value))
	
	# INFO: Timer Settings
	check_hour_format.set_pressed_no_signal(SettingsManager.is_use_12_hour_format)
	check_hour_format.toggled.connect(
		func(value): SettingsManager.is_use_12_hour_format = value)
		
	check_hide_session_controls.set_pressed_no_signal(SettingsManager.is_hide_session_timer_controls)
	check_hide_session_controls.toggled.connect(
		func(value): SettingsManager.is_hide_session_timer_controls = value)
	
	check_hide_break_controls.set_pressed_no_signal(SettingsManager.is_hide_break_timer_controls)
	check_hide_break_controls.toggled.connect(
		func(value): SettingsManager.is_hide_break_timer_controls = value)
	
	# INFO: Sound Settings
	edit_session_notification_path.text = str(SettingsManager.path_session_end_notification_timer)
	edit_session_notification_path.text_changed.connect(
		func(value): SettingsManager.path_session_end_notification_timer = value)
	
	edit_break_notification_path.text = str(SettingsManager.path_break_end_notification_timer)
	edit_break_notification_path.text_changed.connect(
		func(value): SettingsManager.path_break_end_notification_timer = value)
		
	slider_session_notification_volume.value = SettingsManager.volume_session_end_notification
	slider_session_notification_volume.value_changed.connect(
		func(value): SettingsManager.volume_session_end_notification = value)
	
	slider_break_notification_volume.value = SettingsManager.volume_break_end_notification
	slider_break_notification_volume.value_changed.connect(
		func(value): SettingsManager.volume_break_end_notification = value)
	
	# INFO: Theme
	color_background.color = Color.from_string(SettingsManager.color_background_primary, Color.MAGENTA)
	color_background.color_changed.connect(
		func(value: Color): SettingsManager.color_background_primary = value.to_html(false))
	
	color_primary.color = Color.from_string(SettingsManager.color_primary, Color.MAGENTA)
	color_primary.color_changed.connect(
		func(value: Color): SettingsManager.color_primary = value.to_html(false))
	
	color_secondary.color = Color.from_string(SettingsManager.color_secondary, Color.MAGENTA)
	color_secondary.color_changed.connect(
		func(value: Color): SettingsManager.color_secondary = value.to_html(false))
	
	color_danger.color = Color.from_string(SettingsManager.color_danger_primary, Color.MAGENTA)
	color_danger.color_changed.connect(
		func(value: Color): SettingsManager.color_danger_primary = value.to_html(false))
	
	check_custom_title_bar.set_pressed_no_signal(SettingsManager.is_use_custom_title_bar)
	check_custom_title_bar.toggled.connect(
		func(value): SettingsManager.is_use_custom_title_bar = value)
	
	color_title_bar_primary.color = Color.from_string(SettingsManager.color_title_bar_primary, Color.MAGENTA)
	color_title_bar_primary.color_changed.connect(
		func(value: Color): SettingsManager.color_title_bar_primary = value.to_html(false))
	
	color_title_bar_secondary.color = Color.from_string(SettingsManager.color_title_bar_secondary, Color.MAGENTA)
	color_title_bar_secondary.color_changed.connect(
		func(value: Color): SettingsManager.color_title_bar_secondary = value.to_html(false))
