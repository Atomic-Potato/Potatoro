extends Page

var preset: Preset
var session: Session
var break_: Break

#@export var label_preset_name: Label
#@export var label_sessions_count: Label

@export_category("General Nodes")
@export var content_parent: Control

@export_category("Child Pages")
@export var page_default: Page
@export var page_session_setup: Page
@export var page_session_timer: Page
@export var page_session_finish: Page
@export var page_break_setup: Page
@export var page_break_timer: Page
@export var page_break_finish: Page


var cache_remaining_session_time: int # used to check if the session was skipped

func initialize(data: Dictionary = {}):
	preset = data.get("preset")
	session = SessionsManager.get_loaded_buffered_session(preset.current_session_id)

func _ready():
	hide_all_child_pages()
	
	# TODO: set appropriate page when coming from the presets page
	if session and SessionsManager.is_session_buffered(session.ID) \
	and SessionsManager.get_session_id_remaining_time_in_seconds(session.ID) <= 0:
		set_page(page_session_finish)
		return
	set_page(page_default)

func _process(_delta):
	current_page.update()

func hide_all_child_pages():
	for child in content_parent.get_children():
		child.visible = false

func load_preset_page_presets():
	Global.AppMan.load_gui_page(Global.SceneCont.preset_page_presets)

