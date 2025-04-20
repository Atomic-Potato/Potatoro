extends Node

@export var default_font_file: FontFile
@export var main_theme: Theme
@export var theme_types_to_apply_fonts: PackedStringArray

@export_category("Default window resolution")
## Window resolution for screens with 1080p resolution and higher
@export var default_FHD_window_resolution: Vector2i = Vector2i(800, 820)
## Window resolution for screens less than 1080p resolution
@export var default_HD_window_resolution:Vector2i = Vector2i(600, 600)
var default_window_resolution: Vector2i:
	get:
		var primary_screen_height: int = DisplayServer.screen_get_size().y
		if primary_screen_height >= 1080:
			return default_FHD_window_resolution
		else:
			return default_HD_window_resolution

@export_category("Default UI Scale")
## UI scale for screens with 1080p resolution and higher
@export var default_FHD_scale:float = 1
## Window resolution for screens less than 1080p resolution
@export var default_HD_scale: float = 0.78
var default_scale: float:
	get:
		var primary_screen_height: int = DisplayServer.screen_get_size().y
		if primary_screen_height >= 1080:
			return default_FHD_scale
		else:
			return default_HD_scale

var current_font_file: FontFile

func _ready():
	_setup_window_resolution()
	_setup_ui_scale()
	_update_main_theme_font()
	SettingsManager.path_font_file_changed.connect(_update_main_theme_font)

func _exit_tree():
	_save_window_size()

func _setup_window_resolution()-> void:
	get_window().size = SettingsManager.window_resolution
	await get_tree().process_frame
	_center_window_with_mouse()

func _setup_ui_scale():
	get_window().content_scale_factor = SettingsManager.ui_scale
	SettingsManager.ui_scale_changed.connect(
		func(): 
			get_window().content_scale_factor = SettingsManager.ui_scale
	)

func _save_window_size()-> void:
	var size: Vector2i = get_window().size
	SettingsManager.window_resolution = size
	ProjectSettings.set_setting('display/window/size/viewport_width', size.x)
	ProjectSettings.set_setting('display/window/size/viewport_height', size.y)

func _center_window_with_mouse()-> void:
	# getting mouse screen index
	var mouse_screen_index: int = -1
	var mouse_pos = DisplayServer.mouse_get_position()
	var screen_count = DisplayServer.get_screen_count()
	for screen_index in range(screen_count):
		var screen_pos = DisplayServer.screen_get_position(screen_index)
		var screen_size = DisplayServer.screen_get_size(screen_index)
		var screen_rect = Rect2(screen_pos, screen_size)
		if screen_rect.has_point(mouse_pos):
			mouse_screen_index = screen_index
			break
	
	# centering the window
	var screen_size: Vector2 = DisplayServer.screen_get_size(mouse_screen_index)
	var window_size: Vector2 = DisplayServer.window_get_size()
	var centered_position: Vector2 = (screen_size - window_size) / 2.0
	var screen_position: Vector2 = DisplayServer.screen_get_position(mouse_screen_index)
	DisplayServer.window_set_position(screen_position + centered_position)

func _update_main_theme_font():
	current_font_file = default_font_file
	if SettingsManager.path_font_file:
		current_font_file = load_font_from_file(SettingsManager.path_font_file)
	if not current_font_file:
		push_error("No default or custom font file found!")
		return
	for type: String in theme_types_to_apply_fonts:
		main_theme.set_font("font", type, current_font_file)

func load_font_from_file(user_path: String) -> FontFile:
	var font_file: FontFile = FontFile.new()
	var err = font_file.load_dynamic_font(user_path)
	if err != OK:
		push_error("Failed to load font from: " + user_path)
		return null
	return font_file
