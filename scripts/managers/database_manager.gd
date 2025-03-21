extends Node

var db : SQLite
var db_path: String

func _ready():
	match(Global.CURRENT_ENV):
		Global.Env.Development:
			db_path = "user://potatoro_dev.db"
		Global.Env.Production:
			db_path = "user://potatoro.db"
		_:
			db_path = "user://potatoro_other.db"
	
	var is_db_exists: bool = FileAccess.file_exists(db_path)
	db = SQLite.new()
	db.path = db_path
	db.open_db()
	
	if not is_db_exists:
		create_db(db)
		
	if Global.CURRENT_ENV == Global.Env.Development:
		#db.verbosity_level = SQLite.VERBOSE
		empty_sessions_data()

# NOTE: offset should in the format +/-time seconds/minutes/hours e.g. +20 seconds
func get_datetime(offset: String = '', start_date: String = 'now')-> String:
	var query: String =\
		"select datetime() as 'datetime'" if not offset\
		else "select datetime('" + start_date + "', '" + offset + "') as 'datetime'"
	DatabaseManager.db.query(query)
	return DatabaseManager.db.query_result[0].get("datetime")

func get_datetimes_seconds_difference(reduced_date: String, reduced_from_date: String):
	db.query("
		select unixepoch('" + reduced_date +"') 
			- unixepoch('" + reduced_from_date + "') as ElapsedTime" 
	)
	return db.query_result[0].get("ElapsedTime")

func empty_sessions_data():
	var query = "
		DELETE FROM Presets_Buffer;
		DELETE FROM SessionPauses;
		DELETE FROM SessionPauses_Buffer;
		DELETE FROM Sessions_Buffer;
		DELETE FROM Sessions;
		DELETE FROM Breaks_Buffer;
		DELETE FROM sqlite_sequence 
		WHERE name in (
			'Sessions_Buffer',
			'Sessions',
			'SessionPauses',
			'SessionPauses_Buffer',
			'Breaks_Buffer',
			'Presets_Buffer'
		);
	"
	db.query(query)

# NOTE:
#	- I created buffers to save on memory and query times
#	- In the presets buffer,the break end datetime is filled with remaining seconds
#		when the break is paused, i did this because i didnt plan well and im lazy
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
			"SessionID" INTEGERE NOT NULL UNIQUE,
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
		CREATE TABLE "Breaks_Buffer" (
			"ID"	INTEGER NOT NULL UNIQUE,
			"Length"	INTEGER NOT NULL,
			"EndDateTime"	INTEGER NOT NULL,
			"AddedLength"	INTEGER,
			PRIMARY KEY("ID" AUTOINCREMENT)
		);
		CREATE TABLE "Presets" (
			"ID"	INTEGER NOT NULL UNIQUE,
			"DefaultTagID"	INTEGER,
			"Name"	INTEGER NOT NULL UNIQUE,
			"SessionsCount"	INTEGER NOT NULL,
			"SessionLength"	INTEGER,
			"BreakLength"	INTEGER,
			"isAutoStartBreak"	INTEGER NOT NULL DEFAULT 0,
			"isAutoStartSession"	INTEGER NOT NULL DEFAULT 0,
			PRIMARY KEY("ID" AUTOINCREMENT)
		);
		CREATE TABLE "Presets_Buffer" (
			"ID"	INTEGER NOT NULL UNIQUE,
			"PresetID"	INTEGER NOT NULL UNIQUE,
			"DefaultTagID"	INTEGER,
			"CurrentSessionID"	INTEGER,
			"CurrentBreakID" INTEGER,
			"Name"	TEXT NOT NULL,
			"SessionsCount"	INTEGER NOT NULL,
			"SessionsDone"	INTEGER NOT NULL,
			"SessionLength"	INTEGER NOT NULL,
			"AddedSessionLength" INTEGER NOT NULL,
			"BreakLength"	INTEGER NOT NULL,
			"isAutoStartBreak"	INTEGER NOT NULL,
			"isAutoStartSession"	INTEGER NOT NULL,
			FOREIGN KEY("PresetID") REFERENCES "Presets"("ID"),
			FOREIGN KEY("CurrentSessionID") REFERENCES "Sessions"("ID"),
			FOREIGN KEY("CurrentBreakID") REFERENCES "Breaks_Buffer"("ID"),
			FOREIGN KEY("DefaultTagID") REFERENCES "Tags"("ID"),
			PRIMARY KEY("ID" AUTOINCREMENT)
		);
	')
