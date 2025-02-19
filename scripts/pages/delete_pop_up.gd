class_name DeletePopUp extends Control

@export var label_delete_message: Label
signal response(is_accepted: bool)

func initialize(data: Dictionary):
	label_delete_message.text = data.get("DeleteMessage")
	response.connect(data.get("Callable"))

func accept():
	response.emit(true)
	queue_free()

func decline():
	response.emit(false)
	queue_free()
