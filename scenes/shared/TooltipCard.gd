class_name TooltipCard
extends CanvasLayer

# The Item Tooltip. In the shop it shows base stats. In battle (show_for_battle) it
# shows the element's *current* effective stats — cooldown after shock/cooldown
# modifiers, damage after weaken — and live-updates every frame while shown.
# Holding Shift pins the card in place so the player can hover the [keyword] links
# in the ability text and read a secondary glossary card.

var _panel: PanelContainer
var _name_lbl: Label
var _stat_vals: Dictionary = {}
var _ability_rich: RichTextLabel

var _glossary_panel: PanelContainer
var _glossary_lbl: Label

var _madefrom_box: VBoxContainer
var _last_madefrom_id: String = ""  # guards against per-frame rebuilds (battle live-refresh)

# Battle context: empty side = shop/static. When set, stats refresh from live state.
var _battle_side: String = ""
var _battle_slot: int = -1
var _pinned: bool = false
var _last_ability_text: String = ""  # guards against per-frame RichText resets (hover flicker)


func _ready() -> void:
	layer = 100
	_build_ui()


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(230, 0)
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # never steals slot/game hover

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.13, 0.97)
	style.set_border_width_all(1)
	style.border_color = Color(0.45, 0.45, 0.65, 0.9)
	style.set_corner_radius_all(5)
	_panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)

	_name_lbl = Label.new()
	UIScale.apply(_name_lbl, UIScale.TOOLTIP_TITLE)
	vbox.add_child(_name_lbl)

	vbox.add_child(HSeparator.new())

	var stat_keys: Array[String] = ["▲ Tier", "⬆ Level", "⏱ Cooldown", "⚔ Base Dmg", "💥 Eff. Dmg", "💰 Price"]
	for key: String in stat_keys:
		var row := HBoxContainer.new()
		var k_lbl := Label.new()
		k_lbl.text = key
		UIScale.apply(k_lbl, UIScale.TOOLTIP_STAT)
		k_lbl.modulate = Color(0.72, 0.72, 0.78)
		k_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(k_lbl)
		var v_lbl := Label.new()
		UIScale.apply(v_lbl, UIScale.TOOLTIP_STAT)
		v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(v_lbl)
		_stat_vals[key] = v_lbl
		vbox.add_child(row)

	vbox.add_child(HSeparator.new())

	var ab_header := Label.new()
	ab_header.text = "ABILITIES"
	UIScale.apply(ab_header, UIScale.TOOLTIP_SECTION)
	ab_header.modulate = Color(0.55, 0.55, 0.62)
	vbox.add_child(ab_header)

	_ability_rich = RichTextLabel.new()
	_ability_rich.bbcode_enabled = true
	_ability_rich.fit_content = true
	_ability_rich.autowrap_mode = TextServer.AUTOWRAP_WORD
	_ability_rich.custom_minimum_size = Vector2(210, 0)
	_ability_rich.scroll_active = false
	_ability_rich.mouse_filter = Control.MOUSE_FILTER_STOP  # so keyword links are hoverable
	UIScale.apply_rich(_ability_rich, UIScale.TOOLTIP_BODY)
	_ability_rich.meta_hover_started.connect(_on_keyword_hover)
	_ability_rich.meta_hover_ended.connect(_on_keyword_unhover)
	vbox.add_child(_ability_rich)

	# "Made from" — the recipe(s) that produce this element (T2+). Populated in _render.
	_madefrom_box = VBoxContainer.new()
	_madefrom_box.add_theme_constant_override("separation", 1)
	vbox.add_child(_madefrom_box)

	var hint := Label.new()
	hint.text = "hold Shift to inspect keywords"
	UIScale.apply(hint, UIScale.TOOLTIP_SECTION)
	hint.modulate = Color(0.4, 0.4, 0.5)
	vbox.add_child(hint)

	add_child(_panel)
	_build_glossary_panel()


func _build_glossary_panel() -> void:
	_glossary_panel = PanelContainer.new()
	_glossary_panel.custom_minimum_size = Vector2(210, 0)
	_glossary_panel.visible = false
	_glossary_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.10, 0.16, 0.98)
	style.set_border_width_all(1)
	style.border_color = Color(0.4, 0.6, 0.85, 0.95)
	style.set_corner_radius_all(5)
	_glossary_panel.add_theme_stylebox_override("panel", style)
	var gm := MarginContainer.new()
	gm.add_theme_constant_override("margin_left", 8)
	gm.add_theme_constant_override("margin_right", 8)
	gm.add_theme_constant_override("margin_top", 6)
	gm.add_theme_constant_override("margin_bottom", 6)
	_glossary_panel.add_child(gm)
	_glossary_lbl = Label.new()
	_glossary_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_glossary_lbl.custom_minimum_size = Vector2(194, 0)
	UIScale.apply(_glossary_lbl, UIScale.TOOLTIP_BODY)
	_glossary_lbl.modulate = Color(0.85, 0.92, 1.0)
	gm.add_child(_glossary_lbl)
	add_child(_glossary_panel)


# ── public entry points ───────────────────────────────────────────────────────

func show_for(element: Dictionary) -> void:
	_battle_side = ""
	_battle_slot = -1
	_render(element, {})
	_panel.visible = true
	_update_position()


func show_for_battle(element: Dictionary, side: String, slot: int) -> void:
	_battle_side = side
	_battle_slot = slot
	_render(element, CombatSide.statuses(GameManager.state, side))
	_panel.visible = true
	_update_position()


func hide_card() -> void:
	if _pinned:
		return  # keep the card while the player inspects keywords
	_force_hide()


func _force_hide() -> void:
	_panel.visible = false
	_glossary_panel.visible = false


# ── rendering ─────────────────────────────────────────────────────────────────

func _render(element: Dictionary, own_statuses: Dictionary) -> void:
	var emoji: String = element.get("emoji", "") as String
	var elem_name: String = element.get("name", "") as String
	var tier: int = element.get("tier", 1) as int
	var level: int = element.get("level", 1) as int
	var base_cooldown_deciseconds: int = element.get("cooldown_deciseconds", 0) as int
	var base_dmg: int = element.get("damage", 0) as int
	var eff_dmg: int = ElementData.effective_damage(element)
	var pure_effect: bool = eff_dmg == 0  # captured before weaken; 0 here = no direct damage
	var price: int = element.get("price", 0) as int

	var cooldown_seconds: float
	if own_statuses.is_empty():
		cooldown_seconds = float(base_cooldown_deciseconds) / 10.0
	else:
		# Live: effective cooldown reflects shock-slow + cooldown modifiers; damage
		# output drops while the side is weakened.
		cooldown_seconds = float(StatusSystem.effective_cooldown_deciseconds(base_cooldown_deciseconds, own_statuses)) / 10.0
		var weaken: Dictionary = own_statuses["weaken"] as Dictionary
		if (weaken["ticks"] as int) > 0:
			eff_dmg = maxi(0, eff_dmg - (weaken["stacks"] as int))

	_name_lbl.text = "%s  %s" % [emoji, elem_name]
	(_stat_vals["▲ Tier"] as Label).text = "T%d" % tier
	(_stat_vals["⬆ Level"] as Label).text = "Lv%d" % level
	(_stat_vals["⏱ Cooldown"] as Label).text = "%.1fs" % cooldown_seconds
	(_stat_vals["⚔ Base Dmg"] as Label).text = str(base_dmg)
	(_stat_vals["💥 Eff. Dmg"] as Label).text = str(eff_dmg)
	(_stat_vals["💰 Price"] as Label).text = "%dg" % price
	# Pure-effect elements deal no direct damage — hide both damage rows (not "0").
	((_stat_vals["⚔ Base Dmg"] as Label).get_parent() as Control).visible = not pure_effect
	((_stat_vals["💥 Eff. Dmg"] as Label).get_parent() as Control).visible = not pure_effect

	var element_id: String = element.get("element_id", element.get("id", "")) as String
	var description: String = AbilityData.get_ability(element_id).get("description", "") as String
	var new_text: String = _to_bbcode(description) if description != "" else "— none yet —"
	if description != "":
		# Surface the tier-scaled potency so the authored amounts don't understate combat.
		var note: String = ElementData.potency_note(tier, level)
		if note != "":
			new_text += "\n[color=#8a8aa0]%s[/color]" % note
	if new_text != _last_ability_text:
		_ability_rich.text = new_text
		_ability_rich.modulate = Color(0.82, 0.82, 0.9) if description != "" else Color(0.42, 0.42, 0.48)
		_last_ability_text = new_text

	_render_made_from(element_id)


# "Made from" recipe list (reverse lookup). Static per element, so it only rebuilds
# when the shown element changes — battle's per-frame live-refresh leaves it alone.
func _render_made_from(element_id: String) -> void:
	if element_id == _last_madefrom_id:
		return
	_last_madefrom_id = element_id
	for child: Node in _madefrom_box.get_children():
		child.queue_free()
	var made: Array[Dictionary] = RecipeData.recipes_for(element_id)
	if made.is_empty():
		return
	var header := Label.new()
	header.text = "MADE FROM"
	UIScale.apply(header, UIScale.TOOLTIP_SECTION)
	header.modulate = Color(0.55, 0.55, 0.62)
	_madefrom_box.add_child(header)
	for pair: Dictionary in made:
		var resolved: Dictionary = RecipeData.describe_pair(pair)
		if resolved.is_empty():
			continue
		var a: Dictionary = resolved["a"]
		var b: Dictionary = resolved["b"]
		var row := Label.new()
		row.text = "%s %s + %s %s" % [a["emoji"], a["name"], b["emoji"], b["name"]]
		row.autowrap_mode = TextServer.AUTOWRAP_WORD
		UIScale.apply(row, UIScale.TOOLTIP_STAT)
		row.modulate = Color(0.65, 0.9, 0.65)
		_madefrom_box.add_child(row)


# Turns [keyword] tags into hoverable links for keywords the glossary defines.
func _to_bbcode(description: String) -> String:
	var out: String = description
	for keyword: Variant in StatusGlossary.keywords():
		var k: String = keyword as String
		out = out.replace("[%s]" % k, "[url=%s][color=#8fd3ff]%s[/color][/url]" % [k, k])
	return out


# ── live refresh + shift-to-pin ───────────────────────────────────────────────

func _process(_delta: float) -> void:
	if not _panel.visible:
		return
	var shift_held: bool = Input.is_key_pressed(KEY_SHIFT)
	if shift_held and not _pinned:
		_pinned = true  # freeze in place so the player can reach the keywords
	elif _pinned and not shift_held:
		_pinned = false
		_force_hide()  # releasing Shift dismisses the pinned card
		return

	if _battle_side != "":
		_refresh_live()
	if not _pinned:
		_update_position()


func _refresh_live() -> void:
	var state: Dictionary = GameManager.state
	var grid: Array = CombatSide.grid(state, _battle_side)
	if _battle_slot < 0 or _battle_slot >= grid.size() or grid[_battle_slot] == null:
		return
	_render(grid[_battle_slot] as Dictionary, CombatSide.statuses(state, _battle_side))


func _on_keyword_hover(meta: Variant) -> void:
	var definition: String = StatusGlossary.get_definition(str(meta))
	if definition == "":
		return
	_glossary_lbl.text = "%s — %s" % [str(meta).capitalize(), definition]
	_glossary_panel.visible = true
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var pos: Vector2 = mouse_pos + Vector2(14, 14)
	pos.x = minf(pos.x, vp_size.x - _glossary_panel.size.x - 8.0)
	pos.y = minf(pos.y, vp_size.y - _glossary_panel.size.y - 8.0)
	_glossary_panel.position = pos


func _on_keyword_unhover(_meta: Variant) -> void:
	_glossary_panel.visible = false


func _update_position() -> void:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var panel_size: Vector2 = _panel.size
	var x: float = mouse_pos.x + 16.0
	var y: float = mouse_pos.y + 8.0
	if x + panel_size.x > vp_size.x - 8.0:
		x = mouse_pos.x - panel_size.x - 16.0
	y = clampf(y, 0.0, maxf(0.0, vp_size.y - panel_size.y))
	_panel.position = Vector2(x, y)
