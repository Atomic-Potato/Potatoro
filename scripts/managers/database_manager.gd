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
		CREATE TABLE "Information" (
			"ID"	INTEGER NOT NULL UNIQUE,
			"Key"	TEXT NOT NULL UNIQUE,
			"Value"	TEXT,
			PRIMARY KEY("ID")
		);
		
		insert into Information(ID, Key, Value) values
		(1, "AppVersion", "0.1");
		
		CREATE TABLE "SettingsCategories" (
			"ID"	INTEGER NOT NULL UNIQUE,
			"Name"	TEXT NOT NULL,
			PRIMARY KEY("ID")
		);
		
		insert into SettingsCategories(ID, Name) values
		(1, "Default Values"),
		(2, "Timer Settings"),
		(3, "Sound Settings"),
		(4, "Theme"),
		(5, "Other");
		
		CREATE TABLE "Settings" (
			"ID"	INTEGER NOT NULL UNIQUE,
			"SettingsCategoryID"	INTEGER NOT NULL,
			"Key"	TEXT NOT NULL UNIQUE,
			"Value"	TEXT,
			FOREIGN KEY("SettingsCategoryID") REFERENCES "SettingsCategories"("ID"),
			PRIMARY KEY("ID")
		);
		
		insert into Settings(ID, SettingsCategoryID, Key, Value) values
		(1, 1, "Sessions Count", "8"),
		(2, 1, "Session Length", "50"),
		(3, 1, "Break Length", "5"),
		
		(4, 2, "is Use 12 Hour Format", "0"),
		(5, 2, "Hide Session timer time change buttons", "0"),
		(6, 2, "Hide Break timer time change buttons", "0"),
		
		(7, 3, "Path: Session end notification", ""),
		(8, 3, "Path: Break end notification", ""),
		(9, 3, "Volume: Session end notification", "1.0"),
		(10, 3, "Volume: Break end notification", "1.0"),
		
		(11, 4, "Background Color", "#000000"),
		(12, 4, "Primary Color", "#ffffff"),
		(13, 4, "Danger Color", "#ff0000"),
		
		(14, 5, "is use custom title bar", "0");
		
		
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
		
		CREATE TABLE "TimerTypes" (
			"ID"	INTEGER NOT NULL UNIQUE,
			"Name"	TEXT NOT NULL UNIQUE,
			PRIMARY KEY("ID")
		);
		
		insert into TimerTypes(ID, Name) values
			(1, "Session"), 
			(2, "Break");
		
		CREATE TABLE "Presets" (
			"ID"	INTEGER NOT NULL UNIQUE,
			"DefaultTagID"	INTEGER,
			"Name"	TEXT NOT NULL UNIQUE,
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
			"NextTimerTypeID" INTEGER,
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
			FOREIGN KEY("NextTimerTypeID") REFERENCES "TimerTypes"("ID"),
			PRIMARY KEY("ID" AUTOINCREMENT)
		);
	')
