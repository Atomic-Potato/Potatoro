@tool
extends Node

# NOTE: Which colors should be assigned to which font
# PRIMARY
# DANGER_PRIMARY
#			font_color, font_focus_color, 
#			font_hover_pressed_color, font_pressed_color
# DANGER_SECONDARY:
#		font_hover_color

@export_category("Main")
@export var main_options_parent_node: Node

var color_primary_cache: Color = Color.WHITE
@export var color_primary: Color:
	get: return color_primary_cache
	set(value):
		color_primary_cache = value
		set_color(value, StyleBoxThemeOptions.ColorType.primary, main_options_parent_node)

var color_secondary_cache: Color = Color.BLACK
@export var color_secondary: Color:
	get: return color_secondary_cache
	set(value):
		color_secondary_cache = value
		set_color(value, StyleBoxThemeOptions.ColorType.secondary, main_options_parent_node)

var color_third_cache: Color = Color(144,144,144)
@export var color_third: Color:
	get: return color_third_cache
	set(value):
		color_third_cache = value
		set_color(value, StyleBoxThemeOptions.ColorType.third, main_options_parent_node)

@export_category("Danger")
@export var danger_options_parent_node: Node

var danger_primary_cache: Color = Color.RED
@export var color_danger_primary: Color:
	get: return danger_primary_cache
	set(value):
		danger_primary_cache = value
		set_color(value, StyleBoxThemeOptions.ColorType.primary, danger_options_parent_node)

var danger_secondary_cache: Color = Color.BLACK
@export var color_danger_secondary: Color:
	get: return danger_secondary_cache
	set(value):
		danger_secondary_cache = value
		set_color(value, StyleBoxThemeOptions.ColorType.secondary, danger_options_parent_node)

@export_category("Themes")
@export var theme_main: Theme

func set_color(color: Color, type: StyleBoxThemeOptions.ColorType, options_parent_node: Node):
	var options: Array[Node] = options_parent_node.get_children()
	for option in options:
		if option is StyleBoxThemeOptions:
			if option.has_method("set_color_stuff"):
				option.set_color_stuff(color, type)
