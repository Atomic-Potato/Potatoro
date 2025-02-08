class_name PresetPage extends Control

var presets: Array[Preset]



func _ready():
	presets = PresetsManager.get_presets()
	for preset in presets:
		
