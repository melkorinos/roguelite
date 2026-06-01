extends Node


var state: Dictionary = {}


func _ready() -> void:
	state = GameState.create()
