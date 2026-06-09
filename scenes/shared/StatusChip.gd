class_name StatusChip
extends PanelContainer

# One chip in the in-combat Status Tray: an emoji + a small stack-count badge, tinted by
# valence. Hovering shows a framed Status Readout (the plain-language, magnitude-filled
# text supplied by StatusSystem.describe). Render + input only — no game logic here.

var _count_label: Label


func setup(emoji: String, tint: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(tint.r, tint.g, tint.b, 0.18)
	style.set_border_width_all(1)
	style.border_color = Color(tint.r, tint.g, tint.b, 0.9)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(3)
	add_theme_stylebox_override("panel", style)
	mouse_filter = Control.MOUSE_FILTER_STOP  # receive hover so the readout shows

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 1)

	var emoji_label := Label.new()
	emoji_label.text = emoji
	emoji_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIScale.apply(emoji_label, UIScale.STATUS_CHIP)
	hbox.add_child(emoji_label)

	_count_label = Label.new()
	_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_count_label.modulate = ThemeData.STATUS_COUNT_TINT
	UIScale.apply(_count_label, UIScale.STATUS_COUNT)
	hbox.add_child(_count_label)

	add_child(hbox)


# `badge` is the stack-count beside the emoji ("" hides it); `readout` is the hover text.
func set_data(badge: String, readout: String) -> void:
	_count_label.text = badge
	_count_label.visible = badge != ""
	tooltip_text = readout


# Custom, framed hover popup — replaces Godot's plain default tooltip entirely.
func _make_custom_tooltip(for_text: String) -> Object:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeData.STATUS_READOUT_BG
	style.set_border_width_all(1)
	style.border_color = ThemeData.STATUS_READOUT_BORDER
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = for_text
	label.modulate = ThemeData.STATUS_READOUT_TEXT
	UIScale.apply(label, UIScale.TOOLTIP_BODY)
	panel.add_child(label)
	return panel
