extends Control

var _selected_slots: Array[int] = []


func _ready() -> void:
	var s: Dictionary = GameManager.state
	if s["shop_items"].is_empty():
		GameManager.state = ShopSystem.reroll_shop(s, true)
	_render()


func _render() -> void:
	var s: Dictionary = GameManager.state
	$VBox/TopBar/RoundLabel.text = "Round %d" % s["round"]
	$VBox/TopBar/GoldLabel.text = "Gold: %dg" % s["gold"]
	$VBox/TopBar/HPLabel.text = "HP: %d/30" % s["player_hp"]
	$VBox/DebugRow/TierLabel.text = "Shop T%d" % s["shop_tier"]
	_rebuild_shop_list(s)
	_rebuild_inventory(s)
	_update_forge_ui(s)


func _rebuild_shop_list(s: Dictionary) -> void:
	var list: Node = $VBox/ShopList
	for child: Node in list.get_children():
		child.queue_free()
	for item: Variant in s["shop_items"]:
		var elem: Dictionary = item as Dictionary
		var row: HBoxContainer = HBoxContainer.new()
		var label: Label = Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s %-10s  %dg  %.1fs  %ddmg" % [
			elem["emoji"], elem["name"], elem["price"], elem["cooldown"], elem["damage"],
		]
		row.add_child(label)
		var btn: Button = Button.new()
		btn.text = "Buy"
		btn.disabled = (s["gold"] as int) < (elem["price"] as int)
		var id: String = elem["id"]
		btn.pressed.connect(_on_buy_pressed.bind(id))
		row.add_child(btn)
		list.add_child(row)


func _rebuild_inventory(s: Dictionary) -> void:
	var row: Node = $VBox/InventoryRow
	for child: Node in row.get_children():
		child.queue_free()
	var inv: Array = s["inventory"]
	for i: int in inv.size():
		var item: Variant = inv[i]
		var slot: InventorySlot = InventorySlot.new()
		slot.slot_index = i
		slot.custom_minimum_size = Vector2(110, 110)
		slot.add_theme_font_size_override("font_size", 22)
		if item != null:
			var elem: Dictionary = item as Dictionary
			slot.has_item = true
			slot.text = "%s\n%s\nLv%d" % [elem["emoji"], elem["name"], elem["level"]]
			if _selected_slots.has(i):
				slot.modulate = Color(0.4, 1.0, 0.4)
			slot.pressed.connect(_on_inventory_slot_pressed.bind(i))
			slot.slot_dropped.connect(_on_slot_drop)
		else:
			slot.has_item = false
			slot.text = "[ ]"
			slot.disabled = true
		row.add_child(slot)


func _update_forge_ui(s: Dictionary) -> void:
	var info_label: Label = $VBox/ForgeInfoLabel
	var level_btn: Button = $VBox/ForgeActionsRow/LevelUpButton
	var forge_btn: Button = $VBox/ForgeActionsRow/ForgeButton
	var sell_btn: Button = $VBox/ForgeActionsRow/SellButton
	var result_label: Label = $VBox/ForgeActionsRow/ForgeResultLabel

	level_btn.disabled = true
	forge_btn.disabled = true
	sell_btn.disabled = true
	result_label.text = ""

	match _selected_slots.size():
		0:
			info_label.text = "Select inventory slots to combine or sell"
		1:
			var slot: int = _selected_slots[0]
			var item: Variant = s["inventory"][slot]
			if item == null:
				_selected_slots.clear()
				info_label.text = "Select inventory slots to combine or sell"
				return
			var elem: Dictionary = item as Dictionary
			info_label.text = "%s Lv%d selected — pick a second slot or sell" % [elem["name"], elem["level"]]
			sell_btn.disabled = false
		2:
			var sa: int = _selected_slots[0]
			var sb: int = _selected_slots[1]
			var inv: Array = s["inventory"]
			var ea: Variant = inv[sa]
			var eb: Variant = inv[sb]
			if ea == null or eb == null:
				_selected_slots.clear()
				_update_forge_ui(s)
				return
			var da: Dictionary = ea as Dictionary
			var db: Dictionary = eb as Dictionary
			var preview: String = ForgeSystem.preview(s, sa, sb)
			result_label.text = preview
			if da["element_id"] == db["element_id"]:
				var levels_match: bool = (da["level"] as int) == (db["level"] as int)
				if levels_match:
					info_label.text = "Same element — level up?"
					level_btn.disabled = false
				else:
					info_label.text = "Levels must match to level up"
			else:
				var result_id: String = RecipeData.find_result(da["element_id"], db["element_id"])
				if result_id.is_empty():
					info_label.text = "No recipe for this combination"
				else:
					info_label.text = "Forge these two elements?"
					forge_btn.disabled = false


func _on_buy_pressed(element_id: String) -> void:
	GameManager.state = ShopSystem.buy_item(GameManager.state, element_id)
	_render()


func _on_inventory_slot_pressed(slot_index: int) -> void:
	if _selected_slots.has(slot_index):
		_selected_slots.erase(slot_index)
	elif _selected_slots.size() < 2:
		_selected_slots.append(slot_index)
	else:
		_selected_slots = [slot_index]
	_rebuild_inventory(GameManager.state)
	_update_forge_ui(GameManager.state)


func _on_level_up_pressed() -> void:
	if _selected_slots.size() < 2:
		return
	GameManager.state = ForgeSystem.level_up(GameManager.state, _selected_slots[0], _selected_slots[1])
	_selected_slots.clear()
	_render()


func _on_forge_pressed() -> void:
	if _selected_slots.size() < 2:
		return
	GameManager.state = ForgeSystem.forge(GameManager.state, _selected_slots[0], _selected_slots[1])
	_selected_slots.clear()
	_render()


func _on_sell_pressed() -> void:
	if _selected_slots.is_empty():
		return
	# Sell the first selected slot (single or first of two)
	var slot: int = _selected_slots[0]
	GameManager.state = ShopSystem.sell_item(GameManager.state, slot)
	_selected_slots.clear()
	_render()


func _on_slot_drop(from_slot: int, to_slot: int) -> void:
	var s: Dictionary = GameManager.state
	var inv: Array = s["inventory"]
	if inv[from_slot] == null or inv[to_slot] == null:
		return
	var da: Dictionary = inv[from_slot] as Dictionary
	var db: Dictionary = inv[to_slot] as Dictionary
	if da["element_id"] == db["element_id"] and (da["level"] as int) == (db["level"] as int):
		GameManager.state = ForgeSystem.level_up(s, from_slot, to_slot)
	else:
		var result_id: String = RecipeData.find_result(da["element_id"], db["element_id"])
		if not result_id.is_empty():
			GameManager.state = ForgeSystem.forge(s, from_slot, to_slot)
	_selected_slots.clear()
	_render()


func _on_add_gold_pressed() -> void:
	var s: Dictionary = GameManager.state.duplicate(true)
	s["gold"] = (s["gold"] as int) + 10
	GameManager.state = s
	_render()


func _on_tier_up_pressed() -> void:
	var s: Dictionary = GameManager.state.duplicate(true)
	var tier: int = s["shop_tier"] as int
	if tier < 5:
		s["shop_tier"] = tier + 1
	GameManager.state = s
	_render()


func _on_reroll_pressed() -> void:
	GameManager.state = ShopSystem.reroll_shop(GameManager.state)
	_render()


func _on_fight_pressed() -> void:
	GameManager.state["phase"] = "battle"
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")
