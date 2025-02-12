class_name PackedScenesContainer extends Node

@export_category("Preset")
@export var preset_info_card: PackedScene
@export var preset_page_presets: PackedScene
@export var preset_page_save_preset: PackedScene
@export var preset_page_session: PackedScene

func _ready():
	Global.SceneCont = self
