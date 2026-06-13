class_name StartingPickOverlay
extends CanvasLayer

# Run-start choice overlay (ADR 0016): shows the offered Keystones and emits the chosen
# one's id. Logic lives in StartSystem / KeystoneData; this is render + input only. The
# pick is a hard commit for the whole Run.

signal picked(keystone_id: String)

var _options_row: HBoxContainer


func _ready() -> void:
	layer = 115  # above the Pause overlay (110)
	_build_ui()
	visible = false


func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.color = Color(0.0, 0.0, 0.0, 0.7)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.13, 0.98)
	style.set_border_width_all(1)
	style.border_color = Color(0.45, 0.45, 0.65, 0.9)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Choose your Keystone — one pick, the whole run"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIScale.apply(title, UIScale.TOOLTIP_TITLE)
	title.modulate = Color(0.8, 0.8, 0.92)
	vbox.add_child(title)

	_options_row = HBoxContainer.new()
	_options_row.add_theme_constant_override("separation", 14)
	_options_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(_options_row)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	center.add_child(panel)


func show_options(options: Array) -> void:
	for child: Node in _options_row.get_children():
		child.queue_free()
	for opt: Variant in options:
		_options_row.add_child(_make_card(opt as Dictionary))
	visible = true


# A Keystone card: emoji + name, the axis/dimension tag chips, the upside description, the
# pact line (if any, tinted as a warning), and a Choose button that emits the pick.
func _make_card(keystone: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(210, 240)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.12, 0.12, 0.18, 1.0)
	card_style.set_border_width_all(1)
	card_style.border_color = Color(0.4, 0.4, 0.55, 0.8)
	card_style.set_corner_radius_all(6)
	card_style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", card_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = "%s  %s" % [keystone.get("emoji", "") as String, keystone.get("name", "") as String]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	UIScale.apply(name_lbl, UIScale.TOOLTIP_TITLE)
	vbox.add_child(name_lbl)

	var tags_lbl := Label.new()
	tags_lbl.text = " · ".join(PackedStringArray(keystone.get("tags", []) as Array))
	tags_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tags_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	UIScale.apply(tags_lbl, UIScale.TOOLTIP_BODY)
	tags_lbl.modulate = Color(0.6, 0.75, 0.95)
	vbox.add_child(tags_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = keystone.get("description", "") as String
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UIScale.apply(desc_lbl, UIScale.TOOLTIP_BODY)
	desc_lbl.modulate = Color(0.85, 0.9, 0.85)
	vbox.add_child(desc_lbl)

	var pact: String = keystone.get("pact", "") as String
	if pact != "":
		var pact_lbl := Label.new()
		pact_lbl.text = "Pact: %s" % pact
		pact_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pact_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		UIScale.apply(pact_lbl, UIScale.TOOLTIP_BODY)
		pact_lbl.modulate = Color(0.95, 0.55, 0.5)
		vbox.add_child(pact_lbl)

	var choose_btn := Button.new()
	choose_btn.text = "Choose"
	var id: String = keystone.get("id", "") as String
	choose_btn.pressed.connect(func() -> void: emit_signal("picked", id))
	vbox.add_child(choose_btn)

	return card


func hide_overlay() -> void:
	visible = false
