extends Page

#func _continue_to_session():
	#BreaksManager.end_break_id(break_.ID)
	#break_ = null
	#update_preset.call()
	#if preset.is_auto_start_session:
		#_start_session()
	#else:
		#_set_content(content_session_setup)
		#_initialize_content_session_setup()
	#
