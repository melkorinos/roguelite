extends Control


func _ready() -> void:
	var s = GameManager.state
	if s["shop_items"].is_empty():
		GameManager.state = ShopSystem.reroll_shop(s, true)
	_render()


func _render() -> void:
	var s = GameManager.state

	$VBox/TopBar/RoundLabel.text = "Round %d" % s["round"]
	$VBox/TopBar/GoldLabel.text = "Gold: %dg" % s["gold"]
	$VBox/TopBar/HPLabel.text = "HP: %d/30" % s["player_hp"]

	_rebuild_shop_list(s)
	_rebuild_inventory(s)


func _rebuild_shop_list(s: Dictionary) -> void:
	var list = $VBox/ShopList
	for child in list.get_children():
		child.queue_free()

	for item in s["shop_items"]:
		var row = HBoxContainer.new()

		var label = Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%-16s  %dg  %s" % [
			item["name"],
			item["price"],
			_stat_text(item),
		]
		row.add_child(label)

		var btn = Button.new()
		btn.text = "Buy"
		var id = item["id"]
		btn.pressed.connect(_on_buy_pressed.bind(id))
		row.add_child(btn)

		list.add_child(row)


func _rebuild_inventory(s: Dictionary) -> void:
	var row = $VBox/InventoryRow
	for child in row.get_children():
		child.queue_free()

	for i in s["inventory"].size():
		var item = s["inventory"][i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(180, 60)
		if item != null:
			btn.text = item["name"]
			btn.pressed.connect(_on_sell_pressed.bind(i))
		else:
			btn.text = "[empty]"
			btn.disabled = true
		row.add_child(btn)


func _stat_text(item: Dictionary) -> String:
	var parts := []
	if item["attack"] != 0:
		parts.append("%+datk" % item["attack"])
	if item["defence"] != 0:
		parts.append("%+ddef" % item["defence"])
	return "  ".join(parts)


func _on_buy_pressed(item_id: String) -> void:
	GameManager.state = ShopSystem.buy_item(GameManager.state, item_id)
	_render()


func _on_sell_pressed(slot_index: int) -> void:
	GameManager.state = ShopSystem.sell_item(GameManager.state, slot_index)
	_render()


func _on_reroll_pressed() -> void:
	GameManager.state = ShopSystem.reroll_shop(GameManager.state)
	_render()


func _on_fight_pressed() -> void:
	GameManager.state["phase"] = "battle"
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")
