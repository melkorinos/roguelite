class_name ForgePanel
extends VBoxContainer

# The Forge bench. Two-column layout: the BENCH (2 ForgeSlot Element Cards + the Forge
# button + status line) on the LEFT, the FORGE PATHS on the RIGHT. The right column shows,
# depending on the bench:
#   • one element present → its "Made from" / "Forges with" paths (hoverable chips; hover
#     pops the partner/result as a full ElementCard via CardPreview).
#   • two valid (forgeable) elements → the entire resulting ElementCard.
# Bench operations mutate GameManager.state here, then signal the Shop so the rest of the
# shop re-renders. Attached to the RightPanel node in Shop.tscn.
#
# Interface (called by Shop):
#   setup() · render(state) · quick_add_from_inventory(slot) · quick_add_from_grid(slot)
# Signals (Shop connects): state_changed · forge_succeeded

signal state_changed
signal forge_succeeded

var _paths_box: VBoxContainer = null      # right column: forge paths / result card
var _card_preview: CardPreview = null     # floating preview for hovered path chips
var _glossary: GlossaryPopup = null       # keyword popup for the inline result card
# Bench nodes captured before the .tscn children are reparented into the left column.
var _slots_row: HBoxContainer
var _info_lbl: Label
var _result_lbl: Label
var _forge_btn: Button


# One-time setup: theme, the two-column split, and the forge-path preview helpers.
func setup() -> void:
	_apply_theme()

	# Capture the .tscn bench nodes before moving them.
	_slots_row = $ForgeSlotsRow
	_info_lbl = $ForgeInfoLabel
	_result_lbl = $ForgeResultLabel
	_forge_btn = $ForgeButton
	($ForgeSeparator as HSeparator).visible = false  # the frame divides; no inner rule

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", LayoutData.COLUMN_GAP)
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(columns)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	columns.add_child(left)
	for node: Variant in [$ForgeHintLine, _info_lbl, _slots_row, _forge_btn, _result_lbl]:
		(node as Control).reparent(left)

	_paths_box = VBoxContainer.new()
	_paths_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_paths_box.add_theme_constant_override("separation", 4)
	columns.add_child(_paths_box)

	_card_preview = CardPreview.new()
	add_child(_card_preview)
	_glossary = GlossaryPopup.new()
	add_child(_glossary)

	_forge_btn.pressed.connect(_on_forge_button_pressed)


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
	for child: Node in _slots_row.get_children():
		child.queue_free()
	var forge_slots: Array = s["forge_slots"]
	for i: int in 2:
		var fslot: ForgeSlot = ForgeSlot.new()
		fslot.forge_slot_index = i
		_slots_row.add_child(fslot)
		fslot.set_item(forge_slots[i])
		fslot.item_placed.connect(_on_slot_item_placed)
		fslot.item_removed.connect(_on_slot_item_removed)
	_update_info(s)


func _update_info(s: Dictionary) -> void:
	var slots: Array = s["forge_slots"]
	var ea: Variant = slots[0]
	var eb: Variant = slots[1]
	_result_lbl.text = ""
	if ea == null and eb == null:
		_info_lbl.text = "Drop 2 items to forge"
		_forge_btn.disabled = true
	elif ea != null and eb == null:
		var da: Dictionary = ea as Dictionary
		_info_lbl.text = "%s %s in slot 1 — add second item" % [da["emoji"], da["name"]]
		_forge_btn.disabled = true
	elif ea == null and eb != null:
		var db: Dictionary = eb as Dictionary
		_info_lbl.text = "%s %s in slot 2 — add first item" % [db["emoji"], db["name"]]
		_forge_btn.disabled = true
	else:
		# Both present — the result is shown as a full card on the right (see _render_paths);
		# the status line only carries the miss reason, if any.
		var preview_text: String = ForgeSystem.preview(s, {"kind": "forge_bench"})
		var has_recipe: bool = preview_text.begins_with("→")
		_info_lbl.text = "Forge result →" if has_recipe else "Forge result:"
		_forge_btn.disabled = not has_recipe
		if not has_recipe:
			_result_lbl.text = preview_text
			_result_lbl.add_theme_color_override("font_color", ThemeData.COLOR_OPP_SIDE)
	_render_paths(s)


# ── Forge paths (right column) ────────────────────────────────────────────────
# One element → its "Made from" / "Forges with" recipe chips. Two valid elements →
# the resulting ElementCard. Each path chip pops the partner/result as a full card.

func _render_paths(s: Dictionary) -> void:
	for child: Node in _paths_box.get_children():
		child.queue_free()

	var slots: Array = s["forge_slots"]
	var a: Variant = slots[0]
	var b: Variant = slots[1]

	if a != null and b != null:
		# Both present: show the resulting card when there is a recipe.
		if ForgeSystem.preview(s, {"kind": "forge_bench"}).begins_with("→"):
			var result_elem: Variant = ForgeSystem.result_element(s, {"kind": "forge_bench"})
			if result_elem != null and not (result_elem as Dictionary).is_empty():
				_add_paths_header("RESULT", ThemeData.COLOR_PLAYER_SIDE)
				_add_result_card(result_elem as Dictionary)
		return

	# Exactly one present: the discoverability paths (ADR 0009).
	var single: Variant = a if a != null else b
	if single == null:
		return
	_build_partner_hint(s, single as Dictionary)


# A non-interactive ElementCard of the forge result, with live keyword links.
func _add_result_card(elem: Dictionary) -> void:
	var card := ElementCard.new()
	card.card_width = LayoutData.CARD_PREVIEW
	card.keywords_interactive = true
	_paths_box.add_child(card)
	card.render(elem)
	card.keyword_hovered.connect(func(keyword: String) -> void: _glossary.show_keyword(keyword))
	card.keyword_unhovered.connect(func() -> void: _glossary.hide_popup())


func _build_partner_hint(s: Dictionary, elem: Dictionary) -> void:
	var elem_id: String = elem["element_id"] as String

	# Honest about ADR 0008: a Level-1 bench item can't forge until merged up.
	if (elem["level"] as int) < TuningData.FORGE_MIN_INPUT_LEVEL:
		var note := Label.new()
		note.text = "⚠ Level %d — Merge to Level %d to forge" % [elem["level"] as int, TuningData.FORGE_MIN_INPUT_LEVEL]
		note.autowrap_mode = TextServer.AUTOWRAP_WORD
		note.modulate = ThemeData.COLOR_OPP_SIDE
		UIScale.apply(note, UIScale.TOOLTIP_SECTION)
		_paths_box.add_child(note)

	# Made from — the recipe(s) that produce this element (reverse). T2+ only.
	var made: Array[Dictionary] = RecipeData.recipes_for(elem_id)
	if not made.is_empty():
		_add_paths_header("Made from:", ThemeData.COLOR_SUBTITLE)
		for pair: Dictionary in made:
			var resolved: Dictionary = RecipeData.describe_pair(pair)
			if resolved.is_empty():
				continue
			_add_recipe_row(_make_chip(resolved["a"], ThemeData.COLOR_COMP_ABILITY), "+", _make_chip(resolved["b"], ThemeData.COLOR_COMP_ABILITY))

	# Forges with — everything this element can forge INTO. Owned partners first + highlighted.
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
		_add_paths_header("Forges with:", ThemeData.COLOR_SUBTITLE)
		for row: Dictionary in rows:
			var partner_color: Color = ThemeData.COLOR_PLAYER_SIDE if (row["owned"] as bool) else ThemeData.COLOR_SUBTITLE.lightened(0.2)
			var partner_chip: Control = _make_chip(row["partner"] as Dictionary, partner_color)
			var result_chip: Control = _make_chip(row["result"] as Dictionary, ThemeData.COLOR_COMP_ABILITY)
			_add_recipe_row(partner_chip, "→", result_chip)


func _add_paths_header(text: String, color: Color) -> void:
	var header := Label.new()
	header.text = text
	header.add_theme_color_override("font_color", color)
	UIScale.apply(header, UIScale.TOOLTIP_SECTION)
	_paths_box.add_child(header)


func _add_recipe_row(left: Control, separator: String, right: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.add_child(left)
	var sep := Label.new()
	sep.text = separator
	sep.modulate = ThemeData.COLOR_SUBTITLE
	UIScale.apply(sep, UIScale.TOOLTIP_STAT)
	row.add_child(sep)
	row.add_child(right)
	_paths_box.add_child(row)


# A hoverable element chip (emoji + name). Hovering pops the element's full ElementCard
# via the floating CardPreview (the "show me the card" path the player asked for).
func _make_chip(def: Dictionary, color: Color) -> Control:
	var chip := Label.new()
	chip.text = "%s %s" % [def["emoji"], def["name"]]
	chip.add_theme_color_override("font_color", color)
	chip.mouse_filter = Control.MOUSE_FILTER_STOP
	UIScale.apply(chip, UIScale.TOOLTIP_STAT)
	chip.mouse_entered.connect(func() -> void: _card_preview.show_for(def, chip.get_global_rect()))
	chip.mouse_exited.connect(func() -> void: _card_preview.request_hide())
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
	# that and resets the status line, so set the outcome message afterwards.
	state_changed.emit()
	if discovered_new:
		forge_succeeded.emit()

	match outcome:
		"ok":
			var msg: String = "Forged!"
			if level_mismatch:
				msg += "  ⚠ Level mismatch — result at lower level"
			_result_lbl.text = msg
		"no_recipe":
			_result_lbl.text = "✗ No recipe — items returned"
		"level_too_low":
			_result_lbl.text = "✗ Inputs must be Level %d+ — Merge them first" % TuningData.FORGE_MIN_INPUT_LEVEL
		"no_gold":
			_result_lbl.text = "✗ Not enough gold to forge"
		"inv_full":
			_result_lbl.text = "✗ Inventory full — clear a slot first"
		_:
			_result_lbl.text = ""
