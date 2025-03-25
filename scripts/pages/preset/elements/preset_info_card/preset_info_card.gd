class_name PresetInfoCard extends Page

@export var name_label: Label
@export var tag_label: Label

@export_category("Child Pages")
@export var page_values: Page
@export var page_timer: Page
@export var page_message: Page

var preset: Preset

func initialize(data: Dictionary = {}):
	preset = data.get("preset")

func enter():
	hide_all_child_pages()
	update_text()
	if not PresetsManager.is_preset_id_buffered(preset.ID, false):
		set_page(page_values)
	elif PresetsManager.is_in_session(preset.ID) or PresetsManager.is_in_break(preset.ID):
		set_page(page_timer)
	else:
		set_page(page_message)

func update():
	current_page.update()

func update_text():
	name_label.text = preset.name_
	tag_label.text = str(preset.default_tag_id) # TODO: fix it, when tags are implemented


func load_make_edit_preset_page():
	preset = PresetsManager.get_preset(preset.ID)
	if PresetsManager.is_preset_id_buffered(preset.ID):
		Global.AppMan.load_gui_scene(Global.SceneCont.preset_page_session, {"preset" : preset})
	else:
		Global.AppMan.load_gui_scene(Global.SceneCont.preset_page_save_preset, {"preset" : preset})
