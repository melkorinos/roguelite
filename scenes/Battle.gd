extends Control


func _ready() -> void:
	_render()


func _process(delta: float) -> void:
	if GameManager.state["phase"] == "result":
		return
	GameManager.state = BattleSystem.tick_battle(GameManager.state, delta)
	_render()


func _render() -> void:
	var s = GameManager.state

	$VBox/Header.text = "BATTLE — Round %d" % s["round"]
	$VBox/BattleRow/PlayerCol/PlayerHP.text = "YOUR HP: %d" % s["player_hp"]
	$VBox/BattleRow/OppCol/OppHP.text = "OPP HP: %d" % s["opponent_hp"]

	var remaining = max(0.0, 10.0 - s["battle_timer"])
	$VBox/TimerLabel.text = "⏱ %.1fs until SANDSTORM..." % remaining
	$VBox/TimerLabel.visible = not s["sandstorm_fired"]
	$VBox/SandstormLabel.visible = s["sandstorm_fired"]

	_rebuild_player_items(s)

	if s["phase"] == "result":
		var outcome = BattleSystem.compute_result(s)
		var text := ""
		match outcome:
			"player_wins":   text = "Result: YOU WIN"
			"opponent_wins": text = "Result: YOU LOSE"
			"draw":          text = "Result: DRAW"
		$VBox/ResultLabel.text = text
		$VBox/ResultLabel.visible = true
		$VBox/ButtonRow.visible = true


func _rebuild_player_items(s: Dictionary) -> void:
	var list = $VBox/BattleRow/PlayerCol/PlayerItemList
	for child in list.get_children():
		child.queue_free()
	for item in s["inventory"]:
		if item == null:
			continue
		var lbl = Label.new()
		var stats := []
		if item["attack"] != 0:
			stats.append("%+datk" % item["attack"])
		if item["defence"] != 0:
			stats.append("%+ddef" % item["defence"])
		lbl.text = "%s (%s)" % [item["name"], "  ".join(stats)] if stats.size() > 0 else item["name"]
		list.add_child(lbl)


func _on_next_round_pressed() -> void:
	var s = GameManager.state
	s["round"] += 1
	s["player_hp"] = 30
	s["opponent_hp"] = 20
	s["battle_timer"] = 0.0
	s["sandstorm_fired"] = false
	s["phase"] = "shop"
	GameManager.state = s
	get_tree().change_scene_to_file("res://scenes/Shop.tscn")


func _on_menu_pressed() -> void:
	GameManager.state = GameState.create()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
