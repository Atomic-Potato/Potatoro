# NOTE: if you say to me "acshually u can make this script better this x way"
# I know, fuk off

extends Control

var preset: Preset
var session: Session
var break_: Break

@export var is_use_24_hour_format: bool = false # TODO: Get this data from the config table

# NOTE: Naming abbreviation rule:
# for nodes that are contained in content control nodes
# i put the first letter for each word in the content node name
# e.g: cst_lable_timer is a node in content_session_timer(_label_timer)
@export_category("General Nodes")
@export var label_preset_name: Label
@export var label_sessions_count: Label
@export var content_parent: Control


@export_category("Content")
@export var content_default: Control
@export var content_session_setup: Control
@export var content_session_timer: Control
@export var content_session_finish: Control
@export var content_break_setup: Control
@export var content_break_timer: Control
@export var content_break_finish: Control

var current_content: Control

var update_preset: Callable = func(): preset = PresetsManager.get_preset(preset.ID)

var cache_remaining_session_time: int # used to check if the session was skipped

func initialize(data: Dictionary):
	# TODO: do the initialization of the break instead of a session if the page was initialized during a break
	preset = data.get("preset")
	session = SessionsManager.get_loaded_buffered_session(preset.current_session_id)
	connect_session_finish_subscribers(session)

func _ready():
	if SessionsManager.is_session_buffered(session.ID) \
	and SessionsManager.get_session_id_remaining_time_in_seconds(session.ID) <= 0:
		_set_content(content_session_finish)
		return
	
	_hide_all_content()
	_set_content(content_default)
	
	_update_titles_text()
	_update_timer_text()
	if cst_button_pause_toggle.button_pressed:
		SessionsManager.pause_session(session.ID)
	_update_finish_hour()

func _process(_delta):
	# Process session timer
	if preset and PresetsManager.is_in_session(preset.ID):
		if not SessionsManager.is_session_paused(session.ID):
			_update_timer_text()
	# Process break timer
	elif preset and PresetsManager.is_in_break(preset.ID):
		if not BreaksManager.is_break_id_paused(break_.ID):
			_update_break_timer_label()

func _set_content(content: Control):
	if not content:
		push_error("Cannot set null content!") 
	if current_content:
		current_content.visible = false
	current_content = content
	current_content.visible = true

func _hide_all_content():
	for child in content_parent.get_children():
		child.visible = false

func load_preset_page_presets():
	Global.AppMan.load_gui_page(Global.SceneCont.preset_page_presets)

func connect_session_finish_subscribers(s: Session):
	if not s:
		push_error("Cannot connect subscribers to a null session")
	s.session_finish.connect(update_preset)
	s.session_finish.connect(_update_titles_text)
	s.session_finish.connect(_end_session_timer)



# SECTION_TITLE: Content Session Finish
func _continue_to_break():
	if preset.is_auto_start_break:
		_start_break()
	else:
		_set_content_break_setup()


















