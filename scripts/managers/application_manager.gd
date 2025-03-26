class_name ApplicationManager extends Tab

@export_category("Tabs")
@export var tab_default: Tab
@export var tab_potatoro: Tab
@export var tab_calendar: Tab
@export var tab_tags: Tab
@export var tab_settings: Tab
@export_category("NavBarButtons")
@export var nav_bar: Control
@export var button_tab_default: Button
@export var button_tab_potatoro: Button
@export var button_tab_calendar: Button
@export var button_tab_tags: Button
@export var button_tab_settings: Button

func _ready():
	Global.AppMan = self
	set_tab(tab_default)
	_unpress_all_nav_bar_buttons()
	button_tab_default.set_pressed_no_signal(true)

func load_gui_scene(scene_res: PackedScene, data: Dictionary = {}, is_popup: bool = false):
	current_tab.load_gui_scene(scene_res, data, is_popup)

func load_2d_scene(scene_res: PackedScene):
	current_tab.load_2d_scene(scene_res)
	
func load_3d_scene(scene_res: PackedScene):
	current_tab.load_3d_scene(scene_res)

func _set_tab_potatoro():
	set_tab(tab_potatoro)
	_unpress_all_nav_bar_buttons()
	button_tab_potatoro.set_pressed_no_signal(true)

func _set_tab_calendar():
	set_tab(tab_calendar)
	_unpress_all_nav_bar_buttons()
	button_tab_calendar.set_pressed_no_signal(true)
	
func _set_tab_tags():
	set_tab(tab_tags)
	_unpress_all_nav_bar_buttons()
	button_tab_tags.set_pressed_no_signal(true)
	
func _set_tab_settings():
	set_tab(tab_settings)
	_unpress_all_nav_bar_buttons()
	button_tab_settings.set_pressed_no_signal(true)

func _unpress_all_nav_bar_buttons():
	for child:Button in nav_bar.get_children():
		child.set_pressed_no_signal(false)
