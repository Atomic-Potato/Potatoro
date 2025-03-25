class_name Page extends Node

@export var child_pages_parent_node: Node

var parent: Page
var current_page: Page

func initialize(data: Dictionary = {}):
	pass

func enter():
	pass

func update():
	pass

func exit():
	pass

func set_page(page: Page):
	if not page:
		push_error("Cannot set null page!") 
		
	if current_page:
		current_page.exit()
		current_page.visible = false
		
	current_page = page
	current_page.visible = true
	current_page.parent = self
	current_page.enter()

func hide_all_child_pages():
	for child in child_pages_parent_node.get_children():
		child.visible = false
