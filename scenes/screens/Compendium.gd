extends Control

const CARD_WIDTH: float = 160.0
const TIER_NAMES: Dictionary = {
	1: "Tier 1 — Basics",
	2: "Tier 2 — Combinations",
	3: "Tier 3 — Compounded",
	4: "Tier 4 — Phenomena",
}

# Human-readable label per ability trigger. Fixed triggers only; "periodic" and
# "on_status_applied" are formatted in _trigger_label from their extra fields.
const TRIGGER_LABELS: Dictionary = {
	"combat_start":      "Combat start",
	"passive":           "Passive",
	"passive_on_hit":    "On hit",
	"on_burn_applied":   "On [burn]",
	"on_heal_applied":   "On [heal]",
	"on_leech":          "On [leech]",
	"on_poison_tick":    "On [poison] tick",
	"on_armor_stripped": "On armor strip",
	"on_haste_applied":  "On [haste]",
}


func _ready() -> void:
	_build_content()


func _on_back_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file(GameManager.compendium_return_scene)


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
		trigger_lbl.text = _trigger_label(ability)
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


func _trigger_label(ability: Dictionary) -> String:
	var trigger: String = ability.get("trigger", "") as String
	var label: String = ""
	match trigger:
		"periodic":
			var seconds_text: String = "%.1f" % (float(ability.get("interval_deciseconds", 0) as int) / 10.0)
			if seconds_text.ends_with(".0"):
				seconds_text = seconds_text.left(seconds_text.length() - 2)
			label = "Every %ss" % seconds_text
		"on_status_applied":
			label = "On [%s]" % (ability.get("status", "") as String)
		"on_activate":
			var every_n: int = ability.get("every_n", 1) as int
			label = ("Every %d activations" % every_n) if every_n > 1 else "On activation"
		_:
			label = TRIGGER_LABELS.get(trigger, trigger) as String
	var multicast: int = ability.get("multicast", 0) as int
	if multicast > 0:
		label += "  ×%d" % (multicast + 1)
	return label


func _recipes_for(element_id: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for pair: Dictionary in RecipeData.recipes_for(element_id):
		var a: Dictionary = ElementData.find(pair["a"] as String)
		var b: Dictionary = ElementData.find(pair["b"] as String)
		results.append({
			"a_emoji": a["emoji"] as String,
			"a_name":  a["name"]  as String,
			"b_emoji": b["emoji"] as String,
			"b_name":  b["name"]  as String,
		})
	return results
