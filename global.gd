# Global
extends Node

const APP_VERSION = '0.1.1'
const CURRENT_ENV = Env.Production
const MAX_FPS: int = 60



var AppMan: ApplicationManager
var SceneCont: PackedScenesContainer

enum Env
{
	Development,
	Production
}

func _ready():
	# NOTE: it does not really matter since Low Processor Mode is enabled in the project settings
	#Engine.max_fps = MAX_FPS
	
	pass
