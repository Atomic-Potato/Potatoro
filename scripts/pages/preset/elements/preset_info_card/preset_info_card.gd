class_name PresetInfoCard extends Page

@export var name_label: Label
@export var tag_label: Label
@export var reset_container: Control

@export_category("Child Pages")
@export var page_values: Page
@export var page_timer: Page
@export var page_message: Page

@warning_ignore("shadowed_global_identifier")
var preset: Preset

func initialize(data: Dictionary = {}):
	preset = data.get("preset")

func enter():
	reset_container.hide()
	hide_all_child_pages()
	update_text()
	update_page()

func update():
	current_page.update()

func update_text():
	name_label.text = preset.name_
	tag_label.text = str(preset.default_tag_id) # TODO: fix it, when tags are implemented

func update_page():
	if not PresetsManager.is_preset_id_buffered(preset.ID, false):
		set_page(page_values)
	elif PresetsManager.is_in_session(preset.ID) or PresetsManager.is_in_break(preset.ID):
		set_page(page_timer)
	else:
		set_page(page_message)

func load_make_edit_preset_page():
	preset = PresetsManager.get_preset(preset.ID)
	if PresetsManager.is_preset_id_buffered(preset.ID):
		Global.AppMan.load_gui_scene(Global.SceneCont.preset_page_session, {"preset" : preset})
	else:
		Global.AppMan.load_gui_scene(Global.SceneCont.preset_page_save_preset, {"preset" : preset})

func reset_preset():
	if not preset:
		push_error("Cant reset a null preset!")
		return
	
	PresetsManager.end_buffered_preset(preset.ID)
	preset = PresetsManager.get_preset(preset.ID)
	update_page()
	
	if AudioManager.is_playing_notification():
		AudioManager.stop_notification()
