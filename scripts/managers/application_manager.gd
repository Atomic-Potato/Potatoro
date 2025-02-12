class_name ApplicationManager extends Node

@export_category("GUI")
@export var gui: Control
var default_gui_scene_res: PackedScene
@export_category("2D")
@export var world_2d: Node2D
var default_2d_scene_res: PackedScene
@export_category("3D")
@export var world_3d: Node3D
var default_3d_scene_res: PackedScene

var current_gui_scene
var current_2d_scene
var current_3d_scene

func _ready():
	default_gui_scene_res = Global.SceneCont.preset_page_presets
	
	Global.AppMan = self
	if default_gui_scene_res:
		load_gui_scene(default_gui_scene_res)
	if default_2d_scene_res:
		load_2d_scene(default_2d_scene_res)
	if default_3d_scene_res:
		load_3d_scene(default_3d_scene_res)

func load_gui_scene(scene_res: PackedScene, data: Dictionary = {}):
	if not scene_res:
		push_error("Could not load GUI scene. resource not found!")
		return
	
	if current_gui_scene:
		current_gui_scene.queue_free()
	current_gui_scene = scene_res.instantiate()
	
	if not data.is_empty():
		if current_gui_scene.get_script():
			if current_gui_scene.has_method("initialize"):
				current_gui_scene.initialize(data)
			else:
				push_error(
					"Data was passed to " + scene_res.resource_name 
					+ " but no initialize function was found")
		else:
			push_error("Data was passed to " + scene_res.resource_name 
				+ " but no script was found")
	
	gui.add_child(current_gui_scene)

func load_2d_scene(scene_res: PackedScene):
	if not scene_res:
		push_error("Could not load 2D scene. resource not found!")
		return
	if current_2d_scene:
		current_2d_scene.queue_free()
	current_2d_scene = scene_res.instantiate()
	world_2d.add_child(current_2d_scene)

func load_3d_scene(scene_res: PackedScene):
	if not scene_res:
		push_error("Could not load 3D scene. resource not found!")
		return
	if current_3d_scene:
		current_3d_scene.queue_free()
	current_3d_scene = scene_res.instantiate()
	world_3d.add_child(current_3d_scene)
