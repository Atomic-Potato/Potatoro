extends Node

# SUMMARY:
# The sole reason this class exists is to start breaks or sessions
# if the preset has auto start break/session and the user is not within the timer page

func end_session(loaded_session: Session, session_preset_ID: int):
	var preset: Preset = PresetsManager.get_preset(session_preset_ID)
	if preset.is_auto_start_break:
		BreaksManager.start_break(session_preset_ID)
	loaded_session.session_finish.emit()
	print("ended session")

func end_break(loaded_break: Break, break_preset_ID: int):
	var preset: Preset = PresetsManager.get_preset(break_preset_ID)
	if preset.is_auto_start_session:
		SessionsManager.start_buffered_session(preset)
	loaded_break.break_finish.emit()
	print("ended break")
