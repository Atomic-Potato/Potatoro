extends Node

var buffered_breaks: Array[Break]

func _ready():
	update_buffered_breaks()

func _process(_delta):
	for break_: Break in buffered_breaks:
		print("processing break")
		if not is_break_id_buffered(break_.ID) or is_break_id_paused(break_.ID):
			continue
		var remaining_time: int = get_break_id_remaining_seconds(break_.ID)
		if remaining_time <= 0:
			end_break_id(break_.ID)

func update_buffered_breaks():
	var new_buffered_breaks: Array[Break] = []
	DatabaseManager.db.query("select * from Breaks_Buffer")
	for i in DatabaseManager.db.query_result:
		new_buffered_breaks.append(get_break(DatabaseManager.db.query_result[0].get("ID")))
	
	var removed_breaks: Array[Break] = []
	for bb in buffered_breaks:
		if new_buffered_breaks.find(bb) == -1 :
			removed_breaks.append(bb)
	for rb in removed_breaks:
		buffered_breaks.remove_at(buffered_breaks.find(rb))
	
	for nbb in new_buffered_breaks:
		var is_updated: bool
		for bb in buffered_breaks:
			if bb.ID == nbb.ID:
				bb.length = nbb.length
				bb.end_datetime = nbb.end_datetime
				bb.added_length = bb.added_length
				is_updated = true
		if not is_updated:
			buffered_breaks.append(nbb)

func get_break(break_id: int)-> Break:
	DatabaseManager.db.query("select * from Breaks_Buffer where ID = " + str(break_id))
	if DatabaseManager.db.query_result.is_empty():
		return null
	return Break.new(
		DatabaseManager.db.query_result[0].get("ID"),
		DatabaseManager.db.query_result[0].get("Length"),
		str(DatabaseManager.db.query_result[0].get("EndDateTime")),
		DatabaseManager.db.query_result[0].get("AddedLength")
	)

func get_loaded_break(break_id: int)-> Break:
	for bb in buffered_breaks:
		if bb.ID == break_id:
			return bb
	
	push_error("Could not find loaded break with ID ", break_id)
	return null

func save_break(new_break: Break)-> Break:
	if not new_break:
		push_error("Cannot save null break!")
		return null
	
	DatabaseManager.db.query("select ID from Breaks_Buffer where ID = " + str(new_break.ID))
	var is_exisits: bool = not DatabaseManager.db.query_result.is_empty()
	if is_exisits:
		DatabaseManager.db.query("
			update Breaks_Buffer set
				Length = " + str(new_break.length) + ",
				EndDateTime = '" + new_break.end_datetime + "',
				AddedLength = " + str(new_break.added_length) + "
			where ID = " + str(new_break.ID)
		)
		update_buffered_breaks()
		return new_break
	else: 
		DatabaseManager.db.query("
			insert into Breaks_Buffer(Length, EndDateTime, AddedLength)
			values(" 
				+ str(new_break.length) + ", 
				'" + new_break.end_datetime + "', 
				" +  str(new_break.added_length) + 
			")"
		)
		update_buffered_breaks()
		return get_loaded_break(DatabaseManager.db.last_insert_rowid)

func is_break_id_buffered(break_id: int, is_push_error: bool = true)-> bool:
	DatabaseManager.db.query("select ID from Breaks_Buffer where ID = " + str(break_id))
	if DatabaseManager.db.query_result.is_empty():
		if is_push_error:
			push_error("Break ID " + str(break_id) + " is not buffered!")
		return false
	return true

func is_break_id_paused(break_id: int)-> bool:
	if not is_break_id_buffered(break_id):
		return false
	
	# NOTE: if the break end datetime contains an int, then it is paused and the remaining time
	# in seconds is stored in its place
	DatabaseManager.db.query("select EndDateTime from Breaks_Buffer where ID = " + str(break_id))
	return str(DatabaseManager.db.query_result[0].get("EndDateTime")).is_valid_int()

func start_break(preset_id: int, break_length_minutes: int = -1, next_session_length: int = -1)-> Break:
	if not PresetsManager.is_preset_id_buffered(preset_id):
		return null
	if PresetsManager.is_in_break(preset_id):
		push_error("Preset is already in break!")
		return null
	
	if break_length_minutes < 0:
		DatabaseManager.db.query(
			"select BreakLength from Presets where ID = " + str(preset_id))
		break_length_minutes = DatabaseManager.db.query_result[0].get("BreakLength")
	if next_session_length < 0:
		DatabaseManager.db.query(
			"select SessionLength from Presets where ID = " + str(preset_id))
		next_session_length = DatabaseManager.db.query_result[0].get("SessionLength")
	
	var new_break = save_break(
		Break.new(
			0, 
			break_length_minutes,
			DatabaseManager.get_datetime('+' + str(break_length_minutes) + ' minutes')
		)
	)
	
	DatabaseManager.db.query("
		update Presets_Buffer
		set 
			CurrentBreakID = " + str(new_break.ID) + ", 
			SessionLength = " + str(next_session_length) + "
		where PresetID = " + str(preset_id)
	)
	
	update_buffered_breaks()
	return get_loaded_break(new_break.ID)

func end_break_id(break_id: int):
	if not is_break_id_buffered(break_id):
		return
	
	DatabaseManager.db.query("
		update Presets_Buffer
		set
			CurrentBreakID = 0
		from Presets p
		where CurrentBreakID = " + str(break_id)
	)
	DatabaseManager.db.query("
		delete from Breaks_Buffer
		where ID = " + str(break_id)
	)
	get_loaded_break(break_id).break_finish.emit()
	update_buffered_breaks()

func restart_break_id(break_id: int)-> Break:
	if not is_break_id_buffered(break_id):
		return get_loaded_break(break_id)
	
	DatabaseManager.db.query("select Length from Breaks_Buffer where ID = " + str(break_id))
	var break_length: int = DatabaseManager.db.query_result[0].get("Length")
	DatabaseManager.db.query("
		update Breaks_Buffer
		set 
			EndDateTime = '" + DatabaseManager.get_datetime('+' + str(break_length) + ' minutes') + "'
		where ID = " + str(break_id)
	)
	update_buffered_breaks()
	return get_loaded_break(break_id)

func pause_break_id(break_id: int)-> Break:
	if not is_break_id_buffered(break_id):
		return null
	if is_break_id_paused(break_id):
		push_error("Cannot pause break ID ", break_id, ", since it is already paused!")
		return get_loaded_break(break_id)
	
	DatabaseManager.db.query(
		"select EndDateTime from Breaks_Buffer where ID = " + str(break_id)
	)
	var end_datetime = DatabaseManager.db.query_result[0].get("EndDateTime")
	var remaining_seconds: int = DatabaseManager.get_datetimes_seconds_difference(
		end_datetime, DatabaseManager.get_datetime()
	) 
	if remaining_seconds < 0: 
		remaining_seconds = 0
		push_warning("Paused break has a negative remaining time, setting remaining time to 0 instead.")
	
	DatabaseManager.db.query("
		update Breaks_Buffer
		set EndDateTime = '" + str(remaining_seconds) + "'
		where ID = " + str(break_id)
	)
	update_buffered_breaks()
	return get_loaded_break(break_id)

func resume_break_id(break_id: int)-> Break:
	if not is_break_id_buffered(break_id):
		return null
	if not is_break_id_paused(break_id):
		push_error("Cannot resume break ID ", break_id, ", since it is already running!")
		return get_loaded_break(break_id)
	
	# Remaining seconds, when paused, is stored in BreakEndDateTime
	DatabaseManager.db.query(
		"select EndDateTime from Breaks_Buffer where ID = " + str(break_id)
	)
	var remaining_seconds: int = int(DatabaseManager.db.query_result[0].get("EndDateTime"))
	var new_end_datetime: String = DatabaseManager.get_datetime(
		'+' + str(remaining_seconds) + ' seconds')
	DatabaseManager.db.query(
		"update Breaks_Buffer
		set EndDateTime = '" + new_end_datetime + "'
		where ID = " + str(break_id)
	)
	update_buffered_breaks()
	return get_loaded_break(break_id)

func get_break_id_remaining_seconds(break_id: int)-> int:
	if not is_break_id_buffered(break_id):
		return 0
		
	DatabaseManager.db.query("select EndDateTime from Breaks_Buffer where ID = " + str(break_id))
	return DatabaseManager.get_datetimes_seconds_difference(
		DatabaseManager.db.query_result[0].get("EndDateTime"), 
		DatabaseManager.get_datetime()
	)
