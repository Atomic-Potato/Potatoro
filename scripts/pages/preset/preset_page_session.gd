extends Page

var preset: Preset
var session: Session
var break_: Break

var session_cache: Session

@export_category("General Nodes")
@export var content_parent: Control

@export_category("Child Pages")
@export var page_session_setup: Page
@export var page_session_timer: Page
@export var page_session_finish: Page
@export var page_break_setup: Page
@export var page_break_timer: Page
@export var page_break_finish: Page


var cache_remaining_session_time: int # used to check if the session was skipped

func initialize(data: Dictionary = {}):
	preset = data.get("preset")
	if preset.current_session_id != 0:
		session = SessionsManager.get_loaded_buffered_session(preset.current_session_id)
	if preset.current_break_id != 0:
		break_ = BreaksManager.get_loaded_break(preset.current_break_id)

func _ready():
	hide_all_child_pages()
	
	# TODO: set appropriate page
	if PresetsManager.is_in_session(preset.ID):
		set_page(page_session_timer)
	elif PresetsManager.is_in_break(preset.ID):
		set_page(page_break_timer)
	elif preset.next_timer_type_id == PresetsManager.TimerTypes.Session:
		if preset.is_auto_start_session:
			set_page(page_session_timer)
		else:
			set_page(page_session_setup)
	elif preset.next_timer_type_id == PresetsManager.TimerTypes.Break:
		if preset.is_auto_start_break:
			set_page(page_break_timer)
		else:
			set_page(page_break_setup)
	else:
		set_page(page_session_timer)

func _process(_delta):
	current_page.update()

func hide_all_child_pages():
	for child in content_parent.get_children():
		child.visible = false

func load_preset_page_presets():
	Global.AppMan.load_gui_scene(Global.SceneCont.preset_page_presets)

