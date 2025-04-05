extends Node

@export_category("Notifications")
@export var default_session_notification: AudioStream
var custom_session_notification: AudioStream
@export var default_break_notification: AudioStream
var custom_break_notification: AudioStream

enum Notification
{
	SessionEnd, BreakEnd 
}

var notification_player: AudioStreamPlayer

func _ready():
	notification_player = AudioStreamPlayer.new()
	add_child(notification_player)
	
func play_notification(sound: Notification):
	stop_notification()
	var volume: float = 0
	match sound:
		Notification.SessionEnd:
			if SettingsManager.path_session_end_notification_timer:
				custom_session_notification = get_audio_stream(SettingsManager.path_session_end_notification_timer)
				notification_player.stream = custom_session_notification
			if not notification_player.stream:
				notification_player.stream = default_session_notification
			volume = SettingsManager.volume_session_end_notification
		
		Notification.BreakEnd:
			if SettingsManager.path_session_end_notification_timer:
				custom_break_notification = get_audio_stream(SettingsManager.path_break_end_notification_timer)
				notification_player.stream = custom_break_notification
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

func get_audio_stream(user_path: String)-> AudioStream:
	user_path = "user://" + user_path
	var file: FileAccess = FileAccess.open(user_path, FileAccess.READ)
	if not file:
		return null
	var buffer: PackedByteArray = file.get_buffer(file.get_length())
	
	var extension: String = user_path.get_extension().to_lower()
	var stream: AudioStream
	match extension:
		'mp3': 
			stream = AudioStreamMP3.new()
			stream.loop = true
		'ogg': 
			stream = AudioStreamOggVorbis.new()
			stream.loop = true
		'wav': 
			stream = AudioStreamWAV.new()
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	if not stream:
		return null
	
	stream.data = buffer
	file.close()
	
	return stream
