class_name NumberEdit extends LineEdit

@export var value: int = 0
@export var min: int = 0
@export var max: int = 9223372036854775807

func _ready():
	_clamp_value()
	text = str(value)
	text_changed.connect(_update_value_from_text)

func _update_value_from_text(new_text: String):
	if not new_text:
		value = min
		text = str(value)
		caret_column = 1
		return
	
	if not new_text.is_valid_int():
		text = str(value)
		return 
	
	value = int(text)
	_clamp_value()
	var caret_column_cache = caret_column
	text = str(value)
	caret_column = caret_column_cache

func _clamp_value():
	value = clamp(value, min, max)
