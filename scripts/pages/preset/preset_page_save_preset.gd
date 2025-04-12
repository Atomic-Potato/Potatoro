extends Control

var preset_: Preset

@export var preset_edit: LineEdit
@export var preset_edit_danger: BlinkCanvasItem
@export var tag_edit: LineEdit
@export var session_count_spin_box: SpinBox
@export var session_length_spin_box: SpinBox
@export var break_length_spin_box: SpinBox
@export var auto_break_toggle: BaseButton
@export var auto_session_toggle: BaseButton

func initialize(data: Dictionary):
	preset_ = data.get("preset")
	preset_edit.text = preset_.name_
	tag_edit.text = str(preset_.default_tag_id)
	
	session_count_spin_box.value = preset_.sessions_count
	session_length_spin_box.value = preset_.session_length
	break_length_spin_box.value = preset_.break_length
	
	auto_session_toggle.button_pressed = preset_.is_auto_start_session
	auto_break_toggle.button_pressed = preset_.is_auto_start_break

func _ready():
	if not preset_:
		_update_fields()
	
	# NOTE: I was using this before i changed the fields to spin boxes instead of line edits
	# and in line edits i was just updating the placeholder text, but theres no placeholder in spinboxes
	# so it is waht it is
	#self.visibility_changed.connect(_update_fields)
	
func _load_prests_page():
	Global.AppMan.load_gui_scene(Global.SceneCont.preset_page_presets)

func _save_preset_data()-> bool:
	if not preset_edit.text:
		preset_edit_danger.set_active()
		return false
	
	if not preset_:
		preset_ = Preset.new()
	
	preset_.name_ = preset_edit.text
	# preset_.default_tag_id = # TODO
	
	preset_.sessions_count = session_count_spin_box.value
	preset_.session_length = session_length_spin_box.value
	preset_.break_length = break_length_spin_box.value
		
	preset_.is_auto_start_break = int(auto_break_toggle.button_pressed)
	preset_.is_auto_start_session = int(auto_session_toggle.button_pressed)
	preset_.ID = PresetsManager.save_preset(preset_) 
	
	Global.AppMan.load_gui_scene(Global.SceneCont.preset_page_presets)
	return true

func _start_preset():
	if not _save_preset_data():
		return
	PresetsManager.save_buffered_preset(preset_)
	preset_ = PresetsManager.get_preset(preset_.ID)
	Global.AppMan.load_gui_scene(Global.SceneCont.preset_page_session, {"preset": preset_})

func _delete_preset():
	if preset_:
		Global.AppMan.load_gui_scene(
			Global.SceneCont.popup_delete, 
			{"DeleteMessage": "delete preset_ " + preset_.name_ + "?", "Callable": _delete_preset_callable},
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
	PresetsManager.delete_preset(preset_.ID)
	Global.AppMan.load_gui_scene(Global.SceneCont.preset_page_presets)

func _update_fields():
	session_count_spin_box.value = SettingsManager.default_sessions_count
	session_length_spin_box.value = SettingsManager.default_session_length
	break_length_spin_box.value = SettingsManager.default_break_length
