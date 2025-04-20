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

@export_category("UI")
@export var edit_ui_scale: NumberEditFloat
@export var open_file_dialog_font_file: FileDialog
@export var label_font_file_path: Label

#@export_category("Other") # in case i do need it later # its one line, idk why i even kept it

func _ready():
	DirAccess.make_dir_absolute("user://sound")
	DirAccess.make_dir_absolute("user://fonts")
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
	
	# INFO: UI
	edit_ui_scale.text = str(SettingsManager.ui_scale)
	edit_ui_scale.value = SettingsManager.ui_scale
	label_font_file_path.text = \
		ProjectSettings.globalize_path(SettingsManager.path_font_file)\
		if SettingsManager.path_font_file\
		else text_no_file_select


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
	check_custom_title_bar.toggled.connect(
		func(value): SettingsManager.is_use_custom_title_bar = value)
		
	# INFO: UI
	edit_ui_scale.value_changed.connect(
		func(): SettingsManager.ui_scale = edit_ui_scale.value)

func _apply_theme():
		SettingsManager.color_background_primary = color_background.color.to_html(false)
		SettingsManager.color_primary = color_primary.color.to_html(false)
		SettingsManager.color_secondary = color_secondary.color.to_html(false)
		SettingsManager.color_third = color_third.color.to_html(false)
		SettingsManager.color_danger_primary = color_danger_primary.color.to_html(false)
		SettingsManager.color_danger_secondary = color_danger_secondary.color.to_html(false)
		SettingsManager.color_title_bar_primary = color_title_bar_primary.color.to_html(false)
		SettingsManager.color_title_bar_secondary = color_title_bar_secondary.color.to_html(false)

func _clear_theme():
	color_background.color = SettingsManager.color_background_primary
	color_primary.color = SettingsManager.color_primary
	color_secondary.color = SettingsManager.color_secondary
	color_third.color = SettingsManager.color_third
	color_danger_primary.color = SettingsManager.color_danger_primary
	color_danger_secondary.color = SettingsManager.color_danger_secondary
	color_title_bar_primary.color = SettingsManager.color_title_bar_primary
	color_title_bar_secondary.color = SettingsManager.color_title_bar_secondary


func _setup_open_file_dialogs():
	## SOUND
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
	
	## UI
	open_file_dialog_font_file.root_subfolder = "fonts"
	open_file_dialog_font_file.hide()
	open_file_dialog_font_file.file_selected.connect(
		func(path: String): 
			SettingsManager.path_font_file = path
			label_font_file_path.text = ProjectSettings.globalize_path(path)
	)

func _restore_defaults():
	DatabaseManager.restore_default_settings()
	_update_fileds()

func _open_sound_directory()-> void:
	OS.shell_open(ProjectSettings.globalize_path("user://sound"))

func _open_fonts_directory()-> void:
	OS.shell_open(ProjectSettings.globalize_path("user://fonts"))

func _open_user_directory():
	OS.shell_open(ProjectSettings.globalize_path("user://"))

func _open_db_directory():
	OS.shell_open(DatabaseManager.db.path.get_base_dir())
	
func _show_open_file_dialog_session_notification():
	open_file_dialog_session_notification.show()

func _show_open_file_dialog_break_notification():
	open_file_dialog_break_notification.show()

func _show_open_file_dialog_font_file():
	open_file_dialog_font_file.show()

func _clear_session_notification_path():
	SettingsManager.path_session_end_notification_timer = ""
	label_session_notification_path.text = text_no_file_select

func _clear_break_notification_path():
	SettingsManager.path_break_end_notification_timer = ""
	label_break_notification_path.text = text_no_file_select

func _clear_font_file_path():
	SettingsManager.path_font_file = ""
	label_font_file_path.text = text_no_file_select

func _add_ui_scale(value: float):
	edit_ui_scale.set_value(edit_ui_scale.value + value)
