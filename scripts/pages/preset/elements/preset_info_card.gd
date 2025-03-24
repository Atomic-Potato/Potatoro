class_name PresetInfoCard extends Node

@export var name_label: Label
@export var tag_label: Label
@export var sessions_lable: Label
@export var length_lable: Label
@export var break_lable: Label
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
	if PresetsManager.is_preset_id_buffered(preset.ID):
		Global.AppMan.load_gui_scene(Global.SceneCont.preset_page_session, {"preset" : preset})
	else:
		Global.AppMan.load_gui_scene(Global.SceneCont.preset_page_save_preset, {"preset" : preset})
