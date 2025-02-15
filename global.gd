# Global
extends Node

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
