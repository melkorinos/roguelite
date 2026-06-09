extends Control

var _inv_slot_nodes: Array = []
var _battle_slot_nodes: Array = []
var _tooltip: TooltipCard
var _pause_overlay: PauseOverlay
var _starting_pick_overlay: StartingPickOverlay
var _event_overlay: EventOverlay
var _add_elem_panel: PanelContainer = null
var _forge_hint_box: VBoxContainer = null
var _forge_result_elem: Variant = null
var _forge_result_hover_timer: Timer


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
	_build_compendium_button()
	_build_forge_hint()

	_forge_result_hover_timer = Timer.new()
	_forge_result_hover_timer.wait_time = 0.3
	_forge_result_hover_timer.one_shot = true
	add_child(_forge_result_hover_timer)
	_forge_result_hover_timer.timeout.connect(_on_forge_result_hover_timeout)
	var forge_result_lbl: Label = $VBox/MainArea/RightPanel/ForgeResultLabel
	forge_result_lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	forge_result_lbl.mouse_entered.connect(func() -> void:
		if _forge_result_elem != null:
			_forge_result_hover_timer.start()
	)
	forge_result_lbl.mouse_exited.connect(func() -> void:
		_forge_result_hover_timer.stop()
		_on_tooltip_hide()
	)

	_starting_pick_overlay = StartingPickOverlay.new()
	add_child(_starting_pick_overlay)
	_starting_pick_overlay.picked.connect(_on_starting_pick)

	_event_overlay = EventOverlay.new()
	add_child(_event_overlay)
	_event_overlay.chosen.connect(_on_event_chosen)

	var s: Dictionary = GameManager.state
	var all_null: bool = (s["shop_items"] as Array).all(func(x: Variant) -> bool: return x == null)
	if all_null:
		GameManager.state = ShopSystem.reroll_shop(s, true)
	_render()

	# Run-start choice takes priority on round 1; the Event (every N rounds) shows on
	# later visits. Both are blocking overlays gated so Shop re-entry can't double-fire.
	if not (GameManager.state["starting_pick_done"] as bool):
		_starting_pick_overlay.show_options(StartSystem.starting_options())
	elif EventSystem.is_event_due(GameManager.state):
		_event_overlay.show_rewards(EventSystem.offer(GameManager.state))


func _on_starting_pick(element_id: String) -> void:
	AudioManager.play("buy")
	GameManager.state = StartSystem.apply_starting_pick(GameManager.state, element_id)
	_starting_pick_overlay.hide_overlay()
	_render()


func _on_event_chosen(reward: Dictionary) -> void:
	AudioManager.play("buy")
	GameManager.state = EventSystem.apply_reward(GameManager.state, reward)
	_event_overlay.hide_overlay()
	_render()


func _forge_button_style(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(2)
	sb.border_color = ThemeData.FORGE_BUTTON_BORDER
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	return sb


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

	# Forge button — red action button, distinct from the forge/tier purples.
	var forge_btn: Button = $VBox/MainArea/RightPanel/ForgeButton
	forge_btn.add_theme_stylebox_override("normal", _forge_button_style(ThemeData.FORGE_BUTTON_BG))
	forge_btn.add_theme_stylebox_override("hover", _forge_button_style(ThemeData.FORGE_BUTTON_BG_HOVER))
	forge_btn.add_theme_stylebox_override("pressed", _forge_button_style(ThemeData.FORGE_BUTTON_BG_HOVER))
	forge_btn.add_theme_stylebox_override("disabled", _forge_button_style(ThemeData.FORGE_BUTTON_BG_DISABLED))
	forge_btn.add_theme_color_override("font_color", Color.WHITE)
	UIScale.apply(forge_btn, UIScale.FORGE_BUTTON)

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


# ── Compendium (in-run recipe reference) ──────────────────────────────────────

func _build_compendium_button() -> void:
	var btn := Button.new()
	btn.text = "📖 Compendium"
	UIScale.apply(btn, UIScale.FORGE_BUTTON)
	btn.pressed.connect(_on_compendium_pressed)
	$VBox/TopBar.add_child(btn)


func _on_compendium_pressed() -> void:
	AudioManager.play("click")
	GameManager.compendium_return_scene = "res://scenes/screens/Shop.tscn"
	get_tree().change_scene_to_file("res://scenes/screens/Compendium.tscn")


# ── Forge discoverability hint (ADR 0009) ─────────────────────────────────────
# Appended to the forge panel; populated when exactly one element sits in the bench.
# Shows "Made from" (the recipe(s) that produce the placed element) + "Forges with"
# (everything it can forge into). Each element is a hoverable chip that pops the
# Item Tooltip — the SAME card used everywhere (TooltipCard.show_for), no duplication.

func _build_forge_hint() -> void:
	_forge_hint_box = VBoxContainer.new()
	_forge_hint_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_forge_hint_box.add_theme_constant_override("separation", 2)
	$VBox/MainArea/RightPanel.add_child(_forge_hint_box)


func _update_forge_partner_hint(s: Dictionary) -> void:
	for child: Node in _forge_hint_box.get_children():
		child.queue_free()

	# Show only when exactly one bench slot is filled (the "what next?" moment).
	var slots: Array = s["forge_slots"]
	var single: Variant = null
	if slots[0] != null and slots[1] == null:
		single = slots[0]
	elif slots[1] != null and slots[0] == null:
		single = slots[1]
	if single == null:
		_forge_hint_box.visible = false
		return
	_forge_hint_box.visible = true

	var elem: Dictionary = single as Dictionary
	var elem_id: String = elem["element_id"] as String

	# Honest about ADR 0008: a Level-1 bench item can't forge until merged up.
	if (elem["level"] as int) < TuningData.FORGE_MIN_INPUT_LEVEL:
		var note := Label.new()
		note.text = "⚠ Level %d — Merge to Level %d to forge" % [elem["level"] as int, TuningData.FORGE_MIN_INPUT_LEVEL]
		note.autowrap_mode = TextServer.AUTOWRAP_WORD
		note.modulate = ThemeData.COLOR_OPP_SIDE
		UIScale.apply(note, UIScale.TOOLTIP_SECTION)
		_forge_hint_box.add_child(note)

	# Made from — the recipe(s) that produce this element (reverse). T2+ only; a T1
	# bench item has none. Hover any ingredient chip for its card.
	var made: Array[Dictionary] = RecipeData.recipes_for(elem_id)
	if not made.is_empty():
		_add_hint_section_header("Made from:")
		var neutral := Color(0.7, 0.82, 0.95)
		for pair: Dictionary in made:
			var a: Dictionary = ElementData.find(pair["a"] as String)
			var b: Dictionary = ElementData.find(pair["b"] as String)
			if a.is_empty() or b.is_empty():
				continue
			_add_recipe_row(_make_element_chip(a, neutral), "+", _make_element_chip(b, neutral))

	# Forges with — everything this element can forge INTO (forward). Owned partners
	# (inventory + grid) first and highlighted. Hidden when empty (a forward dead-end).
	var owned: Dictionary = _owned_element_ids(s)
	var rows: Array = []
	for recipe: Dictionary in RecipeData.recipes_with(elem_id):
		var partner: Dictionary = ElementData.find(recipe["partner"] as String)
		var result: Dictionary = ElementData.find(recipe["result"] as String)
		if partner.is_empty() or result.is_empty():
			continue
		rows.append({
			"partner": partner, "result": result,
			"owned": owned.has(recipe["partner"] as String),
			"tier": result["tier"] as int,
		})
	rows.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
		if (x["owned"] as bool) != (y["owned"] as bool):
			return x["owned"] as bool
		return (x["tier"] as int) < (y["tier"] as int))

	if not rows.is_empty():
		_add_hint_section_header("Forges with:")
		var owned_color := Color(0.55, 0.95, 0.6)
		var unowned_color := Color(0.62, 0.64, 0.72)
		for row: Dictionary in rows:
			var partner_color: Color = owned_color if (row["owned"] as bool) else unowned_color
			var partner_chip: Control = _make_element_chip(row["partner"] as Dictionary, partner_color)
			var result_chip: Control = _make_element_chip(row["result"] as Dictionary, Color(0.85, 0.85, 0.92))
			_add_recipe_row(partner_chip, "→", result_chip)


func _add_hint_section_header(text: String) -> void:
	var header := Label.new()
	header.text = text
	header.modulate = Color(0.6, 0.6, 0.68)
	UIScale.apply(header, UIScale.TOOLTIP_SECTION)
	_forge_hint_box.add_child(header)


# Assembles one recipe row: [chip] sep [chip], the chips hoverable for their card.
func _add_recipe_row(left: Control, separator: String, right: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.add_child(left)
	var sep := Label.new()
	sep.text = separator
	sep.modulate = Color(0.5, 0.5, 0.56)
	UIScale.apply(sep, UIScale.TOOLTIP_STAT)
	row.add_child(sep)
	row.add_child(right)
	_forge_hint_box.add_child(row)


# A hoverable element chip (emoji + name). Hovering pops the shared Item Tooltip —
# the same card seen everywhere — so the player can read the element's full info.
func _make_element_chip(def: Dictionary, color: Color) -> Control:
	var chip := Label.new()
	chip.text = "%s %s" % [def["emoji"], def["name"]]
	chip.modulate = color
	chip.mouse_filter = Control.MOUSE_FILTER_STOP
	UIScale.apply(chip, UIScale.TOOLTIP_STAT)
	chip.mouse_entered.connect(_on_hint_chip_hover.bind(def))
	chip.mouse_exited.connect(_on_hint_chip_unhover)
	return chip


func _on_hint_chip_hover(def: Dictionary) -> void:
	_tooltip.show_for(def)


func _on_hint_chip_unhover() -> void:
	_tooltip.hide_card()


# Set of element ids the player currently owns (inventory + battle grid), at any level.
func _owned_element_ids(s: Dictionary) -> Dictionary:
	var owned: Dictionary = {}
	for zone: String in ["inventory", "battle_grid"]:
		for item: Variant in s[zone] as Array:
			if item != null:
				owned[(item as Dictionary)["element_id"] as String] = true
	return owned


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
	$VBox/TopBar/HPLabel.text = "❤ %d/%d   💰 %dg" % [s["player_hp"], s["player_starting_hp"], s["gold"]]
	$VBox/TopBar/LivesLabel.text = "Life: %d  Wins: %d/10" % [s["lives"], s["wins"]]
	var unlocked: Array[int] = ShopSystem.unlocked_tiers(s["run_discoveries"] as Array)
	$VBox/DebugRow/TierLabel.text = "Shop T1–T%d  (%d forged)" % [unlocked[unlocked.size() - 1], (s["run_discoveries"] as Array).size()]
	($VBox/MainArea/LeftPanel/SellZone/SellZoneVBox/ShopHeaderRow/RerollButton as Button).text = "Reroll — %dg" % ShopSystem.reroll_cost(s)
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
		slot.custom_minimum_size = Vector2(143, 143)
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
			slot.apply_item_style(elem["tier"] as int)
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
	_update_forge_partner_hint(s)
	var info: Label = $VBox/MainArea/RightPanel/ForgeInfoLabel
	var result: Label = $VBox/MainArea/RightPanel/ForgeResultLabel
	var forge_btn: Button = $VBox/MainArea/RightPanel/ForgeButton
	var slots: Array = s["forge_slots"]
	var ea: Variant = slots[0]
	var eb: Variant = slots[1]
	result.text = ""
	_forge_result_elem = null
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
		# Both items present — show the resulting element prominently so the player can
		# decide before committing. preview_bench returns "→ …" on a hit, "✗ …" on a miss.
		var preview_text: String = ForgeSystem.preview(s, {"kind": "forge_bench"})
		var has_recipe: bool = preview_text.begins_with("→")
		info.text = "Forge result:"
		result.text = preview_text
		result.add_theme_color_override("font_color", ThemeData.COLOR_PLAYER_SIDE if has_recipe else ThemeData.COLOR_OPP_SIDE)
		forge_btn.disabled = not has_recipe
		# Compute the hoverable result element for the tooltip.
		if has_recipe:
			var da: Dictionary = (ea as Dictionary)
			var db: Dictionary = (eb as Dictionary)
			var result_id: String = RecipeData.find_result(da["element_id"], db["element_id"])
			if not result_id.is_empty():
				var la: int = da["level"] as int
				var lb: int = db["level"] as int
				var result_level: int = maxi(1, mini(la, lb) - TuningData.FORGE_RESULT_LEVEL_PENALTY)
				_forge_result_elem = ElementData.instantiate(result_id, result_level)
			else:
				# Merge case: same element, level+1
				var merged: Dictionary = (ea as Dictionary).duplicate()
				merged["level"] = (merged["level"] as int) + 1
				_forge_result_elem = merged
		else:
			_forge_result_elem = null


# ── Item Tooltip ─────────────────────────────────────────────────────────────

func _on_tooltip_requested(element: Dictionary) -> void:
	_tooltip.show_for(element)


func _on_tooltip_hide() -> void:
	_tooltip.hide_card()


func _on_forge_result_hover_timeout() -> void:
	if _forge_result_elem != null:
		_tooltip.show_for(_forge_result_elem as Dictionary)


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


# ── Shop intake ───────────────────────────────────────────────────────────────

# Routes a drag-drop / buy through ShopSystem.resolve_drop and returns the outcome
# ("bought" | "merged" | "swapped" | "rejected"). Captures undo for the actions
# that change holdings (buys and merges), matching the previous per-branch undo
# behavior. The caller maps the outcome to a sound.
func _apply_drop(from_loc: Dictionary, to_loc: Dictionary) -> String:
	var before: Dictionary = GameManager.state
	var result: Dictionary = ShopSystem.resolve_drop(before, from_loc, to_loc)
	var outcome: String = result["outcome"] as String
	if outcome == "bought" or outcome == "merged":
		GameManager.undo_state = before.duplicate(true)
	GameManager.state = result["state"] as Dictionary
	return outcome


func _buy_sound(outcome: String) -> void:
	match outcome:
		"bought":   AudioManager.play("buy")
		"merged":   AudioManager.play("upgrade")
		_:          AudioManager.play("reject")


# ── Buy ───────────────────────────────────────────────────────────────────────

func _on_buy_pressed(_element_id: String, shop_slot: int) -> void:
	_buy_sound(_apply_drop({"zone": "shop", "slot": shop_slot}, {"zone": "inventory", "slot": -1}))
	_render()


func _on_reroll_pressed() -> void:
	AudioManager.play("click")
	GameManager.save_undo()
	GameManager.state = ShopSystem.reroll_shop(GameManager.state)
	_render()


# ── Buy → empty inventory slot (no dialog) ───────────────────────────────────

func _on_shop_buy_to_slot_requested(_element_id: String, to_inv_index: int, shop_slot: int) -> void:
	_buy_sound(_apply_drop({"zone": "shop", "slot": shop_slot}, {"zone": "inventory", "slot": to_inv_index}))
	_render()


# ── Buy + level-up combo (no confirmation — undo covers it) ──────────────────

func _on_shop_buy_upgrade_requested(_element_id: String, to_inv_index: int, shop_slot: int) -> void:
	_buy_sound(_apply_drop({"zone": "shop", "slot": shop_slot}, {"zone": "inventory", "slot": to_inv_index}))
	_render()


# ── Forge bench ───────────────────────────────────────────────────────────────

func _on_forge_slot_item_placed(forge_slot_idx: int, from_inv_idx: int) -> void:
	GameManager.state = ForgeSystem.attempt(GameManager.state,
		{"kind": "to_bench", "forge_slot": forge_slot_idx, "from": {"zone": "inventory", "slot": from_inv_idx}})["state"]
	_render()


func _on_forge_quick_slot(inv_slot_index: int) -> void:
	GameManager.state = ForgeSystem.attempt(GameManager.state,
		{"kind": "to_bench", "forge_slot": -1, "from": {"zone": "inventory", "slot": inv_slot_index}})["state"]
	_render()


func _on_forge_slot_item_removed(forge_slot_idx: int) -> void:
	GameManager.state = ForgeSystem.attempt(GameManager.state, {"kind": "from_bench", "forge_slot": forge_slot_idx})["state"]
	_render()


func _on_forge_button_pressed() -> void:
	_execute_forge()


func _execute_forge() -> void:
	GameManager.save_undo()
	var pre_recipe_count: int = (GameManager.state["discovered_recipes"] as Array).size()
	var result: Dictionary = ForgeSystem.attempt(GameManager.state, {"kind": "forge_bench"})
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
		"level_too_low":
			result_lbl.text = "✗ Inputs must be Level %d+ — Merge them first" % TuningData.FORGE_MIN_INPUT_LEVEL
		"no_gold":
			result_lbl.text = "✗ Not enough gold to forge"
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
	var outcome: String = _apply_drop({"zone": from_type, "slot": from_index}, {"zone": "inventory", "slot": to_inv_index})
	if outcome == "merged":
		AudioManager.play("upgrade")
	_render()


# ── Battle grid drag-and-drop ─────────────────────────────────────────────────

func _on_grid_slot_received_drop(from_type: String, from_index: int, to_grid_index: int) -> void:
	var outcome: String = _apply_drop({"zone": from_type, "slot": from_index}, {"zone": "grid", "slot": to_grid_index})
	if outcome == "merged":
		AudioManager.play("upgrade")
	_render()


func _on_forge_quick_slot_grid(grid_slot: int) -> void:
	GameManager.state = ForgeSystem.attempt(GameManager.state,
		{"kind": "to_bench", "forge_slot": -1, "from": {"zone": "grid", "slot": grid_slot}})["state"]
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
	# Dev: unlock the next locked tier by injecting enough distinct forge discoveries.
	var s: Dictionary = GameManager.state.duplicate(true)
	var run_disc: Array = s["run_discoveries"]
	var unlocked: Array[int] = ShopSystem.unlocked_tiers(run_disc)
	for tier: int in [2, 3, 4]:
		if unlocked.has(tier):
			continue
		var needed: int = TuningData.TIER_UNLOCK_THRESHOLDS[tier] as int
		for elem: Dictionary in ElementData.all_elements():
			if needed <= 0:
				break
			if (elem["tier"] as int) == tier and not run_disc.has(elem["id"]):
				run_disc.append(elem["id"])
				needed -= 1
		break
	GameManager.state = s
	_render()


func _on_add_elem_pressed() -> void:
	if _add_elem_panel != null:
		_add_elem_panel.queue_free()
		_add_elem_panel = null
		return
	_add_elem_panel = _build_add_elem_panel()
	add_child(_add_elem_panel)


func _build_add_elem_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 420)
	panel.position = Vector2(4, 44)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.07, 0.12, 0.97)
	style.set_border_width_all(1)
	style.border_color = Color(1.0, 0.4, 0.4, 0.8)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Add element to inventory"
	title.modulate = Color(1.0, 0.55, 0.55)
	UIScale.apply(title, UIScale.TOOLTIP_STAT)
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(280, 360)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(scroll)

	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 2)
	scroll.add_child(inner)

	var current_tier: int = -1
	for elem: Dictionary in ElementData.all_elements():
		var tier: int = elem["tier"] as int
		if tier != current_tier:
			current_tier = tier
			var tier_lbl := Label.new()
			tier_lbl.text = "T%d" % tier
			tier_lbl.modulate = Color(0.5, 0.5, 0.6)
			UIScale.apply(tier_lbl, UIScale.TOOLTIP_SECTION)
			inner.add_child(tier_lbl)
		var btn := Button.new()
		var emoji: String = elem.get("emoji", "") as String
		var elem_name: String = elem.get("name", "") as String
		btn.text = "%s  %s" % [emoji, elem_name]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		UIScale.apply(btn, UIScale.TOOLTIP_STAT)
		var eid: String = elem["id"] as String
		btn.pressed.connect(_debug_add_element.bind(eid))
		inner.add_child(btn)

	return panel


func _debug_add_element(element_id: String) -> void:
	var instance: Dictionary = ElementData.instantiate(element_id)
	if instance.is_empty():
		return
	var s: Dictionary = GameManager.state.duplicate(true)
	if ShopSystem.grant_to_inventory(s, instance):
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
	}
	var snapshot: Dictionary = OpponentProvider.get_opponent(context)
	GameManager.state = PhaseSystem.to_battle(s, snapshot)
	get_tree().change_scene_to_file("res://scenes/screens/Battle.tscn")
