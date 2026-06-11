class_name ForgePanel
extends VBoxContainer

# The Forge bench, extracted from Shop.gd. Owns the bench UI (two ForgeSlots, the
# info/result labels, the Forge button) and the forge discoverability hint (ADR
# 0009). Bench operations mutate GameManager.state here, then signal the Shop so
# the rest of the shop re-renders. The Shop stays the orchestrator; the bench now
# reads as one module. Attached to the RightPanel node in Shop.tscn.
#
# Interface (called by Shop):
#   setup()                          one-time theme + wiring, after the node exists
#   render(state)                    rebuild bench + info + hint
#   quick_add_from_inventory(slot)   F-key quick-forge from an inventory slot
#   quick_add_from_grid(slot)        F-key quick-forge from a battle-grid slot
#
# Signals (Shop connects):
#   state_changed              a bench op changed GameManager.state → Shop re-renders
#   forge_succeeded            a forge discovered a new recipe → Shop fires achievement
#   tooltip_requested(element) / tooltip_hide   show/hide the shared Item Tooltip

signal state_changed
signal forge_succeeded
signal tooltip_requested(element: Dictionary)
signal tooltip_hide

var _hint_box: VBoxContainer = null
var _result_elem: Variant = null
var _result_hover_timer: Timer


# One-time setup: forge theme, the dynamic hint box, the result-hover tooltip, and
# the Forge button signal (wired here instead of in the .tscn so the panel owns it).
func setup() -> void:
	_apply_theme()

	_hint_box = VBoxContainer.new()
	_hint_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint_box.add_theme_constant_override("separation", 2)
	add_child(_hint_box)

	_result_hover_timer = Timer.new()
	_result_hover_timer.wait_time = 0.3
	_result_hover_timer.one_shot = true
	add_child(_result_hover_timer)
	_result_hover_timer.timeout.connect(_on_result_hover_timeout)

	var result_lbl: Label = $ForgeResultLabel
	result_lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	result_lbl.mouse_entered.connect(func() -> void:
		if _result_elem != null:
			_result_hover_timer.start()
	)
	result_lbl.mouse_exited.connect(func() -> void:
		_result_hover_timer.stop()
		tooltip_hide.emit()
	)

	($ForgeButton as Button).pressed.connect(_on_forge_button_pressed)


func _apply_theme() -> void:
	# Forge bench: purple panel background via Container's built-in "panel" stylebox.
	var forge_style := StyleBoxFlat.new()
	forge_style.bg_color = ThemeData.FORGE_PANEL_BG
	forge_style.set_border_width_all(1)
	forge_style.border_color = ThemeData.FORGE_PANEL_BORDER
	forge_style.set_corner_radius_all(8)
	forge_style.content_margin_left = 10.0
	forge_style.content_margin_right = 10.0
	forge_style.content_margin_top = 8.0
	forge_style.content_margin_bottom = 8.0
	add_theme_stylebox_override("panel", forge_style)

	# Forge button — red action button, distinct from the forge/tier purples.
	var forge_btn: Button = $ForgeButton
	forge_btn.add_theme_stylebox_override("normal", _button_style(ThemeData.FORGE_BUTTON_BG))
	forge_btn.add_theme_stylebox_override("hover", _button_style(ThemeData.FORGE_BUTTON_BG_HOVER))
	forge_btn.add_theme_stylebox_override("pressed", _button_style(ThemeData.FORGE_BUTTON_BG_HOVER))
	forge_btn.add_theme_stylebox_override("disabled", _button_style(ThemeData.FORGE_BUTTON_BG_DISABLED))
	forge_btn.add_theme_color_override("font_color", Color.WHITE)
	UIScale.apply(forge_btn, UIScale.FORGE_BUTTON)
	($ForgeHeader as Label).add_theme_color_override("font_color", ThemeData.COLOR_HEADER_FORGE)


func _button_style(bg: Color) -> StyleBoxFlat:
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


# ── render ────────────────────────────────────────────────────────────────────

func render(s: Dictionary) -> void:
	var row: Node = $ForgeSlotsRow
	for child: Node in row.get_children():
		child.queue_free()
	var forge_slots: Array = s["forge_slots"]
	for i: int in 2:
		var fslot: ForgeSlot = ForgeSlot.new()
		fslot.forge_slot_index = i
		row.add_child(fslot)
		fslot.set_item(forge_slots[i])
		fslot.item_placed.connect(_on_slot_item_placed)
		fslot.tooltip_requested.connect(_on_slot_tooltip)
		fslot.tooltip_hide_requested.connect(_on_slot_tooltip_hide)
		fslot.item_removed.connect(_on_slot_item_removed)
	_update_info(s)


func _update_info(s: Dictionary) -> void:
	_update_partner_hint(s)
	var info: Label = $ForgeInfoLabel
	var result: Label = $ForgeResultLabel
	var forge_btn: Button = $ForgeButton
	var slots: Array = s["forge_slots"]
	var ea: Variant = slots[0]
	var eb: Variant = slots[1]
	result.text = ""
	_result_elem = null
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
		# decide before committing. preview returns "→ …" on a hit, "✗ …" on a miss.
		var preview_text: String = ForgeSystem.preview(s, {"kind": "forge_bench"})
		var has_recipe: bool = preview_text.begins_with("→")
		info.text = "Forge result:"
		result.text = preview_text
		result.add_theme_color_override("font_color", ThemeData.COLOR_PLAYER_SIDE if has_recipe else ThemeData.COLOR_OPP_SIDE)
		forge_btn.disabled = not has_recipe
		# The hoverable result Element comes straight from ForgeSystem — the scene
		# never re-derives the ADR-0008 level rule.
		_result_elem = ForgeSystem.result_element(s, {"kind": "forge_bench"})


# ── Forge discoverability hint (ADR 0009) ─────────────────────────────────────
# Populated when exactly one element sits in the bench. Shows "Made from" (the
# recipe(s) that produce the placed element) + "Forges with" (everything it can
# forge into). Each element is a hoverable chip that pops the Item Tooltip via the
# tooltip_requested signal — the SAME card used everywhere, no duplication.

func _update_partner_hint(s: Dictionary) -> void:
	for child: Node in _hint_box.get_children():
		child.queue_free()

	# Show only when exactly one bench slot is filled (the "what next?" moment).
	var slots: Array = s["forge_slots"]
	var single: Variant = null
	if slots[0] != null and slots[1] == null:
		single = slots[0]
	elif slots[1] != null and slots[0] == null:
		single = slots[1]
	if single == null:
		_hint_box.visible = false
		return
	_hint_box.visible = true

	var elem: Dictionary = single as Dictionary
	var elem_id: String = elem["element_id"] as String

	# Honest about ADR 0008: a Level-1 bench item can't forge until merged up.
	if (elem["level"] as int) < TuningData.FORGE_MIN_INPUT_LEVEL:
		var note := Label.new()
		note.text = "⚠ Level %d — Merge to Level %d to forge" % [elem["level"] as int, TuningData.FORGE_MIN_INPUT_LEVEL]
		note.autowrap_mode = TextServer.AUTOWRAP_WORD
		note.modulate = ThemeData.COLOR_OPP_SIDE
		UIScale.apply(note, UIScale.TOOLTIP_SECTION)
		_hint_box.add_child(note)

	# Made from — the recipe(s) that produce this element (reverse). T2+ only; a T1
	# bench item has none. Hover any ingredient chip for its card.
	var made: Array[Dictionary] = RecipeData.recipes_for(elem_id)
	if not made.is_empty():
		_add_section_header("Made from:")
		var neutral := Color(0.7, 0.82, 0.95)
		for pair: Dictionary in made:
			var resolved: Dictionary = RecipeData.describe_pair(pair)
			if resolved.is_empty():
				continue
			_add_recipe_row(_make_chip(resolved["a"], neutral), "+", _make_chip(resolved["b"], neutral))

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
		_add_section_header("Forges with:")
		var owned_color := Color(0.55, 0.95, 0.6)
		var unowned_color := Color(0.62, 0.64, 0.72)
		for row: Dictionary in rows:
			var partner_color: Color = owned_color if (row["owned"] as bool) else unowned_color
			var partner_chip: Control = _make_chip(row["partner"] as Dictionary, partner_color)
			var result_chip: Control = _make_chip(row["result"] as Dictionary, Color(0.85, 0.85, 0.92))
			_add_recipe_row(partner_chip, "→", result_chip)


func _add_section_header(text: String) -> void:
	var header := Label.new()
	header.text = text
	header.modulate = Color(0.6, 0.6, 0.68)
	UIScale.apply(header, UIScale.TOOLTIP_SECTION)
	_hint_box.add_child(header)


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
	_hint_box.add_child(row)


# A hoverable element chip (emoji + name). Hovering pops the shared Item Tooltip
# through tooltip_requested so the player can read the element's full info.
func _make_chip(def: Dictionary, color: Color) -> Control:
	var chip := Label.new()
	chip.text = "%s %s" % [def["emoji"], def["name"]]
	chip.modulate = color
	chip.mouse_filter = Control.MOUSE_FILTER_STOP
	UIScale.apply(chip, UIScale.TOOLTIP_STAT)
	chip.mouse_entered.connect(func() -> void: tooltip_requested.emit(def))
	chip.mouse_exited.connect(func() -> void: tooltip_hide.emit())
	return chip


# Set of element ids the player currently owns (inventory + battle grid), at any level.
func _owned_element_ids(s: Dictionary) -> Dictionary:
	var owned: Dictionary = {}
	for zone: String in ["inventory", "battle_grid"]:
		for item: Variant in s[zone] as Array:
			if item != null:
				owned[(item as Dictionary)["element_id"] as String] = true
	return owned


# ── bench operations (mutate state, signal Shop to re-render) ──────────────────

func _on_slot_item_placed(forge_slot_idx: int, from_inv_idx: int) -> void:
	GameManager.state = ForgeSystem.attempt(GameManager.state,
		{"kind": "to_bench", "forge_slot": forge_slot_idx, "from": {"zone": "inventory", "slot": from_inv_idx}})["state"]
	state_changed.emit()


func _on_slot_item_removed(forge_slot_idx: int) -> void:
	GameManager.state = ForgeSystem.attempt(GameManager.state, {"kind": "from_bench", "forge_slot": forge_slot_idx})["state"]
	state_changed.emit()


func quick_add_from_inventory(inv_slot: int) -> void:
	GameManager.state = ForgeSystem.attempt(GameManager.state,
		{"kind": "to_bench", "forge_slot": -1, "from": {"zone": "inventory", "slot": inv_slot}})["state"]
	state_changed.emit()


func quick_add_from_grid(grid_slot: int) -> void:
	GameManager.state = ForgeSystem.attempt(GameManager.state,
		{"kind": "to_bench", "forge_slot": -1, "from": {"zone": "grid", "slot": grid_slot}})["state"]
	state_changed.emit()


func _on_forge_button_pressed() -> void:
	GameManager.save_undo()
	var pre_recipe_count: int = (GameManager.state["discovered_recipes"] as Array).size()
	var result: Dictionary = ForgeSystem.attempt(GameManager.state, {"kind": "forge_bench"})
	GameManager.state = result["state"] as Dictionary
	var outcome: String = result["outcome"] as String
	var level_mismatch: bool = result["level_mismatch"] as bool
	var discovered_new: bool = false
	if outcome == "ok":
		AudioManager.play("forge")
		discovered_new = (GameManager.state["discovered_recipes"] as Array).size() > pre_recipe_count

	# Shop re-renders the whole shop (inventory changed); our render() runs as part of
	# that and resets the result label, so set the outcome message afterwards.
	state_changed.emit()
	if discovered_new:
		forge_succeeded.emit()

	var result_lbl: Label = $ForgeResultLabel
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


func _on_result_hover_timeout() -> void:
	if _result_elem != null:
		tooltip_requested.emit(_result_elem as Dictionary)


func _on_slot_tooltip(element: Dictionary) -> void:
	tooltip_requested.emit(element)


func _on_slot_tooltip_hide() -> void:
	tooltip_hide.emit()
