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


# NOTE: If u add a new color type, remember to add it in font_color_type.gd as well
# ik it sucks balls but what do u want from me, isnt a 10 color palette 
# already enough for u?!
enum ColorType
{
	primary, secondary, third, fourth, fifth, 
	sixth, seventh, eighth, nineth, tenth
}

func set_color(color: Color, type: ColorType):
	if box is StyleBoxFlat:
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
	var err = ResourceSaver.save(box, box.resource_path)
	if err != OK:
		push_error("Failed to save stylebox resource: " + str(err))
