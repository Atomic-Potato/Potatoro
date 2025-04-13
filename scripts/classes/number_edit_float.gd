class_name NumberEditFloat extends LineEdit

@export var value: float = 0
@export var min: float = 0
@export var max: float = 1000

func _ready():
	_clamp_value()
	text = str(value)
	text_changed.connect(_update_value_from_text)
	focus_exited.connect(_set_valid_float)

func _update_value_from_text(new_text: String):
	if not new_text:
		value = min
		text = str(value)
		caret_column = 1
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

func _clamp_value():
	value = clamp(value, min, max)

func _set_valid_float():
	if text.is_valid_float() and text.ends_with("."):
		value = float(text)
		_clamp_value()
		text = str(value)
