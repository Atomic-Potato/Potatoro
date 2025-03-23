extends Page

func _continue():
	if parent.preset.is_auto_start_break:
		parent.set_page(parent.page_break_timer)
	else:
		parent.set_page(parent.page_break_setup)


func _restart():
	parent.session = SessionsManager.restart_session(parent.session_cache.ID, parent.preset.ID)
	parent.set_page(parent.page_session_timer)
