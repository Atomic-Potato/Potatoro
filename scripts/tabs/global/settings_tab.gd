extends Tab

func enter():
	if not current_gui_scene:
		load_gui_scene(Global.SceneCont.page_settings, {"data": "initialize"})
	
	if current_gui_scene:
		current_gui_scene.visible = true
	if current_2d_scene:
		current_2d_scene.visible = true
	if current_3d_scene:
		current_3d_scene.visible = true
