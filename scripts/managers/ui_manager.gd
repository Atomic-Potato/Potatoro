extends Node

@export var default_font_file: FontFile
@export var main_theme: Theme
@export var theme_types_to_apply_fonts: PackedStringArray
var current_font_file: FontFile

func _ready():
	_setup_ui_scale()
	_update_main_theme_font()
	SettingsManager.path_font_file_changed.connect(_update_main_theme_font)

func _setup_ui_scale():
	get_window().content_scale_factor = SettingsManager.ui_scale
	SettingsManager.ui_scale_changed.connect(
		func(): 
			get_window().content_scale_factor = SettingsManager.ui_scale
	)

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
