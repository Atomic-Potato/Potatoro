class_name PresetInfoCard extends Node

@export var name_label: Label
@export var tag_label: Label
@export var sessions_lable: Label
@export var length_lable: Label
@export var break_lable: Label
@export_category("Resources")
@export var save_preset_page: Resource

var preset: Preset:
	set(value):
		preset = value
		update_text()
		
func update_text():
	name_label.text = preset.name_
	tag_label.text = str(preset.default_tag_id) # TODO: fix it, when tags are implemented
	sessions_lable.text = str(preset.sessions_count)
	length_lable.text = str(preset.session_length)
	break_lable.text = str(preset.break_length)

func load_make_edit_preset_page():
	Global.AppMan.load_gui_scene(save_preset_page, {"preset" : preset})
