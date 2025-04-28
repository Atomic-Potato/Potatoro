## This script does not allow the user to run the app multiple times
## since they will share the same database

extends Node

var is_enabled: bool = true

const LOCK_FILE_PATH = "user://app.lock"
var is_main_instance: bool

func _ready():
	if not is_enabled:
		return
	
	if FileAccess.file_exists(LOCK_FILE_PATH):
		var lock_file = FileAccess.open(LOCK_FILE_PATH, FileAccess.READ)
		var last_date: String = lock_file.get_as_text()
		if last_date:
			var difference: int = DatabaseManager.get_datetimes_seconds_difference(
				DatabaseManager.get_datetime(), last_date)
			if difference < 2:
				print("Another instance is already running. Closing app!")
				get_tree().quit()
				return
	else:
		FileAccess.open(LOCK_FILE_PATH, FileAccess.WRITE)
	is_main_instance = true
	print("Application started successfully.")
	_write_to_lock()

func _write_to_lock():
	while true:
		var lock_file: FileAccess = FileAccess.open(LOCK_FILE_PATH, FileAccess.WRITE_READ)
		lock_file.store_string(DatabaseManager.get_datetime())
		lock_file.flush()
		lock_file.close()
		await get_tree().create_timer(1).timeout

func _exit_tree():
	if not is_enabled or not is_main_instance:
		return
	if FileAccess.file_exists(LOCK_FILE_PATH):
		DirAccess.remove_absolute(LOCK_FILE_PATH)
