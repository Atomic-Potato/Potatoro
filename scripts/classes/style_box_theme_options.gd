@tool
class_name StyleBoxThemeOptions extends Node

@export var box: StyleBox
@export_category("Flat style box")
@export var flat_bg_color: ColorType = ColorType.primary
@export var flat_border_color: ColorType = ColorType.primary
@export var flat_shadow_color: ColorType = ColorType.primary
@export_category("Line style box")
@export var line_color: ColorType = ColorType.primary
@export_category("Texture style box")
@export var texture_modulate_color: ColorType = ColorType.primary


enum ColorType
{
	primary, secondary, third, fourth, fifth, 
	sixth, seventh, eighth, nineth, tenth
}

func set_color_stuff(color: Color, type: ColorType):
	if box is StyleBoxFlat:
		print(color, type)
		if flat_bg_color == type:
			color.a = box.bg_color.a
			box.bg_color = color
		if flat_border_color == type:
			color.a = box.border_color.a
			box.border_color = color
		if flat_shadow_color == type:
			color.a = box.shadow_color.a
			box.shadow_color = color
	elif box is StyleBoxLine:
		if line_color == type:
			color.a = box.color.a
			box.color = color
	elif box is StyleBoxTexture:
		if texture_modulate_color == type:
			color.a = box.modulate_color.a
			box.modulate_color = color
