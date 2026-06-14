extends Control

const TIER_NAMES: Dictionary = {
	1: "Tier 1 — Basics",
	2: "Tier 2 — Combinations",
	3: "Tier 3 — Compounded",
	4: "Tier 4 — Phenomena",
}

var _accent: Color = ThemeData.AREA_COMPENDIUM
var _frame: ScenePanel = null
var _glossary: GlossaryPopup = null

func _ready() -> void:
	_apply_theme()
	_glossary = GlossaryPopup.new()
	add_child(_glossary)

	# A TabBar between the header and the framed content switches the view between the
	# element roster and the Keystone (Starting Pick) roster.
	var tabs := TabBar.new()
	tabs.add_tab("Elements")
	tabs.add_tab("Keystones")
	tabs.tab_changed.connect(_on_tab_changed)
	var vbox: VBoxContainer = $VBoxContainer
	vbox.add_child(tabs)
	vbox.move_child(tabs, 2)  # after Header(0) + HSeparator(1), before the frame
	_style_tabs(tabs)

	# Wrap the scrolling content in the shared beveled frame (compendium teal accent).
	# Content nodes are reparented into the panel body so the scroll survives.
	_frame = ScenePanel.new()
	_frame.setup("ELEMENTS", "📚", _accent)
	_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_frame)
	vbox.move_child(_frame, 3)
	($VBoxContainer/ScrollContainer as ScrollContainer).reparent(_frame.body())

	_render_tab(0)


func _apply_theme() -> void:
	var vbox: VBoxContainer = $VBoxContainer
	# Inset the content off the screen edges and give the column a consistent rhythm.
	vbox.offset_left = 32.0
	vbox.offset_top = 24.0
	vbox.offset_right = -32.0
	vbox.offset_bottom = -32.0
	vbox.add_theme_constant_override("separation", LayoutData.PANEL_GAP)
	($VBoxContainer/HSeparator as HSeparator).visible = false  # framing replaces separators

	($VBoxContainer/Header/Title as Label).add_theme_color_override("font_color", _accent.lightened(0.35))
	var back: Button = $VBoxContainer/Header/BackButton
	UIStyle.accent_button(back, _accent)


func _style_tabs(tabs: TabBar) -> void:
	var sel := StyleBoxFlat.new()
	sel.bg_color = _accent.darkened(0.68)
	sel.set_border_width_all(1)
	sel.border_color = _accent
	sel.set_corner_radius_all(4)
	sel.set_content_margin_all(6)
	tabs.add_theme_stylebox_override("tab_selected", sel)
	var unsel := StyleBoxFlat.new()
	unsel.bg_color = ThemeData.PANEL_INTERIOR
	unsel.set_corner_radius_all(4)
	unsel.set_content_margin_all(6)
	tabs.add_theme_stylebox_override("tab_unselected", unsel)
	tabs.add_theme_stylebox_override("tab_hovered", unsel)
	tabs.add_theme_color_override("font_selected_color", _accent.lightened(0.4))
	tabs.add_theme_color_override("font_unselected_color", ThemeData.COLOR_SUBTITLE)


func _on_back_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file(GameManager.compendium_return_scene)


func _on_tab_changed(index: int) -> void:
	_render_tab(index)


func _render_tab(index: int) -> void:
	var root: Node = _frame.body().get_node("ScrollContainer/CompendiumContent")
	for child: Node in root.get_children():
		root.remove_child(child)
		child.queue_free()
	if index == 1:
		_frame.setup("KEYSTONES", "🔮", _accent)
		_build_keystones(root)
	else:
		_frame.setup("ELEMENTS", "📚", _accent)
		_build_elements(root)


# Element roster — the real in-game ElementCard, one per element, grouped by tier.
# (Recipe / "made from" display on the card is a deferred feature; not shown here yet.)
func _build_elements(root: Node) -> void:
	var current_tier: int = 0
	var current_grid: GridContainer = null

	for elem: Dictionary in ElementData.all_elements():
		var tier: int = elem["tier"] as int
		if tier != current_tier:
			current_tier = tier
			var header := Label.new()
			header.text = TIER_NAMES.get(tier, "Tier %d" % tier) as String
			UIScale.apply(header, UIScale.COMP_HEADER)
			header.add_theme_color_override("font_color", ThemeData.comp_tier_color(tier))
			root.add_child(header)
			current_grid = GridContainer.new()
			current_grid.columns = 8
			current_grid.add_theme_constant_override("h_separation", LayoutData.GRID_CELL_GAP)
			current_grid.add_theme_constant_override("v_separation", LayoutData.GRID_CELL_GAP)
			root.add_child(current_grid)

		var card := ElementCard.new()
		card.card_width = LayoutData.CARD_COMPENDIUM
		card.keywords_interactive = true  # non-draggable, so the ability keywords are live
		current_grid.add_child(card)
		card.render(elem)
		card.keyword_hovered.connect(func(keyword: String) -> void: _glossary.show_keyword(keyword))
		card.keyword_unhovered.connect(func() -> void: _glossary.hide_popup())


# ── Keystones tab (Starting Pick roster, ADR 0016) ────────────────────────────

func _build_keystones(root: Node) -> void:
	var header := Label.new()
	header.text = "Keystones — the Starting Pick"
	UIScale.apply(header, UIScale.COMP_HEADER)
	header.add_theme_color_override("font_color", _accent.lightened(0.3))
	root.add_child(header)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", LayoutData.GRID_CELL_GAP)
	grid.add_theme_constant_override("v_separation", LayoutData.GRID_CELL_GAP)
	root.add_child(grid)

	for keystone: Dictionary in KeystoneData.all():
		grid.add_child(_make_keystone_card(keystone))


func _make_keystone_card(keystone: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(LayoutData.CARD_COMPENDIUM, 0)
	card.add_theme_stylebox_override("panel", UIStyle.dialog_card(_accent))

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
