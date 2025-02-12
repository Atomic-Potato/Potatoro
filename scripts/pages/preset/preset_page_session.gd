extends Control

var session: Session

@export var preset_name: String = "New Preset"
@export var session_count: int = 8
@export var session_length_in_minutes: int = 50
@export var break_length_in_minutes: int = 10
@export var preset_name_label: Label
@export var sessions_count_label: Label

func initialize(data: Dictionary):
	var session_id = data.get("preset")

func load_preset_page_presets():
	Global.AppMan.load_gui_page(Global.SceneCont.preset_page_presets)

func _update_text():
	preset_name_label.text = preset_name
	sessions_count_label.text = type_convert(sessions_complete, TYPE_STRING) + "/" + type_convert(session_count, TYPE_STRING)
