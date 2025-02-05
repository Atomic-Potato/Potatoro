class_name PresetInfo extends Resource

@export var id: int
@export var name: String
@export var sessions_count: int
@export var sessions_done: int 
@export var session_length: int
@export var break_length: int
@export var current_session_id: int
@export var auto_start_break: bool
@export var auto_start_session: bool

func _init(
	id: int,
	name: String,
	sessions_count: int,
	session_length: int,
	break_length: int,
	current_session_id: int = 0,
	sessions_done: int = 0,
	auto_start_break: bool = false,
	auto_start_session: bool = false
):
	self.id = id
	self.name = name
	self.sessions_count = sessions_count
	self.session_length = session_length
	self.break_length = break_length
	self.current_session_id = current_session_id
	self.sessions_done = sessions_done
	self.auto_start_break = auto_start_break
	self.auto_start_session = auto_start_session
