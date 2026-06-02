extends Control


func _on_start_pressed() -> void:
	GameManager.state = GameState.create()
	get_tree().change_scene_to_file("res://scenes/screens/Shop.tscn")


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/screens/Settings.tscn")


func _on_compendium_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/screens/Compendium.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
