# Global
extends Node

const APP_VERSION = '0.1.0'
const CURRENT_ENV = Env.Development
const MAX_FPS: int = 60

var AppMan: ApplicationManager
var SceneCont: PackedScenesContainer

enum Env
{
	Development,
	Production
}

func _ready():
	Engine.max_fps = MAX_FPS
