extends Page

@export var label_message: Label

func enter():
	if parent.preset.next_timer_type_id == PresetsManager.TimerTypes.Session:
		label_message.text = "BREAK\nFINISHED"
	else:
		label_message.text = "SESSION\nFINISHED"
