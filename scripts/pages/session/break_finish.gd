extends Page

func _continue_to_session():
	if preset.is_auto_start_session:
		_start_session()
	else:
		_set_content(content_session_setup)
		_initialize_content_session_setup()
	
