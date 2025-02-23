class_name Session extends Node

@export var ID: int
@export var buffered_ID: int
@export var tag_ID: int
@export var start_date_time: String
@export var end_date_time: String

signal session_finish

func _init(_ID: int = 0, _buffered_ID: int = 0, _tag_ID: int = 0, _start_date_time: String = '', _end_date_time: String = ''):
	self.ID = _ID
	self.buffered_ID = _buffered_ID
	self.tag_ID = _tag_ID
	self.start_date_time = _start_date_time
	self.end_date_time = _end_date_time
