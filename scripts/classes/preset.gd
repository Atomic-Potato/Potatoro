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
	_ID: int = 0, _buffer_ID: int = 0, _default_tag_id: int = 0, _name_: String = '',
	_sessions_count: int = 0 , _sessions_done: int = 0, _session_length: int = 0,
	_break_length: int = 0, _is_auto_start_break: bool = false, _is_auto_start_session: bool = false):
	
	self.ID = _ID
	self.buffer_ID = _buffer_ID
	self.default_tag_id = _default_tag_id
	self.name_ = _name_
	self.sessions_count = _sessions_count
	self.sessions_done = _sessions_done
	self.session_length = _session_length
	self.break_length = _break_length
	self.is_auto_start_break = _is_auto_start_break
	self.is_auto_start_session = _is_auto_start_session
