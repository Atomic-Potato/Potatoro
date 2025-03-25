extends Page

@export var sessions_lable: Label
@export var length_lable: Label
@export var break_lable: Label

func enter():
	update_text()

func update_text():
	sessions_lable.text = str(parent.preset.sessions_count)
	length_lable.text = str(parent.preset.session_length)
	break_lable.text = str(parent.preset.break_length)
