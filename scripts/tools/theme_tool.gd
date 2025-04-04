@tool
extends Node

@export_category("Background")

@export_category("Main")
@export var main_options_parent_node: Node

var color_primary_cache: Color = Color.WHITE
@export var color_primary: Color:
	get: return color_primary_cache
	set(value):
		color_primary_cache = value
		set_color(value, StyleBoxThemeOptions.ColorType.primary, main_options_parent_node, 
			theme_main, get_main_theme_general_types())

var color_secondary_cache: Color = Color.BLACK
@export var color_secondary: Color:
	get: return color_secondary_cache
	set(value):
		color_secondary_cache = value
		set_color(value, StyleBoxThemeOptions.ColorType.secondary, main_options_parent_node,
			theme_main, get_main_theme_general_types())
		
var color_third_cache: Color = Color(144,144,144)
@export var color_third: Color:
	get: return color_third_cache
	set(value):
		color_third_cache = value
		set_color(value, StyleBoxThemeOptions.ColorType.third, main_options_parent_node,
			theme_main, get_main_theme_general_types())

@export_category("Danger")
@export var danger_options_parent_node: Node

var danger_primary_cache: Color = Color.RED
@export var color_danger_primary: Color:
	get: return danger_primary_cache
	set(value):
		danger_primary_cache = value
		set_color(value, StyleBoxThemeOptions.ColorType.primary, danger_options_parent_node,
			theme_main, get_type_from_theme(theme_main_font_color_types, ["Danger"]))

var danger_secondary_cache: Color = Color.BLACK
@export var color_danger_secondary: Color:
	get: return danger_secondary_cache
	set(value):
		danger_secondary_cache = value
		set_color(value, StyleBoxThemeOptions.ColorType.secondary, danger_options_parent_node,
			theme_main, get_type_from_theme(theme_main_font_color_types, ["Danger"]))

@export_category("Themes")
@export var theme_main: Theme
@export var theme_main_font_color_types: Array[FontColorType]

@export_category("Textures")
@export var textures_colors: Dictionary = {
	"primary": [],
	"secondary": [],
	"third": [],
	"fourth": [],
	"fifth": [], 
	"sixth": [],
	"seventh": [],
	"eighth": [],
	"nineth": [],
	"tenth": []
}
@export var resource: Resource

func set_color(
	color: Color, type: StyleBoxThemeOptions.ColorType, options_parent_node: Node, 
	theme: Theme = null, font_color_types: Array[FontColorType] = []):
	
	if not Engine.is_editor_hint():
		await ready
	
	if not options_parent_node:
		return
	
	## Setting styleboxes
	var options: Array[Node] = options_parent_node.get_children()
	for option: StyleBoxThemeOptions in options:
		option.set_color(color, type)
	
	## Setting fonts
	color.a = 1
	for font_color_type: FontColorType in font_color_types:
		for color_type in font_color_type.color_types.keys():
			if color_type == StyleBoxThemeOptions.ColorType.keys()[type]:
				for font_name in font_color_type.color_types[color_type]:
					theme.set_color(font_name, font_color_type.theme_type, color)
	var err = ResourceSaver.save(theme, theme.resource_path)
	if err != OK:
		push_error("Failed to save theme resource: " + str(err))
	
	## Setting textures
	color.a = 1
	for texture_res: Resource in textures_colors[StyleBoxThemeOptions.ColorType.keys()[type]]:
		var texture_instance: TextureRect = texture_res.instantiate()
		texture_instance.modulate = color
		var new_res = PackedScene.new()
		new_res.pack(texture_instance)
		texture_instance.queue_free()
		err = ResourceSaver.save(new_res, texture_res.resource_path)
	if err != OK:
		push_error("Failed to save texture resource: " + str(err))

# DANGER: Remember to add keywords to exclude if needed
func get_main_theme_general_types()-> Array[FontColorType]:
	if theme_main_font_color_types.is_empty():
		push_warning("theme_main_font_color_types array is empty")
		return []
	
	var keywords_to_exclude: Array[String] = ["Danger"]
	var filtered_types: Array[FontColorType] = theme_main_font_color_types.duplicate(true)
	## Removing keywords from filtered_types array
	for type: FontColorType in theme_main_font_color_types:
		for keyword in keywords_to_exclude:
			if type.theme_type.contains(keyword):
				## Finding the type index in the copied array 
				var type_index: int = 0
				for ft in filtered_types:
					if ft.theme_type == type.theme_type:
						break
					type_index += 1
				if type_index >= filtered_types.size():
					push_warning("Could not find type in filtered array")
				else:
					filtered_types.remove_at(type_index)
				break
	return filtered_types

func get_type_from_theme(theme_font_color_types: Array[FontColorType], included_keywords: Array[String])-> Array[FontColorType]:
	if theme_font_color_types.is_empty():
		push_warning("Given font color types array is empty")
		return []
	
	var filtered_types: Array[FontColorType] = []
	for type: FontColorType in theme_font_color_types:
		for keyword in included_keywords:
			if type.theme_type.contains(keyword):
				filtered_types.append(type)
	return filtered_types
	
	
	
	
	
	
	
	
	
	
	
	
