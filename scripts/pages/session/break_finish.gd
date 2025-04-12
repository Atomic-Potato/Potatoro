extends Page

@export var label_message: BlinkCanvasItem

func enter():
	label_message.set_active()
	
func exit():
	label_message.set_inactive()

func _continue_to_session():
	if parent.preset.is_auto_start_session:
		parent.set_page(parent.page_session_timer)
	else:
		parent.set_page(parent.page_session_setup)

func _restart_break():
	parent.set_page(parent.page_break_timer)
