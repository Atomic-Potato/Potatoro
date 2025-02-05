extends Node

var db : SQLite
var db_path: String = "user://potatoro.db"

func _ready():
	db = SQLite.new()
	db.path = db_path
	db.open_db()
