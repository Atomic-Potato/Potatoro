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
@export var edit_session_notification_volume: HSlider
@export var edit_break_notification_volume: HSlider

@export_category("Theme")
@export var color_background: ColorPickerButton
@export var color_primary: ColorPickerButton
@export var color_danger: ColorPickerButton

@export_category("Other")
@export var check_custom_title_bar: CheckBox
