class_name SavePresetPage extends Control

var preset: Preset

@export var preset_edit: LineEdit
@export var tag_edit: LineEdit
@export var session_count_edit: LineEdit
@export var session_length_edit: LineEdit
@export var break_length_edit: LineEdit
@export var auto_break_toggle: BaseButton
@export var auto_session_toggle: BaseButton

@export_category("Resources")
@export var presets_page_res: Resource = preload("res://scenes/pages/save_preset_page.tscn")
@export var session_page_res: Resource

func _ready():
	print('potato')
	print(presets_page_res)
	tag_edit.text = str(randi())

func initialize(data: Dictionary):
	preset = data.get("preset")
	preset_edit.text = preset.name_
	tag_edit.text = str(preset.default_tag_id)
	session_count_edit.text = str(preset.sessions_count)
	session_length_edit.text = str(preset.session_length)
	break_length_edit.text = str(preset.break_length)
	auto_session_toggle.button_pressed = preset.is_auto_start_session
	auto_break_toggle.button_pressed = preset.is_auto_start_break

func _save_preset_data(is_start: bool = false):
	if not preset_edit.text:
		push_warning("Preset name not set")
		return
	
	if not preset:
		preset = Preset.new()
	
	preset.name_ = preset_edit.text
	# preset.default_tag_id = # to be done
	preset.sessions_count = int(session_count_edit.text)
	preset.session_length = int(session_length_edit.text)
	preset.break_length = int(break_length_edit.text)
	preset.is_auto_start_break = auto_break_toggle.button_pressed
	preset.is_auto_start_session = auto_session_toggle.button_pressed
	PresetsManager.save_preset(preset) 
	
	if is_start:
		# TODO: start session
		pass
	else:
		Global.AppMan.load_gui_scene(presets_page_res)
