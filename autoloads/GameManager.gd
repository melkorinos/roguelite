extends Node


var state: Dictionary = {}
var undo_state: Variant = null

# The scene the Compendium returns to on Back. Set by whoever opens it (MainMenu or
# Shop) so the Compendium works as an in-run recipe reference, not just a menu screen.
var compendium_return_scene: String = "res://scenes/screens/MainMenu.tscn"


func _ready() -> void:
	state = GameState.create(PlayerProfile.get_discovered_recipes())


func save_undo() -> void:
	undo_state = state.duplicate(true)


func apply_undo() -> bool:
	if undo_state == null:
		return false
	state = undo_state as Dictionary
	undo_state = null
	return true
