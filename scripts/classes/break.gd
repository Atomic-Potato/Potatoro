class_name Break extends Node

var ID: int
var length: int
var end_datetime: String
var added_length: int

signal break_finish

func _init(_id: int = 0, _length: int = 0, _end_datetime: String = '', _added_length: int = 0):
	ID = _id
	length = _length
	end_datetime = _end_datetime
	added_length = _added_length
