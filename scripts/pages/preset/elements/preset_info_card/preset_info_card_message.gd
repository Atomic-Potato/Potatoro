extends Page

@export var label_message: BlinkCanvasItem

func enter():
	label_message.set_active()
	if parent.preset.next_timer_type_id == PresetsManager.TimerTypes.Session:
		label_message.text = "BREAK\nFINISHED"
	else:
		label_message.text = "SESSION\nFINISHED"

func exit():
	label_message.set_inactive()
