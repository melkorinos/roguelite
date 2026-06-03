extends Control

var _inv_slot_nodes: Array = []
var _battle_slot_nodes: Array = []
var _tooltip: TooltipCard
var _pause_overlay: PauseOverlay


func _ready() -> void:
	_tooltip = TooltipCard.new()
	add_child(_tooltip)

	_pause_overlay = PauseOverlay.new()
	add_child(_pause_overlay)
	_pause_overlay.resumed.connect(func() -> void: _pause_overlay.hide_overlay())
	_pause_overlay.settings_requested.connect(_on_pause_settings)
	_pause_overlay.forfeit_requested.connect(_on_pause_forfeit)
	_pause_overlay.quit_to_menu_requested.connect(_on_pause_menu)
	_pause_overlay.quit_to_desktop_requested.connect(func() -> void: get_tree().quit())

	_apply_theme()

	var s: Dictionary = GameManager.state
	var all_null: bool = (s["shop_items"] as Array).all(func(x: Variant) -> bool: return x == null)
	if all_null:
		GameManager.state = ShopSystem.reroll_shop(s, true)
	_render()


func _apply_theme() -> void:
	# Forge bench: purple panel background via Container's built-in "panel" stylebox
	var forge_style := StyleBoxFlat.new()
	forge_style.bg_color = ThemeData.FORGE_PANEL_BG
	forge_style.set_border_width_all(1)
	forge_style.border_color = ThemeData.FORGE_PANEL_BORDER
	forge_style.set_corner_radius_all(8)
	forge_style.content_margin_left = 10.0
	forge_style.content_margin_right = 10.0
	forge_style.content_margin_top = 8.0
	forge_style.content_margin_bottom = 8.0
	$VBox/MainArea/RightPanel.add_theme_stylebox_override("panel", forge_style)

	# FOR SALE section — warm amber tint (applied directly to SellZone panel)
	var forsale_style := StyleBoxFlat.new()
	forsale_style.bg_color = ThemeData.SHOP_FORSALE_BG
	forsale_style.set_border_width_all(1)
	forsale_style.border_color = ThemeData.SHOP_FORSALE_BORDER
	forsale_style.set_corner_radius_all(6)
	($VBox/MainArea/LeftPanel/SellZone as PanelContainer).add_theme_stylebox_override("panel", forsale_style)

	# INVENTORY section — cool blue tint on the row container
	var inv_style := StyleBoxFlat.new()
	inv_style.bg_color = ThemeData.SHOP_INVENTORY_BG
	inv_style.set_border_width_all(1)
	inv_style.border_color = ThemeData.SHOP_INVENTORY_BORDER
	inv_style.set_corner_radius_all(6)
	$VBox/MainArea/LeftPanel/InventoryRow.add_theme_stylebox_override("panel", inv_style)

	# BATTLE GRID section — warm amber-red tint on the grid container
	var grid_style := StyleBoxFlat.new()
	grid_style.bg_color = ThemeData.SHOP_BATTLEGRID_BG
	grid_style.set_border_width_all(1)
	grid_style.border_color = ThemeData.SHOP_BATTLEGRID_BORDER
	grid_style.set_corner_radius_all(6)
	$VBox/MainArea/LeftPanel/BattleGrid.add_theme_stylebox_override("panel", grid_style)

	# Header label colors
	($VBox/MainArea/LeftPanel/SellZone/SellZoneVBox/ShopHeaderRow/ShopHeader as Label).add_theme_color_override("font_color", ThemeData.COLOR_HEADER_SHOP)
	($VBox/MainArea/LeftPanel/InventoryHeader as Label).add_theme_color_override("font_color", ThemeData.COLOR_HEADER_INVENTORY)
	($VBox/MainArea/LeftPanel/BattleGridHeader as Label).add_theme_color_override("font_color", ThemeData.COLOR_HEADER_GRID)
	($VBox/MainArea/RightPanel/ForgeHeader as Label).add_theme_color_override("font_color", ThemeData.COLOR_HEADER_FORGE)
	($VBox/TopBar/RoundLabel as Label).add_theme_color_override("font_color", ThemeData.COLOR_ROUND_LABEL)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if not ke.pressed or ke.echo:
			return
		if ke.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			if _pause_overlay.is_open():
				_pause_overlay.hide_overlay()
			else:
				_tooltip.hide_card()
				_pause_overlay.show_overlay()
		elif ke.keycode == KEY_Z and ke.ctrl_pressed:
			get_viewport().set_input_as_handled()
			_do_undo()


# ── Pause overlay handlers ────────────────────────────────────────────────────

func _on_pause_settings() -> void:
	_pause_overlay.hide_overlay()
	get_tree().change_scene_to_file("res://scenes/screens/Settings.tscn")


func _on_pause_forfeit() -> void:
	_pause_overlay.hide_overlay()
	GameManager.state = PhaseSystem.forfeit(GameManager.state)
	get_tree().change_scene_to_file("res://scenes/screens/MainMenu.tscn")


func _on_pause_menu() -> void:
	_pause_overlay.hide_overlay()
	get_tree().change_scene_to_file("res://scenes/screens/MainMenu.tscn")


func _render() -> void:
	_tooltip.hide_card()
	var s: Dictionary = GameManager.state
	$VBox/TopBar/RoundLabel.text = "Round %d" % s["round"]
	$VBox/TopBar/GoldLabel.text = ""
	$VBox/TopBar/HPLabel.text = "❤ %d/30   💰 %dg" % [s["player_hp"], s["gold"]]
	$VBox/TopBar/LivesLabel.text = "Life: %d  Wins: %d/10" % [s["lives"], s["wins"]]
	$VBox/DebugRow/TierLabel.text = "Shop T%d" % s["shop_tier"]
	$VBox/TopBar/UndoButton.disabled = GameManager.undo_state == null
	_rebuild_shop_grid(s)
	_rebuild_inventory(s)
	_rebuild_battle_grid(s)
	_rebuild_forge_bench(s)


func _rebuild_shop_grid(s: Dictionary) -> void:
	var grid: Node = $VBox/MainArea/LeftPanel/SellZone/SellZoneVBox/ShopGrid
	for child: Node in grid.get_children():
		child.queue_free()
	var gold: int = s["gold"] as int
	var shop_items: Array = s["shop_items"] as Array
	for i: int in shop_items.size():
		var item: Variant = shop_items[i]
		if item == null:
			# SOLD placeholder
			var sold_tile := PanelContainer.new()
			sold_tile.custom_minimum_size = ShopItemTile.SIZE
			var style := StyleBoxFlat.new()
			style.bg_color = ThemeData.SOLD_TILE_BG
			style.set_border_width_all(1)
			style.border_color = ThemeData.SOLD_TILE_BORDER
			style.set_corner_radius_all(6)
			sold_tile.add_theme_stylebox_override("panel", style)
			var lbl := Label.new()
			lbl.text = "SOLD"
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			lbl.modulate = Color(0.4, 0.4, 0.45, 0.7)
			UIScale.apply(lbl, UIScale.SOLD_LABEL)
			sold_tile.add_child(lbl)
			grid.add_child(sold_tile)
		else:
			var elem: Dictionary = item as Dictionary
			var tile: ShopItemTile = ShopItemTile.new()
			grid.add_child(tile)
			tile.setup(elem, gold, i)
			tile.buy_pressed.connect(_on_buy_pressed)
			tile.tooltip_requested.connect(_on_tooltip_requested)
			tile.tooltip_hide_requested.connect(_on_tooltip_hide)


func _rebuild_inventory(s: Dictionary) -> void:
	_inv_slot_nodes.clear()
	var row: Node = $VBox/MainArea/LeftPanel/InventoryRow
	for child: Node in row.get_children():
		child.queue_free()
	var inv: Array = s["inventory"]
	for i: int in inv.size():
		var item: Variant = inv[i]
		var slot: InventorySlot = InventorySlot.new()
		slot.slot_index = i
		slot.custom_minimum_size = Vector2(110, 110)
		UIScale.apply(slot, UIScale.INV_SLOT)
		if item != null:
			var elem: Dictionary = item as Dictionary
			slot.has_item = true
			slot.element_id = elem["element_id"]
			slot.element_level = elem["level"] as int
			slot.element_price = elem["price"] as int
			slot.item_dict = elem.duplicate()
			var eff_dmg: int = ElementData.effective_damage(elem)
			slot.text = "%s\n%s\nLv%d  %ddmg" % [elem["emoji"], elem["name"], elem["level"], eff_dmg]
		else:
			slot.has_item = false
			slot.text = "[ ]"
			slot.disabled = false
		row.add_child(slot)
		# Connect signals after add_child so _ready() has run.
		slot.slot_dropped.connect(_on_inv_slot_received_drop)
		slot.shop_buy_upgrade_requested.connect(_on_shop_buy_upgrade_requested)
		slot.shop_buy_to_slot_requested.connect(_on_shop_buy_to_slot_requested)
		slot.drag_started.connect(_on_inv_drag_started)
		slot.drag_ended.connect(_on_inv_drag_ended)
		slot.forge_quick_slot.connect(_on_forge_quick_slot)
		slot.tooltip_requested.connect(_on_tooltip_requested)
		slot.tooltip_hide_requested.connect(_on_tooltip_hide)
		_inv_slot_nodes.append(slot)


func _rebuild_battle_grid(s: Dictionary) -> void:
	_battle_slot_nodes.clear()
	var container: Node = $VBox/MainArea/LeftPanel/BattleGrid
	for child: Node in container.get_children():
		child.queue_free()
	var grid: Array = s["battle_grid"]
	for i: int in 4:
		var slot: BattleSlot = BattleSlot.new()
		slot.slot_index = i
		slot.draggable = true
		slot.slot_dropped.connect(_on_grid_slot_received_drop)
		slot.drag_started.connect(_on_grid_drag_started)
		slot.drag_ended.connect(_on_inv_drag_ended)
		slot.forge_quick_slot_grid.connect(_on_forge_quick_slot_grid)
		slot.tooltip_requested.connect(_on_tooltip_requested)
		slot.tooltip_hide_requested.connect(_on_tooltip_hide)
		container.add_child(slot)
		slot.set_element(grid[i])
		_battle_slot_nodes.append(slot)


func _rebuild_forge_bench(s: Dictionary) -> void:
	var row: Node = $VBox/MainArea/RightPanel/ForgeSlotsRow
	for child: Node in row.get_children():
		child.queue_free()
	var forge_slots: Array = s["forge_slots"]
	for i: int in 2:
		var fslot: ForgeSlot = ForgeSlot.new()
		fslot.forge_slot_index = i
		row.add_child(fslot)
		fslot.set_item(forge_slots[i])
		fslot.item_placed.connect(_on_forge_slot_item_placed)
		fslot.tooltip_requested.connect(_on_tooltip_requested)
		fslot.tooltip_hide_requested.connect(_on_tooltip_hide)
		fslot.item_removed.connect(_on_forge_slot_item_removed)
	_update_forge_info(s)


func _update_forge_info(s: Dictionary) -> void:
	var info: Label = $VBox/MainArea/RightPanel/ForgeInfoLabel
	var result: Label = $VBox/MainArea/RightPanel/ForgeResultLabel
	var forge_btn: Button = $VBox/MainArea/RightPanel/ForgeButton
	var slots: Array = s["forge_slots"]
	var ea: Variant = slots[0]
	var eb: Variant = slots[1]
	result.text = ""
	if ea == null and eb == null:
		info.text = "Drop 2 items to forge"
		forge_btn.disabled = true
	elif ea != null and eb == null:
		var da: Dictionary = ea as Dictionary
		info.text = "%s %s in slot 1 — add second item" % [da["emoji"], da["name"]]
		forge_btn.disabled = true
	elif ea == null and eb != null:
		var db: Dictionary = eb as Dictionary
		info.text = "%s %s in slot 2 — add first item" % [db["emoji"], db["name"]]
		forge_btn.disabled = true
	else:
		info.text = ForgeSystem.preview_bench(s)
		forge_btn.disabled = false


# ── Item Tooltip ─────────────────────────────────────────────────────────────

func _on_tooltip_requested(element: Dictionary) -> void:
	_tooltip.show_for(element)


func _on_tooltip_hide() -> void:
	_tooltip.hide_card()


# ── Drag hint overlays ────────────────────────────────────────────────────────

func _on_inv_drag_started(element_id: String, _inv_slot: int, sell_price: int) -> void:
	var sell_zone: SellZone = $VBox/MainArea/LeftPanel/SellZone
	sell_zone.show_hint(sell_price)
	$VBox/MainArea/LeftPanel/SellHintLabel.visible = true
	for node: Variant in _inv_slot_nodes:
		var s: InventorySlot = node as InventorySlot
		if s.has_item and s.element_id == element_id:
			s.modulate = Color(0.4, 1.0, 0.5)


func _on_grid_drag_started(_element_id: String, _grid_slot: int, sell_price: int) -> void:
	var sell_zone: SellZone = $VBox/MainArea/LeftPanel/SellZone
	sell_zone.show_hint(sell_price)
	$VBox/MainArea/LeftPanel/SellHintLabel.visible = true


func _on_inv_drag_ended() -> void:
	var sell_zone: SellZone = $VBox/MainArea/LeftPanel/SellZone
	sell_zone.hide_hint()
	$VBox/MainArea/LeftPanel/SellHintLabel.visible = false
	for node: Variant in _inv_slot_nodes:
		(node as InventorySlot).modulate = Color.WHITE


# ── Sell zone ─────────────────────────────────────────────────────────────────

func _on_sell_zone_sold(from_type: String, from_index: int) -> void:
	AudioManager.play("sell")
	GameManager.save_undo()
	if from_type == "inventory":
		GameManager.state = ShopSystem.sell_item(GameManager.state, from_index)
	elif from_type == "grid":
		GameManager.state = ShopSystem.sell_grid_item(GameManager.state, from_index)
	_render()


# ── Buy ───────────────────────────────────────────────────────────────────────

func _on_buy_pressed(_element_id: String, shop_slot: int) -> void:
	AudioManager.play("buy")
	GameManager.save_undo()
	GameManager.state = ShopSystem.transfer(GameManager.state, {"zone": "shop", "slot": shop_slot}, {"zone": "inventory", "slot": -1})
	_render()


func _on_reroll_pressed() -> void:
	AudioManager.play("click")
	GameManager.save_undo()
	GameManager.state = ShopSystem.reroll_shop(GameManager.state)
	_render()


# ── Buy → empty inventory slot (no dialog) ───────────────────────────────────

func _on_shop_buy_to_slot_requested(_element_id: String, to_inv_index: int, shop_slot: int) -> void:
	AudioManager.play("buy")
	GameManager.save_undo()
	GameManager.state = ShopSystem.transfer(GameManager.state, {"zone": "shop", "slot": shop_slot}, {"zone": "inventory", "slot": to_inv_index})
	_render()


# ── Buy + level-up combo (no confirmation — undo covers it) ──────────────────

func _on_shop_buy_upgrade_requested(_element_id: String, to_inv_index: int, shop_slot: int) -> void:
	AudioManager.play("buy")
	GameManager.save_undo()
	GameManager.state = ShopSystem.transfer(
		GameManager.state,
		{"zone": "shop", "slot": shop_slot},
		{"zone": "inventory", "slot": to_inv_index}
	)
	_render()


# ── Forge bench ───────────────────────────────────────────────────────────────

func _on_forge_slot_item_placed(forge_slot_idx: int, from_inv_idx: int) -> void:
	GameManager.state = ForgeSystem.move_to_forge_slot(GameManager.state, forge_slot_idx, from_inv_idx)
	_render()


func _on_forge_quick_slot(inv_slot_index: int) -> void:
	GameManager.state = ForgeSystem.forge_quick_slot(GameManager.state, inv_slot_index)
	_render()


func _on_forge_slot_item_removed(forge_slot_idx: int) -> void:
	GameManager.state = ForgeSystem.remove_from_forge_slot(GameManager.state, forge_slot_idx)
	_render()


func _on_forge_button_pressed() -> void:
	_execute_forge()


func _execute_forge() -> void:
	GameManager.save_undo()
	var pre_recipe_count: int = (GameManager.state["discovered_recipes"] as Array).size()
	var result: Dictionary = ForgeSystem.forge_from_bench(GameManager.state)
	GameManager.state = result["state"] as Dictionary
	var outcome: String = result["outcome"] as String
	var level_mismatch: bool = result["level_mismatch"] as bool

	if outcome == "ok":
		AudioManager.play("forge")
		var post_count: int = (GameManager.state["discovered_recipes"] as Array).size()
		if post_count > pre_recipe_count:
			_fire_achievement("forge_discovered")

	_render()
	var result_lbl: Label = $VBox/MainArea/RightPanel/ForgeResultLabel
	match outcome:
		"ok":
			var msg: String = "Forged!"
			if level_mismatch:
				msg += "  ⚠ Level mismatch — result at lower level"
			result_lbl.text = msg
		"no_recipe":
			result_lbl.text = "✗ No recipe — items returned"
		"inv_full":
			result_lbl.text = "✗ Inventory full — clear a slot first"
		_:
			result_lbl.text = ""


func _fire_achievement(event: String) -> void:
	var ach: Dictionary = AchievementSystem.check(GameManager.state, PlayerProfile.to_dict(), event)
	PlayerProfile.from_dict(ach["profile"] as Dictionary)
	if not (ach["unlocked"] as Array).is_empty():
		PlayerProfile.save_profile()


# ── Inventory → inventory: level-up ──────────────────────────────────────────

func _on_inv_slot_received_drop(from_type: String, from_index: int, to_inv_index: int) -> void:
	if from_type == "inventory":
		GameManager.save_undo()
		GameManager.state = ForgeSystem.level_up(GameManager.state, from_index, to_inv_index)
	elif from_type == "grid":
		GameManager.state = ShopSystem.transfer(GameManager.state, {"zone": "grid", "slot": from_index}, {"zone": "inventory", "slot": to_inv_index})
	_render()


# ── Battle grid drag-and-drop ─────────────────────────────────────────────────

func _on_grid_slot_received_drop(from_type: String, from_index: int, to_grid_index: int) -> void:
	if from_type == "shop":
		GameManager.save_undo()
		GameManager.state = ShopSystem.transfer(GameManager.state, {"zone": "shop", "slot": from_index}, {"zone": "grid", "slot": to_grid_index})
	elif from_type == "inventory":
		GameManager.state = ShopSystem.transfer(GameManager.state, {"zone": "inventory", "slot": from_index}, {"zone": "grid", "slot": to_grid_index})
	elif from_type == "grid":
		var grid: Array = GameManager.state["battle_grid"] as Array
		var fa: Variant = grid[from_index]
		var tb: Variant = grid[to_grid_index]
		if fa != null and tb != null:
			var da: Dictionary = fa as Dictionary
			var db: Dictionary = tb as Dictionary
			var same_elem: bool = da.get("element_id", "") == db.get("element_id", "")
			var same_level: bool = (da["level"] as int) == (db["level"] as int)
			if same_elem and same_level:
				GameManager.save_undo()
				GameManager.state = ForgeSystem.level_up_grid(GameManager.state, from_index, to_grid_index)
			else:
				GameManager.state = ShopSystem.transfer(GameManager.state, {"zone": "grid", "slot": from_index}, {"zone": "grid", "slot": to_grid_index})
		else:
			GameManager.state = ShopSystem.transfer(GameManager.state, {"zone": "grid", "slot": from_index}, {"zone": "grid", "slot": to_grid_index})
	_render()


func _on_forge_quick_slot_grid(grid_slot: int) -> void:
	GameManager.state = ForgeSystem.forge_quick_slot_from_grid(GameManager.state, grid_slot)
	_render()


# ── Undo ──────────────────────────────────────────────────────────────────────

func _on_undo_pressed() -> void:
	AudioManager.play("click")
	_do_undo()


func _do_undo() -> void:
	if GameManager.apply_undo():
		_render()


# ── Debug ─────────────────────────────────────────────────────────────────────

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


func _on_fight_pressed() -> void:
	AudioManager.play("click")
	var s: Dictionary = GameManager.state
	var date := Time.get_date_dict_from_system()
	var day_key: int = (date["year"] as int) * 10000 + (date["month"] as int) * 100 + (date["day"] as int)
	var context: Dictionary = {
		"day": day_key,
		"round": s["round"] as int,
		"shop_tier": s["shop_tier"] as int,
	}
	var snapshot: Dictionary = OpponentProvider.get_opponent(context)
	GameManager.state = PhaseSystem.to_battle(s, snapshot)
	get_tree().change_scene_to_file("res://scenes/screens/Battle.tscn")
