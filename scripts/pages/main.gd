extends Control

@export var default_page_res: Resource
@export var page_container: Container

var current_page

func _ready():
	load_page(default_page_res)

func load_page(page_res: Resource):
	
