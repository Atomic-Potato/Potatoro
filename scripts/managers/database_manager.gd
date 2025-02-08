extends Node

var db : SQLite
var db_path: String = "user://potatoro.db"

func _ready():
	var is_db_exists: bool = FileAccess.file_exists(db_path)
	db = SQLite.new()
	db.path = db_path
	db.open_db()
	
	if not is_db_exists:
		create_db(db)

func get_presets() -> Array[Preset]:
	db.query("
		SELECT 
			p.ID,
			pb.ID AS BufferID,
			COALESCE(pb.DefaultTagID, p.DefaultTagID) AS DefaultTagID,
			COALESCE(pb.Name, p.Name) AS Name,
			COALESCE(pb.SessionsCount, p.SessionsCount) AS SessionsCount,
			pb.SessionsDone AS SessionsDone,
			COALESCE(pb.SessionLength, p.SessionLength) AS SessionLength,
			COALESCE(pb.BreakLength, p.BreakLength) AS BreakLength,
			COALESCE(pb.isAutoStartBreak, p.isAutoStartBreak) AS isAutoStartBreak,
			COALESCE(pb.isAutoStartSession, p.isAutoStartSession) AS isAutoStartSession
		FROM 
			Presets p
			LEFT JOIN Presets_Buffer pb ON p.ID = pb.PresetID
	")
	var presets: Array[Preset]
	for i in db.query_result:
		return []
	return []

func get_running_sessions() -> Array[Session]:
	db.query("select * from Sessions_Cache where EndDateTime is null")
	return []
	
func create_db(open_db: SQLite):
	open_db.query('
		CREATE TABLE "Configurations" (
			"ID"	INTEGER NOT NULL UNIQUE,
			"Key"	TEXT NOT NULL UNIQUE,
			"Value"	TEXT,
			PRIMARY KEY("ID" AUTOINCREMENT)
		);
		CREATE TABLE "Tags" (
			"ID"	INTEGER NOT NULL UNIQUE,
			"Name"	TEXT NOT NULL UNIQUE,
			"ColorCode"	TEXT,
			PRIMARY KEY("ID" AUTOINCREMENT)
		);
		CREATE TABLE "Sessions" (
			"ID"	INTEGER NOT NULL UNIQUE,
			"TagID"	INTEGER,
			"StartDateTime"	TEXT,
			"EndDateTime"	TEXT,
			FOREIGN KEY("TagID") REFERENCES "Tags"("ID"),
			PRIMARY KEY("ID" AUTOINCREMENT)
		);
		CREATE TABLE "Sessions_Buffer" (
			"ID"	INTEGER NOT NULL UNIQUE,
			"SessionID"	INTEGER NOT NULL UNIQUE,
			"TagID"	INTEGER,
			"StartDateTime"	TEXT NOT NULL,
			"EndDateTime"	TEXT,
			FOREIGN KEY("SessionID") REFERENCES "Sessions"("ID"),
			FOREIGN KEY("TagID") REFERENCES "Tags"("ID"),
			PRIMARY KEY("ID" AUTOINCREMENT)
		);
		CREATE TABLE "SessionPauses" (
			"ID"	INTEGER NOT NULL UNIQUE,
			"SessionID"	INTEGER NOT NULL,
			"StartDateTime"	TEXT,
			"EndDateTime"	TEXT,
			FOREIGN KEY("SessionID") REFERENCES "Sessions"("ID"),
			PRIMARY KEY("ID" AUTOINCREMENT)
		);
		CREATE TABLE "SessionPauses_Buffer" (
			"ID"	INTEGER NOT NULL UNIQUE,
			"SessionID"	INTEGER NOT NULL,
			"StartDateTime"	INTEGER NOT NULL,
			"EndDateTime"	INTEGER,
			FOREIGN KEY("SessionID") REFERENCES "Sessions"("ID"),
			PRIMARY KEY("ID" AUTOINCREMENT)
		);
		CREATE TABLE "Presets" (
			"ID"	INTEGER NOT NULL UNIQUE,
			"DefaultTagID"	INTEGER,
			"Name"	INTEGER NOT NULL UNIQUE,
			"SessionsCount"	INTEGER NOT NULL,
			"SessionsDone"	INTEGER,
			"SessionLength"	INTEGER,
			"BreakLength"	INTEGER,
			"isAutoStartBreak"	INTEGER NOT NULL DEFAULT 0,
			"isAutoStartSession"	INTEGER NOT NULL DEFAULT 0,
			FOREIGN KEY("CurrentSessionID") REFERENCES "Sessions"("ID"),
			PRIMARY KEY("ID" AUTOINCREMENT)
		);
		CREATE TABLE "Presets_Buffer" (
			"ID"	INTEGER NOT NULL UNIQUE,
			"PresetID"	INTEGER NOT NULL UNIQUE,
			"DefaultTagID"	INTEGER,
			"CurrentSessionID"	INTEGER,
			"Name"	TEXT NOT NULL,
			"SessionsCount"	INTEGER NOT NULL,
			"SessionsDone"	INTEGER NOT NULL,
			"SessionLength"	INTEGER NOT NULL,
			"BreakLength"	INTEGER NOT NULL,
			"isAutoStartBreak"	INTEGER NOT NULL,
			"isAutoStartSession"	INTEGER NOT NULL,
			FOREIGN KEY("PresetID") REFERENCES "Presets"("ID"),
			FOREIGN KEY("CurrentSessionID") REFERENCES "Sessions"("ID"),
			FOREIGN KEY("DefaultTagID") REFERENCES "Tags"("ID"),
			PRIMARY KEY("ID" AUTOINCREMENT)
		);
	')
	print ("Created database.")
