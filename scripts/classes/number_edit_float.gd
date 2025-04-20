class_name NumberEditFloat extends LineEdit

## use set_value() when needing to change this via script
@export var value: float = 0
@export var min: float = 0
@export var max: float = 1000
@export var is_set_value_on_ready: bool = true
@export var is_update_value_on_submit: bool = false

signal value_changed

func _ready():
	if is_set_value_on_ready:
		_clamp_value()
		text = str(value)
	if not is_update_value_on_submit:
		text_changed.connect(_update_value_from_text)
		text_submitted.connect(_set_valid_value_from_text)
	else:
		text_submitted.connect(_update_value_from_text.bind(true))
	focus_exited.connect(_set_valid_float)

func set_value(new_value: float)-> void:
	value = new_value
	_clamp_value()
	text = str(value)
	value_changed.emit()

func _update_value_from_text(new_text: String, is_submitted: bool = false):
	if not new_text \
	or (not is_submitted and new_text.is_valid_float() and not is_in_range(float(new_text))):
		text = str(new_text)
		caret_column = new_text.length()
		return
	
	if not new_text.is_valid_float():
		text = str(value)
		return 
	
	if new_text.ends_with("."):
		return
	value = float(text)
	_clamp_value()
	var caret_column_cache = caret_column
	text = str(value)
	caret_column = caret_column_cache
	value_changed.emit()

func _clamp_value():
	value = clamp(value, min, max)
	pass

func _set_valid_value_from_text(new_text: String):
	if not new_text.is_valid_float() or not is_in_range(float(new_text)):
		_clamp_value()
		text = str(value)
		return
	value = float(new_text)
	_clamp_value()
	text = str(value)
	value_changed.emit()

func _set_valid_float():
	if not text:
		text = str(value)
	elif text.is_valid_float() and text.ends_with("."):
		value = float(text)
		_clamp_value()
		text = str(value)
		value_changed.emit()

func is_in_range(val: float)-> bool:
	return min <= val and val <= max
