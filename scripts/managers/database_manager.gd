extends Node

var db : SQLite
var db_path: String

signal restored_defaults

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
		"select datetime('now', 'localtime') as 'datetime'" if not offset\
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

func restore_default_settings():
	DatabaseManager.db.query('
		delete from Settings; ' + _get_settings_insert_query())
	restored_defaults.emit()

func _get_settings_insert_query()-> String:
		return '
			insert into Settings(SettingsCategoryID, Value, ID, Key) values
			(1, "8", '+str(SettingsManager.DBSettings.SessionsCount)+', 
				"' + SettingsManager.get_DBSettings_name(SettingsManager.DBSettings.SessionsCount) + '"),
			(1, "50", '+str(SettingsManager.DBSettings.SessionLength)+', 
				"' + SettingsManager.get_DBSettings_name(SettingsManager.DBSettings.SessionLength) + '"),
			(1, "5", '+str(SettingsManager.DBSettings.BreakLength)+', 
				"' + SettingsManager.get_DBSettings_name(SettingsManager.DBSettings.BreakLength) + '"),
			
			(2, "0", '+str(SettingsManager.DBSettings.IsUse12HourFormat)+', 
				"' + SettingsManager.get_DBSettings_name(SettingsManager.DBSettings.IsUse12HourFormat) + '"),
			(2, "0", '+str(SettingsManager.DBSettings.HideSessionTimerTimeChangeButtons)+', 
				"' + SettingsManager.get_DBSettings_name(SettingsManager.DBSettings.HideSessionTimerTimeChangeButtons) + '"),
			(2, "0", '+str(SettingsManager.DBSettings.HideBreakTimerTimeChangeButtons)+', 
				"' + SettingsManager.get_DBSettings_name(SettingsManager.DBSettings.HideBreakTimerTimeChangeButtons) + '"),
			
			(3, "", '+str(SettingsManager.DBSettings.PathSessionEndNotification)+', 
				"' + SettingsManager.get_DBSettings_name(SettingsManager.DBSettings.PathSessionEndNotification) + '"),
			(3, "", '+str(SettingsManager.DBSettings.PathBreakEndNotification)+', 
				"' + SettingsManager.get_DBSettings_name(SettingsManager.DBSettings.PathBreakEndNotification) + '"),
			(3, "1.0", '+str(SettingsManager.DBSettings.VolumeSessionEndNotification)+', 
				"' + SettingsManager.get_DBSettings_name(SettingsManager.DBSettings.VolumeSessionEndNotification) + '"),
			(3, "1.0", '+str(SettingsManager.DBSettings.VolumeBreakEndNotification)+', 
				"' + SettingsManager.get_DBSettings_name(SettingsManager.DBSettings.VolumeBreakEndNotification) + '"),
			
			(4, "000000", '+str(SettingsManager.DBSettings.BackgroundPrimaryColor)+', 
				"' + SettingsManager.get_DBSettings_name(SettingsManager.DBSettings.BackgroundPrimaryColor) + '"),
			
			(4, "ffffff", '+str(SettingsManager.DBSettings.PrimaryColor)+', 
				"' + SettingsManager.get_DBSettings_name(SettingsManager.DBSettings.PrimaryColor) + '"),
			(4, "000000", '+str(SettingsManager.DBSettings.SecondaryColor)+', 
				"' + SettingsManager.get_DBSettings_name(SettingsManager.DBSettings.SecondaryColor) + '"),
			(4, "909090", '+str(SettingsManager.DBSettings.ThirdColor)+', 
				"' + SettingsManager.get_DBSettings_name(SettingsManager.DBSettings.ThirdColor) + '"),
			
			(4, "ff0000", '+str(SettingsManager.DBSettings.DangerPrimaryColor)+', 
				"' + SettingsManager.get_DBSettings_name(SettingsManager.DBSettings.DangerPrimaryColor) + '"),
			(4, "000000", '+str(SettingsManager.DBSettings.DangerSecondaryColor)+', 
				"' + SettingsManager.get_DBSettings_name(SettingsManager.DBSettings.DangerSecondaryColor) + '"),
			
			(4, "0", '+str(SettingsManager.DBSettings.IsUseCustomTitleBar)+', 
				"' + SettingsManager.get_DBSettings_name(SettingsManager.DBSettings.IsUseCustomTitleBar) + '"),
			(4, "ffffff", '+str(SettingsManager.DBSettings.TitleBarPrimaryColor)+', 
				"' + SettingsManager.get_DBSettings_name(SettingsManager.DBSettings.TitleBarPrimaryColor) + '"),
			(4, "000000", '+str(SettingsManager.DBSettings.TitleBarSecondaryColor)+', 
				"' + SettingsManager.get_DBSettings_name(SettingsManager.DBSettings.TitleBarSecondaryColor) + '");
		'


# INFO:
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
		(1, "AppVersion", "' + Global.APP_VERSION + '");
		
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
		
		'+ _get_settings_insert_query() +'
		
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
	print('
		CREATE TABLE "Information" (
			"ID"	INTEGER NOT NULL UNIQUE,
			"Key"	TEXT NOT NULL UNIQUE,
			"Value"	TEXT,
			PRIMARY KEY("ID")
		);
		
		insert into Information(ID, Key, Value) values
		(1, "AppVersion", "' + Global.APP_VERSION + '");
		
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
		
		'+ _get_settings_insert_query() +'
		
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
