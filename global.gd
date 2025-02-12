# Global
extends Node

const CURRENT_ENV = Env.Development

var AppMan: ApplicationManager
var SceneCont: PackedScenesContainer

enum Env
{
	Development,
	Production
}
