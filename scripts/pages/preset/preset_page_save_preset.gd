extends Control

@warning_ignore("shadowed_global_identifier")
var preset: Preset

@export var preset_edit: LineEdit
@export var preset_edit_danger: BlinkCanvasItem
@export var tag_edit: LineEdit
@export var session_count_spin_box: SpinBox
@export var session_length_spin_box: SpinBox
@export var break_length_spin_box: SpinBox
@export var auto_break_toggle: BaseButton
@export var auto_session_toggle: BaseButton

func initialize(data: Dictionary):
	preset = data.get("preset")
	preset_edit.text = preset.name_
	tag_edit.text = str(preset.default_tag_id)
	
	session_count_spin_box.value = preset.sessions_count
	session_length_spin_box.value = preset.session_length
	break_length_spin_box.value = preset.break_length
	
	auto_session_toggle.button_pressed = preset.is_auto_start_session
	auto_break_toggle.button_pressed = preset.is_auto_start_break

func _ready():
	if not preset:
		_update_fields()
	
	# NOTE: I was using this before i changed the fields to spin boxes instead of line edits
	# and in line edits i was just updating the placeholder text, but theres no placeholder in spinboxes
	# so it is waht it is
	#self.visibility_changed.connect(_update_fields)
	
func _load_prests_page():
	Global.AppMan.load_gui_scene(Global.SceneCont.preset_page_presets)

func _save_preset_data():
	if not preset_edit.text:
		preset_edit_danger.set_active()
		return
	
	if not preset:
		preset = Preset.new()
	
	preset.name_ = preset_edit.text
	# preset.default_tag_id = # TODO
	
	preset.sessions_count = session_count_spin_box.value
	preset.session_length = session_length_spin_box.value
	preset.break_length = break_length_spin_box.value
		
	preset.is_auto_start_break = int(auto_break_toggle.button_pressed)
	preset.is_auto_start_session = int(auto_session_toggle.button_pressed)
	PresetsManager.save_preset(preset) 
	
	Global.AppMan.load_gui_scene(Global.SceneCont.preset_page_presets)

func _start_preset():
	_save_preset_data()
	preset.buffer_ID = PresetsManager.save_buffered_preset(preset)
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
		session_count_spin_box.value = SettingsManager.default_sessions_count
		session_length_spin_box.value = SettingsManager.default_session_length
		break_length_spin_box.value = SettingsManager.default_break_length
		auto_break_toggle.button_pressed = false
		auto_session_toggle.button_pressed = false


func _delete_preset_callable(is_delete_confirmed: bool):
	if not is_delete_confirmed:
		return
	PresetsManager.delete_preset(preset.ID)
	Global.AppMan.load_gui_scene(Global.SceneCont.preset_page_presets)

func _update_fields():
	session_count_spin_box.value = SettingsManager.default_sessions_count
	session_length_spin_box.value = SettingsManager.default_session_length
	break_length_spin_box.value = SettingsManager.default_break_length
