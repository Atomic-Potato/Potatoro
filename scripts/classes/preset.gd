class_name Preset extends Node

var ID: int
var buffer_ID: int
var default_tag_id: int
var current_session_id: int
var current_break_id: int
var name_: String # im too lazy to find a better way to name this
var sessions_count: int:
	set(value):
		sessions_count = 0 if value < 0 else value
	get:
		return sessions_count
var sessions_done: int:
	set(value):
		sessions_done = 0 if value < 0 else value
	get:
		return sessions_done
var session_length: int:
	set(value):
		session_length = 0 if value < 0 else value
	get:
		return session_length
var added_session_length: int :
	set(value):
		added_session_length = 0 if value < 0 else value
	get:
		return added_session_length
var break_length: int:
	set(value):
		break_length = 0 if value < 0 else value
	get:
		return break_length
var is_auto_start_break: bool
var is_auto_start_session: bool

func _init(
_ID: int = 0, _buffer_ID: int = 0, _default_tag_id: int = 0, _name_: String = '',
_sessions_count: int = 0 , _sessions_done: int = 0, _session_length: int = 0,
_break_length: int = 0, _is_auto_start_break: bool = false, _is_auto_start_session: bool = false,
_added_session_length: int = 0,  _current_session_id: int = 0, _current_break_id: int = 0):
	
	ID = _ID
	buffer_ID = _buffer_ID
	default_tag_id = _default_tag_id
	name_ = _name_
	sessions_count = _sessions_count
	sessions_done = _sessions_done
	session_length = _session_length
	break_length = _break_length
	is_auto_start_break = _is_auto_start_break
	is_auto_start_session = _is_auto_start_session
	added_session_length = _added_session_length
	current_session_id = _current_session_id
	current_break_id = _current_break_id
