class_name Preset extends Node

@export var ID: int
@export var buffer_ID: int
@export var default_tag_id: int
@export var name_: String # im too lazy to find a better way to name this
@export var sessions_count: int:
	set(value):
		sessions_count = 0 if value < 0 else value
	get:
		return sessions_count
@export var sessions_done: int:
	set(value):
		sessions_done = 0 if value < 0 else value
	get:
		return sessions_done
@export var session_length: int:
	set(value):
		session_length = 0 if value < 0 else value
	get:
		return session_length
@export var break_length: int:
	set(value):
		break_length = 0 if value < 0 else value
	get:
		return break_length
@export var is_auto_start_break: bool
@export var is_auto_start_session: bool

func _init(
	ID: int = 0, buffer_ID: int = 0, default_tag_id: int = 0, name_: String = '',
	sessions_count: int = 0 , sessions_done: int = 0, session_length: int = 0,
	break_length: int = 0, is_auto_start_break: bool = false, is_auto_start_session: bool = false):
	
	self.ID = ID
	self.buffer_ID = buffer_ID
	self.default_tag_id = default_tag_id
	self.name_ = name_
	self.sessions_count = sessions_count
	self.sessions_done = sessions_done
	self.session_length = session_length
	self.break_length = break_length
	self.is_auto_start_break = is_auto_start_break
	self.is_auto_start_session = is_auto_start_session
