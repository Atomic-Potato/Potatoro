extends Node

@export_category("Notifications")
@export var default_session_notification: AudioStream
var custom_session_notification_path: String
@export var default_break_notification: AudioStream
var custom_break_notification_path: String

enum Notification
{
	SessionEnd, BreakEnd 
}

var notification_player: AudioStreamPlayer

func _ready():
	notification_player = AudioStreamPlayer.new()
	add_child(notification_player)
	
	custom_session_notification_path = SettingsManager.path_session_end_notification_timer
	custom_break_notification_path = SettingsManager.path_break_end_notification_timer

func play_notification(sound: Notification):
	stop_notification()
	var volume: float = 0
	match sound:
		Notification.SessionEnd:
			if custom_session_notification_path:
				pass
			if not notification_player.stream:
				notification_player.stream = default_session_notification
			volume = SettingsManager.volume_session_end_notification
		Notification.BreakEnd:
			if custom_break_notification_path:
				pass
			if not notification_player.stream:
				notification_player.stream = default_break_notification
			volume = SettingsManager.volume_break_end_notification
	
	if notification_player.stream:
		notification_player.volume_db = lerp(-80, 10, volume)
		notification_player.play()

func stop_notification():
	if not notification_player.stream:
		return
	notification_player.stop()
	notification_player.stream = null


func is_playing_notification()-> bool:
	return notification_player.stream != null
