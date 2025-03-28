# NOTE: this class also includes the info table in the database
extends Node

var info_app_version: String:
	get: return _get_info(1)

var default_sessions_count: int:
	get: return int(_get_value(1))
	set(value): _set_value(1, value)

var default_session_length: int:
	get: return int(_get_value(2))
	set(value): _set_value(2, value)

var default_break_length: int:
	get: return int(_get_value(3))
	set(value): _set_value(3, value)

var is_use_12_hour_format: bool:
	get: return bool(int(_get_value(4)))
	set(value): _set_value(4, int(value))

var is_hide_session_timer_controls: bool:
	get: return bool(int(_get_value(5)))
	set(value): _set_value(5, int(value))

var is_hide_break_timer_controls: bool:
	get: return bool(int(_get_value(6)))
	set(value): _set_value(6, int(value))

var path_session_end_notification_timer: String:
	get: return _get_value(7)
	set(value): _set_value(7, value, true)

var path_break_end_notification_timer: String:
	get: return _get_value(8)
	set(value): _set_value(8, value, true)

var volume_session_end_notification: float:
	get: return float(_get_value(9))
	set(value): _set_value(9, value)

var volume_break_end_notification: float:
	get: return float(_get_value(10))
	set(value): _set_value(10, value)

var color_background: String:
	get: return _get_value(11)
	set(value): _set_value(11, value, true)

var color_primary: String:
	get: return _get_value(12)
	set(value): _set_value(12, value, true)

var color_danger: String:
	get: return _get_value(13)
	set(value): _set_value(13, value, true)

var is_use_custom_title_bar: bool:
	get: return bool(int(_get_value(14)))
	set(value): _set_value(14, int(value))

func _get_value(id: int):
	DatabaseManager.db.query("select Value from Settings where ID = " + str(id))
	return DatabaseManager.db.query_result[0].get("Value")

func _set_value(id: int, value, is_string: bool = false):
	var query: String = "update Settings set Value = '" + str(value) + "' where ID = " + str(id)\
		if is_string else "update Settings set Value = " + str(value) + " where ID = " + str(id)
	DatabaseManager.db.query(query)

func _get_info(id: int):
	DatabaseManager.db.query("select Value from Information where ID = " + str(id))
	return DatabaseManager.db.query_result[0].get("Value")
