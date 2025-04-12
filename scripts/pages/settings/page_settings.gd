extends Page

@export var text_no_file_select: String = "[No file selected]"

@export_category("Info")
@export var label_app_version: Label
@export var label_database_path: Label

@export_category("Default Values")
@export var edit_sessions_count: NumberEdit
@export var edit_session_length: NumberEdit
@export var edit_break_length: NumberEdit

@export_category("Timer Settings")
@export var check_hour_format: CheckBox
@export var check_hide_session_controls: CheckBox
@export var check_hide_break_controls: CheckBox

@export_category("Sound Settings")
@export var open_file_dialog_session_notification: FileDialog
@export var open_file_dialog_break_notification: FileDialog
@export var slider_session_notification_volume: HSlider
@export var slider_break_notification_volume: HSlider
@export var label_session_notification_path: Label
@export var label_break_notification_path: Label

@export_category("Theme")
## Background
@export var color_background: ColorPickerButton
## Main
@export var color_primary: ColorPickerButton
@export var color_secondary: ColorPickerButton
@export var color_third: ColorPickerButton
## Danger
@export var color_danger_primary: ColorPickerButton
@export var color_danger_secondary: ColorPickerButton
## Titlebar
@export var check_custom_title_bar: CheckBox
@export var color_title_bar_primary: ColorPickerButton
@export var color_title_bar_secondary: ColorPickerButton

#@export_category("Other") # in case i do need it later # its one line, idk why i even kept it

func _ready():
	DirAccess.make_dir_absolute("user://sound")
	_update_fileds()
	_connect_fileds()
	_setup_open_file_dialogs()
	
func _update_fileds():
	# INFO: Infromation
	label_app_version.text = Global.APP_VERSION
	label_database_path.text = str(DatabaseManager.db.path)
	
	# INFO: Default Values
	edit_sessions_count.text = str(SettingsManager.default_sessions_count)
	edit_session_length.text = str(SettingsManager.default_session_length)
	edit_break_length.text = str(SettingsManager.default_break_length)
	
	# INFO: Timer Settings
	check_hour_format.set_pressed_no_signal(SettingsManager.is_use_12_hour_format)
	check_hide_session_controls.set_pressed_no_signal(SettingsManager.is_hide_session_timer_controls)
	check_hide_break_controls.set_pressed_no_signal(SettingsManager.is_hide_break_timer_controls)
	
	# INFO: Sound Settings
	label_session_notification_path.text = \
		ProjectSettings.globalize_path(SettingsManager.path_session_end_notification_timer)\
		if SettingsManager.path_session_end_notification_timer\
		else text_no_file_select
	label_break_notification_path.text = \
		ProjectSettings.globalize_path(SettingsManager.path_break_end_notification_timer)\
		if SettingsManager.path_break_end_notification_timer\
		else text_no_file_select
	slider_session_notification_volume.value = SettingsManager.volume_session_end_notification
	slider_break_notification_volume.value = SettingsManager.volume_break_end_notification
	
	# INFO: Theme
	color_background.color = Color.from_string(SettingsManager.color_background_primary, Color.MAGENTA)
	color_primary.color = Color.from_string(SettingsManager.color_primary, Color.MAGENTA)
	color_secondary.color = Color.from_string(SettingsManager.color_secondary, Color.MAGENTA)
	color_third.color = Color.from_string(SettingsManager.color_third, Color.MAGENTA)
	color_danger_primary.color = Color.from_string(SettingsManager.color_danger_primary, Color.MAGENTA)
	color_danger_secondary.color = Color.from_string(SettingsManager.color_danger_secondary, Color.MAGENTA)
	check_custom_title_bar.set_pressed_no_signal(SettingsManager.is_use_custom_title_bar)
	color_title_bar_primary.color = Color.from_string(SettingsManager.color_title_bar_primary, Color.MAGENTA)
	color_title_bar_secondary.color = Color.from_string(SettingsManager.color_title_bar_secondary, Color.MAGENTA)

func _connect_fileds():
	# INFO: Default Values
	edit_sessions_count.text_changed.connect(
		func(value): SettingsManager.default_sessions_count = int(value))
	edit_session_length.text_changed.connect(
		func(value): SettingsManager.default_session_length = int(value))
	edit_break_length.text_changed.connect(
		func(value): SettingsManager.default_break_length = int(value))
	
	# INFO: Timer Settings
	check_hour_format.toggled.connect(
		func(value): SettingsManager.is_use_12_hour_format = value)
	check_hide_session_controls.toggled.connect(
		func(value): SettingsManager.is_hide_session_timer_controls = value)
	check_hide_break_controls.toggled.connect(
		func(value): SettingsManager.is_hide_break_timer_controls = value)
	
	# INFO: Sound Settings
	slider_session_notification_volume.value_changed.connect(
		func(value): SettingsManager.volume_session_end_notification = value)
	slider_break_notification_volume.value_changed.connect(
		func(value): SettingsManager.volume_break_end_notification = value)
	
	# INFO: Theme
	color_background.color_changed.connect(
		func(value: Color): SettingsManager.color_background_primary = value.to_html(false))
	color_primary.color_changed.connect(
		func(value: Color): SettingsManager.color_primary = value.to_html(false))
	color_secondary.color_changed.connect(
		func(value: Color): SettingsManager.color_secondary = value.to_html(false))
	color_third.color_changed.connect(
		func(value: Color): SettingsManager.color_third = value.to_html(false))
	color_danger_primary.color_changed.connect(
		func(value: Color): SettingsManager.color_danger_primary = value.to_html(false))
	color_danger_secondary.color_changed.connect(
		func(value: Color): SettingsManager.color_danger_secondary = value.to_html(false))
	check_custom_title_bar.toggled.connect(
		func(value): SettingsManager.is_use_custom_title_bar = value)
	color_title_bar_primary.color_changed.connect(
		func(value: Color): SettingsManager.color_title_bar_primary = value.to_html(false))
	color_title_bar_secondary.color_changed.connect(
		func(value: Color): SettingsManager.color_title_bar_secondary = value.to_html(false))

func _setup_open_file_dialogs():
	open_file_dialog_session_notification.root_subfolder = "sound"
	open_file_dialog_session_notification.hide()
	open_file_dialog_session_notification.file_selected.connect(
		func(path: String): 
			SettingsManager.path_session_end_notification_timer = path
			label_session_notification_path.text = ProjectSettings.globalize_path(path)
	)
	open_file_dialog_break_notification.root_subfolder = "sound"
	open_file_dialog_break_notification.hide()
	open_file_dialog_break_notification.file_selected.connect(
		func(path: String): 
			SettingsManager.path_break_end_notification_timer = path
			label_break_notification_path.text = ProjectSettings.globalize_path(path) + "sound"
	)

func _restore_defaults():
	DatabaseManager.restore_default_settings()
	_update_fileds()

func _open_sound_directory()-> void:
	OS.shell_open(ProjectSettings.globalize_path("user://sound"))

func _open_user_directory():
	OS.shell_open(ProjectSettings.globalize_path("user://"))

func _open_db_directory():
	OS.shell_open(DatabaseManager.db.path.get_base_dir())
	
func _show_open_file_dialog_session_notification():
	open_file_dialog_session_notification.show()

func _show_open_file_dialog_break_notification():
	open_file_dialog_break_notification.show()

func _clear_session_notification_path():
	SettingsManager.path_session_end_notification_timer = ""
	label_session_notification_path.text = text_no_file_select

func _clear_break_notification_path():
	SettingsManager.path_break_end_notification_timer = ""
	label_break_notification_path.text = text_no_file_select
