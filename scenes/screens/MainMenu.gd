extends Control


func _ready() -> void:
	$VBoxContainer/Title.add_theme_color_override("font_color", ThemeData.COLOR_TITLE)
	_apply_theme()


# Wraps the button stack in a beveled ScenePanel (arcane-violet menu accent) and themes
# each button to the same accent. The .tscn keeps a flat list under VBoxContainer; here
# we reparent the buttons into the panel body so their signal connections survive.
func _apply_theme() -> void:
	var accent: Color = ThemeData.AREA_MENU
	var vb: VBoxContainer = $VBoxContainer
	# Center the block on the content (the .tscn used a tiny fixed offset box).
	vb.offset_left = 0.0
	vb.offset_top = 0.0
	vb.offset_right = 0.0
	vb.offset_bottom = 0.0
	vb.add_theme_constant_override("separation", 18)

	var buttons: Array[Button] = [
		$VBoxContainer/StartButton, $VBoxContainer/HowToPlayButton,
		$VBoxContainer/SettingsButton, $VBoxContainer/CompendiumButton,
		$VBoxContainer/QuitButton,
	]

	var panel := ScenePanel.new()
	panel.setup("MAIN MENU", "🎮", accent)
	vb.add_child(panel)
	vb.move_child(panel, 1)  # directly below the title
	panel.body().add_theme_constant_override("separation", 10)

	for btn: Button in buttons:
		btn.reparent(panel.body())
		btn.custom_minimum_size = Vector2(340, 0)
		UIStyle.accent_button(btn, accent)
	# Quit reads as a softer/cooler action than the play CTAs (use the node ref — it has
	# just been reparented out of its .tscn path).
	buttons[buttons.size() - 1].modulate = ThemeData.UI_MUTED_TEXT


func _on_start_pressed() -> void:
	AudioManager.play("click")
	GameManager.state = GameState.create()
	get_tree().change_scene_to_file("res://scenes/screens/Shop.tscn")


func _on_how_to_play_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/screens/HowToPlay.tscn")


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
