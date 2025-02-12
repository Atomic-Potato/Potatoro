extends Node

var buffered_sessions: Array[Session]

func _ready():
	update_buffered_sessions()

func _process(delta):
	for session: Session in buffered_sessions:
		# TODO: Process each buffer
		pass

func get_session(session_id: int)-> Session:
	DatabaseManager.db.query("select * from Sessions where ID = " + str(session_id))
	if DatabaseManager.db.query_result.is_empty():
		push_error("Session ID " + str(session_id) + " not found.")
		return null
		
	var result = DatabaseManager.db.query_result[0]
	var session: Session = Session.new(
		result.get("ID", 0),
		0,
		result.get("TagID", 0),
		result.get("StartDateTime", ""),
		result.get("EndDateTime", "")
	)
	
	DatabaseManager.db.query("select * from Sessions_Buffer where SessionID = " + str(session_id))
	if not DatabaseManager.db.query_result.is_empty():
		session.buffered_ID = DatabaseManager.db.query_result[0].get("ID")
	
	return session

func get_buffered_session(session_id: int)-> Session:
	DatabaseManager.db.query("select * from Sessions_Buffer where SessionID = " + str(session_id))
	if DatabaseManager.db.query_result.is_empty():
		push_error("Session ID " + str(session_id) + " not found in buffer.")
		return null
		
	var result = DatabaseManager.db.query_result[0]
	var session: Session = Session.new(
		result.get("SessionID", 0),
		result.get("ID", 0),
		result.get("TagID", 0),
		result.get("StartDateTime", ""),
		result.get("EndDateTime", "")
	)
	return session

func is_session_buffered(session_id: int)-> bool:
	DatabaseManager.db.query("select * from Sessions where ID = " + str(session_id))
	if DatabaseManager.db.query_result.is_empty():
		push_error("Session ID " + str(session_id) + " not found.")
		return false
		
	DatabaseManager.db.query("select * from Sessions_Buffer where SessionID = " + str(session_id))
	return not DatabaseManager.db.query_result.is_empty()

func update_buffered_sessions():
	var query = "select * from Sessions_Buffer"
	DatabaseManager.db.query(query)
	for i in DatabaseManager.db.query_result:
		var session: Session = Session.new(
			i.get("SessionID", 0),
			i.get("ID", 0),
			i.get("TagID", 0),
			i.get("StartDateTime", ""),
			i.get("EndDateTime", ""),
		)
		buffered_sessions.append(session)

func start_buffered_session(tag_ID:int)-> Session:
	var session: Session
	session.tag_ID = tag_ID
	session.start_date_time = Time.get_datetime_string_from_system()
	session.ID = SessionsManager.save_session(session)
	session.buffered_ID = SessionsManager.save_buffered_session(session) 
	return session

		
func end_buffered_session(session: Session)-> Session:
	if not session:
		push_error("Cannot end null session!")
		return null
	DatabaseManager.db.query("select ID from Sessions_Buffer where ID = " + str(session.buffered_ID))
	if DatabaseManager.db.query_result.is_empty():
		push_error("Buffered Session ID " + str(session.buffered_ID) + " not found in buffer.")
		return null
	
	var query = "
		update Sessions s
		set "\
			+ "s.TagID = sb.TagID, "\
			+ "StartDateTime = sb.StartDateTime, "\
			+ "EndDateTime = " + Time.get_datetime_string_from_system() + " " +\
		"from Sessions_Buffer sb 
		where ID = " + str(session.ID)
	DatabaseManager.db.query(query)
	query = "
		delete from Sessions_Buffer
		where ID = " + str(session.buffered_ID)
	DatabaseManager.db.query(query)
	
	# TODO: handle pauses buffer
	
	update_buffered_sessions()
	return get_session(session.ID)

func save_session(session: Session):
	if session.ID: #Update
		DatabaseManager.db.query("select ID from Sessions where ID = " + str(session.ID))
		if DatabaseManager.db.query_result.is_empty():
			push_error("Session ID " + str(session.ID) + " not found.")
			return 0
			
		var query = "
			update Sessions_Buffer
			set "\
				+ "TagID = " + str(session.tag_ID)+ ", "\
				+ "StartDateTime = " + str(session.start_date_time) + ", "\
				+ "EndDateTime = " + str(session.end_date_time) + " " +\
			"where ID = " + str(session.ID)
		
		DatabaseManager.db.query(query)
		return session.ID
	else: #Insert
		var query = "
			insert into Sessions(TagID, StartDateTime, EndDateTime)
			values("\
				+ str(session.tag_ID)+ ", "\
				+ str(session.start_date_time) + ", "\
				+ str(session.end_date_time) +\
			")
		"
		#print(query)
		DatabaseManager.db.query(query)
		return DatabaseManager.db.last_insert_rowid
	
func save_buffered_session(session: Session)-> int:
	var buffered_ID: int
	if session.buffered_ID: #Update
		DatabaseManager.db.query("select ID from Sessions_Buffer where ID = " + str(session.buffered_ID))
		if DatabaseManager.db.query_result.is_empty():
			push_error("Buffered session ID " + str(session.buffered_ID) + " not found in buffer.")
			return 0
			
		var query = "
			update Sessions_Buffer
			set "\
				+ "TagID = " + str(session.tag_ID)+ ", "\
				+ "StartDateTime = " + str(session.start_date_time) + ", "\
				+ "EndDateTime = " + str(session.end_date_time) + " " +\
			"where ID = " + str(session.buffered_ID)
		DatabaseManager.db.query(query)
		buffered_ID = session.buffered_ID
	else: #Insert
		var query = "
			insert into Sessions_Buffered(SessionID, TagID, StartDateTime, EndDateTime)
			values("\
				+ str(session.ID) + ", "\
				+ str(session.tag_ID)+ ", "\
				+ str(session.start_date_time) + ", "\
				+ str(session.end_date_time) +\
			")
		"
		#print(query)
		DatabaseManager.db.query(query)
		buffered_ID = DatabaseManager.db.last_insert_rowid
	
	update_buffered_sessions()
	return buffered_ID
