class_name TitleBar extends Control

# NOTE: 
#		if you wish to improve it in the future try watching this:
#		https://youtu.be/IbMeHU7um_o?si=VMdD2Pk2yCVuYX1u

# TODO:
# - when draging from maximized to windowed, 
#	set the position to be relative to the mouse when it was maximized
# - Snap windows to edges on mouse drag to edge and release
# - allow window to go through screen edges

var is_left_mouse_button_held: bool
var mouse_pressed_position_offset: Vector2i

func _process(_delta):
	if is_left_mouse_button_held:
		var new_position = \
			DisplayServer.mouse_get_position() + mouse_pressed_position_offset
		DisplayServer.window_set_position(new_position)
	pass
	
func maximize():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	
func minimize():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)

func exit():
	get_tree().quit()

var i = 0
func _on_color_rect_gui_input(event):
	if event is InputEventMouseButton:
		if event.get_button_index() == MOUSE_BUTTON_LEFT:
			is_left_mouse_button_held = !is_left_mouse_button_held
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				DisplayServer.window_set_position(DisplayServer.mouse_get_position())
				mouse_pressed_position_offset = Vector2i.ZERO
			else:
				mouse_pressed_position_offset = \
					DisplayServer.window_get_position() - DisplayServer.mouse_get_position()
