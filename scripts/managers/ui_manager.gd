extends Node

func _ready():
	get_window().content_scale_factor = SettingsManager.ui_scale
	SettingsManager.ui_scale_changed.connect(
		func(): 
			get_window().content_scale_factor = SettingsManager.ui_scale
	)
