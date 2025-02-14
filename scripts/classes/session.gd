class_name Session extends Node

@export var ID: int
@export var buffered_ID: int
@export var tag_ID: int
@export var start_date_time: String
@export var end_date_time: String

func _init(ID: int = 0, buffered_ID: int = 0, tag_ID: int = 0, start_date_time: String = '', end_date_time: String = ''):
	self.ID = ID
	self.buffered_ID = buffered_ID
	self.tag_ID = tag_ID
	self.start_date_time = start_date_time
	self.end_date_time = end_date_time
