class_name BlinkCanvasItem extends CanvasItem

@export var _is_active: bool = true
## Time in seconds between each blink
@export_range(0,10) var blink_interval: float = 1
## Only applies it to attached node
@export var is_self_modulate: bool = false
@export_range(0,1) var alpha: float = 1
## The canvas_item to apply blinking to. If left null then it will be applied to the attached node.
@export var _canvas_item: CanvasItem

var used_canvas: CanvasItem

func _ready():
	used_canvas = _canvas_item if _canvas_item else self
	if _is_active:
		_blink_loop()

func _blink_loop():
	while _is_active:
		await get_tree().create_timer(blink_interval).timeout
		if not _is_active:
			return
		_set_alpha(0)
		await get_tree().create_timer(blink_interval).timeout
		_set_alpha(alpha)

func _set_alpha(a: float):
	if a < 0 or a > 1:
		push_error("Invalid alpha value ", a)
		return 
	
	if is_self_modulate:
		used_canvas.self_modulate.a = a
	else:
		used_canvas.modulate.a = a

func set_active():
	if _is_active:
		push_warning(used_canvas.name, " is already blinking!")
		return
	_is_active = true
	_set_alpha(alpha)
	_blink_loop()

func set_inactive():
	_is_active = false
	_set_alpha(alpha)
