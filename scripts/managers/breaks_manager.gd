extends Node

var buffered_breaks: Array[Break]

func _ready():
	update_buffered_breaks()

func _process(_delta):
	for break_: Break in buffered_breaks:
		if not is_break_id_buffered(break_.ID) or is_break_id_paused(break_.ID):
			continue
		var remaining_time: int = get_break_id_remaining_seconds(break_.ID)
		if remaining_time <= 0:
			end_break_id(break_.ID, true)
			AudioManager.play_notification(AudioManager.Notification.BreakEnd)

func update_buffered_breaks():
	var new_buffered_breaks: Array[Break] = []
	DatabaseManager.db.query("select ID from Breaks_Buffer")
	for i in DatabaseManager.db.query_result:
		new_buffered_breaks.append(get_break(i.get("ID")))
	
	var removed_breaks: Array[Break] = []
	for bb in buffered_breaks:
		var is_found: bool
		for nbb in new_buffered_breaks:
			if nbb.ID == bb.ID:
				is_found = true
				break
		if not is_found :
			removed_breaks.append(bb)
	for rb in removed_breaks:
		buffered_breaks.remove_at(buffered_breaks.find(rb))
	
	for nbb in new_buffered_breaks:
		var is_updated: bool
		for bb in buffered_breaks:
			if bb.ID == nbb.ID:
				bb.length = nbb.length
				bb.end_datetime = nbb.end_datetime
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
		str(DatabaseManager.db.query_result[0].get("EndDateTime"))
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
				EndDateTime = '" + new_break.end_datetime + "'
			where ID = " + str(new_break.ID)
		)
		update_buffered_breaks()
		return get_loaded_break(new_break.ID)
	else: 
		DatabaseManager.db.query("
			insert into Breaks_Buffer(Length, EndDateTime)
			values(" 
				+ str(new_break.length) + ", 
				'" + new_break.end_datetime + "'
			)"
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

func start_break(preset_id: int)-> Break:
	if not PresetsManager.is_preset_id_buffered(preset_id):
		return null
	if PresetsManager.is_in_break(preset_id):
		push_error("Preset is already in break!")
		return null
	
	DatabaseManager.db.query(
		"select BreakLength from Presets_Buffer where PresetID = " + str(preset_id))
	var break_length = DatabaseManager.db.query_result[0].get("BreakLength")
	
	var new_break = save_break(
		Break.new(
			0, 
			break_length,
			DatabaseManager.get_datetime('+' + str(break_length) + ' minutes')
		)
	)
	
	DatabaseManager.db.query("
		update Presets_Buffer
		set 
			CurrentBreakID = " + str(new_break.ID) + ",
			NextTimerTypeID = "+ str(PresetsManager.TimerTypes.Session) +" 
		where PresetID = " + str(preset_id)
	)
	update_buffered_breaks()
	return get_loaded_break(new_break.ID)

func end_break_id(break_id: int, is_notify_timers_tracker: bool = false):
	if not is_break_id_buffered(break_id):
		return
	
	DatabaseManager.db.query("select PresetID from Presets_Buffer where CurrentBreakID = " + str(break_id))
	@warning_ignore("shadowed_global_identifier")
	var preset: Preset = PresetsManager.get_preset(DatabaseManager.db.query_result[0].get("PresetID"), false)
	DatabaseManager.db.query("
		update Presets_Buffer
		set
			CurrentBreakID = 0,
			BreakLength = "+str(preset.break_length)+",
			isAutoStartBreak = "+str(preset.is_auto_start_break)+"
		where CurrentBreakID = " + str(break_id)
	)
	DatabaseManager.db.query("
		delete from Breaks_Buffer
		where ID = " + str(break_id)
	)
	var break_ = get_loaded_break(break_id)
	if is_notify_timers_tracker:
		TimersTrackingManager.end_break(break_, preset.ID)
	else:
		break_.break_finish.emit()
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
	if is_break_id_paused(break_id):
		return DatabaseManager.db.query_result[0].get("EndDateTime")
	else:
		var end: String = DatabaseManager.db.query_result[0].get("EndDateTime")
		var now: String = DatabaseManager.get_datetime()
		return DatabaseManager.get_datetimes_seconds_difference(end, now)

func add_seconds_to_break(seconds: int, break_id: int):
	if not is_break_id_buffered(break_id):
		return
	
	if is_break_id_paused(break_id):
		var remaining_seconds = get_break_id_remaining_seconds(break_id)
		var new_time = remaining_seconds + seconds
		if new_time < 0:
			push_warning("Added seconds to break ID ", break_id, " sums to negetive, aborting")
			return
			
		DatabaseManager.db.query("
			update Breaks_Buffer set
				EndDateTime = " + str(new_time) +"
			where ID = " + str(break_id)
		)
	else:
		DatabaseManager.db.query("select EndDateTime from Breaks_Buffer where ID = " + str(break_id))
		var new_datetime: String = DatabaseManager.get_datetime(
			('+' if seconds > 0 else '') + str(seconds) + ' seconds', 
			DatabaseManager.db.query_result[0].get("EndDateTime")
		)
			
		if DatabaseManager.get_datetimes_seconds_difference(new_datetime, DatabaseManager.get_datetime()) < 0:
			push_warning("Added seconds to break ID ", break_id, " sums to negetive, aborting")
			return
		
		DatabaseManager.db.query("
			update Breaks_Buffer set
				EndDateTime = '" + str(new_datetime) +"'
			where ID = " + str(break_id)
		)

func get_break_buffered_preset(break_id: int)-> Preset:
	DatabaseManager.db.query("
		select PresetID from Presets_Buffer where CurrentBreakID = " + str(break_id)
	)
	if DatabaseManager.db.query_result.is_empty():
		push_error("Could not find buffered preset with the CurrentBreakID " + str(break_id))
		return null
	return PresetsManager.get_preset(DatabaseManager.db.query_result[0].get("PresetID"))
