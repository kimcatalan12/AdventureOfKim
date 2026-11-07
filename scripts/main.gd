extends Node

func _ready() -> void:
	Game.host = self
	Game.go("title")
