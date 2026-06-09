class_name EventOverlay
extends CanvasLayer

# Event choice overlay (ADR 0011): shows the three Event Rewards and emits the chosen
# reward dict. Logic lives in EventSystem; this is render + input only. Mirrors
# StartingPickOverlay — a blocking, dimmed modal shown in the Shop.

signal chosen(reward: Dictionary)

var _options_row: HBoxContainer


func _ready() -> void:
	layer = 115  # above the Pause overlay (110), matching StartingPickOverlay
	_build_ui()
	visible = false


func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.color = ThemeData.EVENT_DIMMER
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeData.EVENT_PANEL_BG
	style.set_border_width_all(1)
	style.border_color = ThemeData.EVENT_PANEL_BORDER
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Choose a reward"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIScale.apply(title, UIScale.EVENT_TITLE)
	title.modulate = ThemeData.EVENT_TITLE_COLOR
	vbox.add_child(title)

	_options_row = HBoxContainer.new()
	_options_row.add_theme_constant_override("separation", 14)
	_options_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(_options_row)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	center.add_child(panel)


func show_rewards(rewards: Array) -> void:
	for child: Node in _options_row.get_children():
		child.queue_free()
	for reward_v: Variant in rewards:
		_options_row.add_child(_make_reward_card(reward_v as Dictionary))
	visible = true


func hide_overlay() -> void:
	visible = false


func _make_reward_card(reward: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(190, 132)
	btn.add_theme_stylebox_override("normal", _card_style(ThemeData.EVENT_REWARD_BG))
	btn.add_theme_stylebox_override("hover", _card_style(ThemeData.EVENT_REWARD_BG_HOVER))
	btn.add_theme_stylebox_override("pressed", _card_style(ThemeData.EVENT_REWARD_BG_HOVER))
	btn.add_theme_stylebox_override("focus", _card_style(ThemeData.EVENT_REWARD_BG_HOVER))

	# Stacked label + description; children ignore the mouse so the Button gets the click.
	var card_margin := MarginContainer.new()
	card_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right", "top", "bottom"]:
		card_margin.add_theme_constant_override("margin_" + side, 10)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = reward.get("label", "") as String
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIScale.apply(label, UIScale.EVENT_REWARD_LABEL)
	label.modulate = ThemeData.EVENT_REWARD_LABEL_COLOR

	var desc := Label.new()
	desc.text = reward.get("description", "") as String
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIScale.apply(desc, UIScale.EVENT_REWARD_DESC)
	desc.modulate = ThemeData.EVENT_REWARD_DESC_COLOR

	vbox.add_child(label)
	vbox.add_child(desc)
	card_margin.add_child(vbox)
	btn.add_child(card_margin)
	btn.pressed.connect(func() -> void: emit_signal("chosen", reward))
	return btn


func _card_style(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(1)
	sb.border_color = ThemeData.EVENT_REWARD_BORDER
	sb.set_corner_radius_all(6)
	return sb
