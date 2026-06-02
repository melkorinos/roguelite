extends Node


var state: Dictionary = {}
var undo_state: Variant = null


func _ready() -> void:
	state = GameState.create()


func save_undo() -> void:
	undo_state = state.duplicate(true)


func apply_undo() -> bool:
	if undo_state == null:
		return false
	state = undo_state as Dictionary
	undo_state = null
	return true
