@tool
extends Node

# NOTE: Which colors should be assigned to what
# DANGER_PRIMARY
#	font colors: 
#		(Button)
#			font_color, font_focus_color, font_hover_pressed_color, font_pressed_color
#		(Label)
#			font_color
#	styleboxes: any color in stylebox but preserving its alpha
# DANGER_SECONDARY:
#	font colors: (Button)
#		font_hover_color

@export_category("Main theme colors")
@export var color_primary: Color = Color.WHITE
@export var color_secondary: Color = Color.BLACK
@export var color_third: Color = Color.GRAY
@export var color_danger_primary: Color = Color.RED
@export var color_danger_secondary: Color = Color.BLACK

@export_category("Themes")
@export var theme_main: Theme
