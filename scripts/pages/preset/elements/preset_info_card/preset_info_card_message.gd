extends Page

@export var label_message: Label

func enter():
	label_message.show()
	if parent.preset.next_timer_type_id == PresetsManager.TimerTypes.Session:
		label_message.text = "BREAK\nFINISHED"
	else:
		label_message.text = "SESSION\nFINISHED"

func exit():
	label_message.hide()
