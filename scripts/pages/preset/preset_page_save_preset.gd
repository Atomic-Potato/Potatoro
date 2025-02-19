extends Control

var preset: Preset

@export var preset_edit: LineEdit
@export var tag_edit: LineEdit
@export var session_count_edit: LineEdit
@export var session_length_edit: LineEdit
@export var break_length_edit: LineEdit
@export var auto_break_toggle: BaseButton
@export var auto_session_toggle: BaseButton

func initialize(data: Dictionary):
	preset = data.get("preset")
	preset_edit.text = preset.name_
	tag_edit.text = str(preset.default_tag_id)
	session_count_edit.text = str(preset.sessions_count)
	session_length_edit.text = str(preset.session_length)
	break_length_edit.text = str(preset.break_length)
	auto_session_toggle.button_pressed = preset.is_auto_start_session
	auto_break_toggle.button_pressed = preset.is_auto_start_break

func _load_prests_page():
	Global.AppMan.load_gui_scene(Global.SceneCont.preset_page_presets)

func _save_preset_data():
	if not preset_edit.text:
		push_warning("Preset name not set")
		return
	
	if not preset:
		preset = Preset.new()
	
	preset.name_ = preset_edit.text
	# preset.default_tag_id = # TODO
	preset.sessions_count = int(session_count_edit.text)
	preset.session_length = int(session_length_edit.text)
	preset.break_length = int(break_length_edit.text)
	preset.is_auto_start_break = int(auto_break_toggle.button_pressed)
	preset.is_auto_start_session = int(auto_session_toggle.button_pressed)
	PresetsManager.save_preset(preset) 
	
	Global.AppMan.load_gui_scene(Global.SceneCont.preset_page_presets)

func _start_preset():
	var session:Session = SessionsManager.start_buffered_session(preset)
	preset.buffer_ID = PresetsManager.save_buffered_preset(preset, session.ID)
	Global.AppMan.load_gui_scene(Global.SceneCont.preset_page_session, {"preset": preset})

func _delete_preset():
	if preset:
		Global.AppMan.load_gui_scene(
			Global.SceneCont.popup_delete, 
			{"DeleteMessage": "delete preset " + preset.name_ + "?", "Callable": _delete_preset_callable},
			true
		)
		
	else:
		preset_edit.text = ''
		tag_edit.text = ''
		session_count_edit.text = ''
		session_length_edit.text = ''
		break_length_edit.text = ''
		auto_break_toggle.button_pressed = false
		auto_session_toggle.button_pressed = false


func _delete_preset_callable(is_delete_confirmed: bool):
	if not is_delete_confirmed:
		return
	PresetsManager.delete_preset(preset.ID)
	Global.AppMan.load_gui_scene(Global.SceneCont.preset_page_presets)
