extends Page

@export var label_message: BlinkCanvasItem
@export var reset_container: Control

func enter():
	label_message.set_active()
	reset_container.show()
	if parent.preset.next_timer_type_id == PresetsManager.TimerTypes.Session:
		label_message.text = "BREAK\nFINISHED"
	else:
		label_message.text = "SESSION\nFINISHED"

func exit():
	label_message.set_inactive()
	reset_container.hide()
