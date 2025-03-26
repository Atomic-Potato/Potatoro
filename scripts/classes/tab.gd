class_name Tab extends Node

@export_category("GUI")
@export var gui: Control
@export_category("2D")
@export var world_2d: Node2D
@export_category("3D")
@export var world_3d: Node3D

var current_gui_scene: Control
var current_2d_scene: Node2D
var current_3d_scene: Node3D

var parent: Tab
var current_tab: Tab

func enter():
	if current_gui_scene:
		current_gui_scene.visible = true
	if current_2d_scene:
		current_2d_scene.visible = true
	if current_3d_scene:
		current_3d_scene.visible = true

func exit():
	if current_gui_scene:
		current_gui_scene.visible = false
	if current_2d_scene:
		current_2d_scene.visible = false
	if current_3d_scene:
		current_3d_scene.visible = false

func set_tab(tab: Tab):
	if not tab:
		push_error("Cannot set null tab!") 
		
	if current_tab:
		current_tab.exit()
		
	current_tab = tab
	current_tab.parent = self
	current_tab.enter()

func load_gui_scene(scene_res: PackedScene, data: Dictionary = {}, is_popup: bool = false):
	if not scene_res:
		push_error("Could not load GUI scene. resource not found!")
		return
	
	if current_gui_scene and not is_popup:
		current_gui_scene.queue_free()
	var instance = scene_res.instantiate()
	current_gui_scene = instance if not is_popup else current_gui_scene
	
	if not data.is_empty():
		if instance.get_script():
			if instance.has_method("initialize"):
				instance.initialize(data)
			else:
				push_error(
					"Data was passed to " + scene_res.resource_name 
					+ " but no initialize function was found")
		else:
			push_error("Data was passed to " + scene_res.resource_name 
				+ " but no script was found")
	
	gui.add_child(instance)

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
