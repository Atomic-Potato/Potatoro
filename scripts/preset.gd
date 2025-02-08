class_name Preset_DEPRECATED extends Control

@export var preset_name: String = "New Preset"
@export var session_count: int = 8
@export var session_length_in_minutes: int = 50
@export var break_length_in_minutes: int = 10

@export var session_object: session
@export var preset_name_label: Label
@export var sessions_count_label: Label

var sessions_complete: int = 0

func _ready():
	session_object.session_finish.connect(add_session)
	_update_text()

func add_session():
	sessions_complete += 1
	_update_text()
	
func remove_session():
	if sessions_complete <= 0:
		return
	sessions_complete -= 1
	_update_text()

func go_to_presets():
	# ask game manager to load presets
	pass

func _update_text():
	preset_name_label.text = preset_name
	sessions_count_label.text = type_convert(sessions_complete, TYPE_STRING) + "/" + type_convert(session_count, TYPE_STRING)

