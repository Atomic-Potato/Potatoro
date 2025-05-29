class_name Break

var ID: int
var length: int
var end_datetime: String

signal break_finish

func _init(_id: int = 0, _length: int = 0, _end_datetime: String = ''):
	ID = _id
	length = _length
	end_datetime = _end_datetime
