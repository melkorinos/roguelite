extends Control


func _ready() -> void:
	$VBoxContainer/Title.add_theme_color_override("font_color", ThemeData.COLOR_TITLE)


func _on_start_pressed() -> void:
	AudioManager.play("click")
	GameManager.state = GameState.create()
	get_tree().change_scene_to_file("res://scenes/screens/Shop.tscn")


func _on_settings_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/screens/Settings.tscn")


func _on_compendium_pressed() -> void:
	AudioManager.play("click")
	GameManager.compendium_return_scene = "res://scenes/screens/MainMenu.tscn"
	get_tree().change_scene_to_file("res://scenes/screens/Compendium.tscn")


func _on_quit_pressed() -> void:
	AudioManager.play("click")
	get_tree().quit()
