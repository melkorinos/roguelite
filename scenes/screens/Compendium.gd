extends Control

const CARD_WIDTH: float = 160.0
const TIER_NAMES: Dictionary = {
	1: "Tier 1 — Basics",
	2: "Tier 2 — Combinations",
	3: "Tier 3 — Compounded",
	4: "Tier 4 — Phenomena",
}

func _ready() -> void:
	# A TabBar between the header and the scrolling content switches the view between the
	# element roster and the Keystone (Starting Pick) roster.
	var tabs := TabBar.new()
	tabs.add_tab("Elements")
	tabs.add_tab("Keystones")
	tabs.tab_changed.connect(_on_tab_changed)
	var vbox: VBoxContainer = $VBoxContainer
	vbox.add_child(tabs)
	vbox.move_child(tabs, 2)  # after Header(0) + HSeparator(1), before the ScrollContainer
	_render_tab(0)


func _on_back_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file(GameManager.compendium_return_scene)


func _on_tab_changed(index: int) -> void:
	_render_tab(index)


func _render_tab(index: int) -> void:
	var root: Node = $VBoxContainer/ScrollContainer/CompendiumContent
	for child: Node in root.get_children():
		root.remove_child(child)
		child.queue_free()
	if index == 1:
		_build_keystones(root)
	else:
		_build_elements(root)


func _build_elements(root: Node) -> void:
	var current_tier: int = 0
	var current_grid: GridContainer = null

	for elem: Dictionary in ElementData.all_elements():
		var tier: int = elem["tier"] as int
		if tier != current_tier:
			current_tier = tier
			# Tier header
			var header := Label.new()
			header.text = TIER_NAMES.get(tier, "Tier %d" % tier) as String
			UIScale.apply(header, UIScale.COMP_HEADER)
			header.modulate = ThemeData.comp_tier_color(tier)
			root.add_child(header)
			# New card grid for this tier
			current_grid = GridContainer.new()
			current_grid.columns = 6
			current_grid.add_theme_constant_override("h_separation", 10)
			current_grid.add_theme_constant_override("v_separation", 10)
			root.add_child(current_grid)

		current_grid.add_child(_make_card(elem))


func _make_card(elem: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(CARD_WIDTH, 0)

	var tier: int = elem.get("tier", 1) as int
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeData.tier_bg(tier)
	style.set_border_width_all(2)
	style.border_color = ThemeData.tier_border(tier)
	style.set_corner_radius_all(6)
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 3)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	# Big emoji
	var emoji_lbl := Label.new()
	emoji_lbl.text = elem["emoji"] as String
	emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIScale.apply(emoji_lbl, UIScale.COMP_EMOJI)
	emoji_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(emoji_lbl)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = elem["name"] as String
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIScale.apply(name_lbl, UIScale.COMP_NAME)
	vbox.add_child(name_lbl)

	# Stats line
	var cooldown_seconds: float = float(elem["cooldown_deciseconds"] as int) / 10.0
	var dps: float = (elem["damage"] as int) / cooldown_seconds
	var stats_lbl := Label.new()
	stats_lbl.text = "cd %.1f  dmg %d  %dg" % [cooldown_seconds, elem["damage"] as int, elem["price"] as int]
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIScale.apply(stats_lbl, UIScale.COMP_STATS)
	stats_lbl.modulate = Color(0.7, 0.8, 0.9)
	vbox.add_child(stats_lbl)

	# DPS
	var dps_lbl := Label.new()
	dps_lbl.text = "%.2f dps" % dps
	dps_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIScale.apply(dps_lbl, UIScale.COMP_STATS)
	dps_lbl.modulate = Color(1.0, 0.75, 0.35)
	vbox.add_child(dps_lbl)

	# Ability trigger + description (elements with a defined Ability only)
	var ability: Dictionary = AbilityData.get_ability(elem["id"] as String)
	var ability_text: String = ability.get("description", "") as String
	if ability_text != "":
		var trigger_lbl := Label.new()
		trigger_lbl.text = AbilityData.trigger_label(ability)
		trigger_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		trigger_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		UIScale.apply(trigger_lbl, UIScale.COMP_TRIGGER)
		trigger_lbl.modulate = ThemeData.COLOR_COMP_TRIGGER
		vbox.add_child(trigger_lbl)

		var ability_lbl := Label.new()
		ability_lbl.text = ability_text
		ability_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ability_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		UIScale.apply(ability_lbl, UIScale.COMP_ABILITY)
		ability_lbl.modulate = ThemeData.COLOR_COMP_ABILITY
		vbox.add_child(ability_lbl)

		# Tier-scaled potency clarifier — the authored amounts are written at potency 1.
		var note: String = ElementData.potency_note(elem["tier"] as int, 1)
		if note != "":
			var note_lbl := Label.new()
			note_lbl.text = note
			note_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			note_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			UIScale.apply(note_lbl, UIScale.COMP_ABILITY)
			note_lbl.modulate = Color(0.55, 0.55, 0.62)
			vbox.add_child(note_lbl)

	# Recipes — emoji row + name row per ingredient pair
	var recipes: Array[Dictionary] = _recipes_for(elem["id"] as String)
	if recipes.size() > 0:
		var sep := HSeparator.new()
		sep.add_theme_constant_override("separation", 4)
		vbox.add_child(sep)
		for recipe: Dictionary in recipes:
			var recipe_emoji_lbl := Label.new()
			recipe_emoji_lbl.text = "%s  +  %s" % [recipe["a_emoji"] as String, recipe["b_emoji"] as String]
			recipe_emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			UIScale.apply(recipe_emoji_lbl, UIScale.COMP_RECIPE_EMOJI)
			recipe_emoji_lbl.modulate = Color(0.65, 0.95, 0.65)
			vbox.add_child(recipe_emoji_lbl)

			var names_lbl := Label.new()
			names_lbl.text = "%s + %s" % [recipe["a_name"] as String, recipe["b_name"] as String]
			names_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			UIScale.apply(names_lbl, UIScale.COMP_RECIPE)
			names_lbl.modulate = Color(0.5, 0.75, 0.5)
			names_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox.add_child(names_lbl)

	return card


func _recipes_for(element_id: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for pair: Dictionary in RecipeData.recipes_for(element_id):
		var resolved: Dictionary = RecipeData.describe_pair(pair)
		if resolved.is_empty():
			continue
		var a: Dictionary = resolved["a"]
		var b: Dictionary = resolved["b"]
		results.append({
			"a_emoji": a["emoji"] as String,
			"a_name":  a["name"]  as String,
			"b_emoji": b["emoji"] as String,
			"b_name":  b["name"]  as String,
		})
	return results


# ── Keystones tab (Starting Pick roster, ADR 0016) ────────────────────────────

func _build_keystones(root: Node) -> void:
	var header := Label.new()
	header.text = "Keystones — the Starting Pick"
	UIScale.apply(header, UIScale.COMP_HEADER)
	header.modulate = ThemeData.COLOR_COMP_HEADER_T3
	root.add_child(header)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	root.add_child(grid)

	for keystone: Dictionary in KeystoneData.all():
		grid.add_child(_make_keystone_card(keystone))


func _make_keystone_card(keystone: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(CARD_WIDTH, 0)

	var style := StyleBoxFlat.new()
	style.bg_color = ThemeData.tier_bg(3)
	style.set_border_width_all(2)
	style.border_color = ThemeData.tier_border(3)
	style.set_corner_radius_all(6)
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 3)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	var emoji_lbl := Label.new()
	emoji_lbl.text = keystone.get("emoji", "") as String
	emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIScale.apply(emoji_lbl, UIScale.COMP_EMOJI)
	vbox.add_child(emoji_lbl)

	var name_lbl := Label.new()
	name_lbl.text = keystone.get("name", "") as String
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	UIScale.apply(name_lbl, UIScale.COMP_NAME)
	vbox.add_child(name_lbl)

	var tags_lbl := Label.new()
	tags_lbl.text = " · ".join(PackedStringArray(keystone.get("tags", []) as Array))
	tags_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tags_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	UIScale.apply(tags_lbl, UIScale.COMP_TRIGGER)
	tags_lbl.modulate = ThemeData.COLOR_COMP_TRIGGER
	vbox.add_child(tags_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = keystone.get("description", "") as String
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	UIScale.apply(desc_lbl, UIScale.COMP_ABILITY)
	desc_lbl.modulate = ThemeData.COLOR_COMP_ABILITY
	vbox.add_child(desc_lbl)

	var pact: String = keystone.get("pact", "") as String
	if pact != "":
		var pact_lbl := Label.new()
		pact_lbl.text = "Pact: %s" % pact
		pact_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pact_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		UIScale.apply(pact_lbl, UIScale.COMP_ABILITY)
		pact_lbl.modulate = ThemeData.FLOAT_DAMAGE
		vbox.add_child(pact_lbl)

	return card
