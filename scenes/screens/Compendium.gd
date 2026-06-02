extends Control

const CARD_SIZE := Vector2(160, 200)
const TIER_NAMES: Dictionary = {
	1: "Tier 1 — Basics",
	2: "Tier 2 — Combinations",
	3: "Tier 3 — Compounded",
}


func _ready() -> void:
	_build_content()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/screens/MainMenu.tscn")


func _build_content() -> void:
	var root: Node = $VBoxContainer/ScrollContainer/CompendiumContent

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
			header.modulate = Color(0.9, 0.75, 0.3)
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
	card.custom_minimum_size = CARD_SIZE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.11, 0.16, 0.97)
	style.set_border_width_all(2)
	style.border_color = Color(0.35, 0.38, 0.5, 0.85)
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
	var dps: float = (elem["damage"] as int) / (elem["cooldown"] as float)
	var stats_lbl := Label.new()
	stats_lbl.text = "cd %.1f  dmg %d  %dg" % [elem["cooldown"] as float, elem["damage"] as int, elem["price"] as int]
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

	# Recipes (compact)
	var recipes: Array[String] = _recipes_for(elem["id"] as String)
	if recipes.size() > 0:
		var sep := HSeparator.new()
		vbox.add_child(sep)
		for recipe_str: String in recipes:
			var r_lbl := Label.new()
			r_lbl.text = recipe_str
			r_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			UIScale.apply(r_lbl, UIScale.COMP_RECIPE)
			r_lbl.modulate = Color(0.6, 0.9, 0.6)
			r_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox.add_child(r_lbl)

	return card


func _recipes_for(element_id: String) -> Array[String]:
	var results: Array[String] = []
	for recipe: Dictionary in RecipeData.all_recipes():
		if (recipe["result"] as String) == element_id:
			var a: Dictionary = ElementData.find(recipe["a"] as String)
			var b: Dictionary = ElementData.find(recipe["b"] as String)
			results.append("%s+%s" % [a["emoji"] as String, b["emoji"] as String])
	return results
