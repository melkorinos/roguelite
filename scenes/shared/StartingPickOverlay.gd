class_name StartingPickOverlay
extends CanvasLayer

# Run-start choice overlay: shows the three Starting Pick options and emits the
# chosen element's id. Logic lives in StartSystem; this is render + input only.

signal picked(element_id: String)

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
	title.text = "Choose your starting element  (2× damage)"
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
		var elem: Dictionary = opt as Dictionary
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(150, 110)
		btn.text = "%s\n%s\n2× DMG" % [elem["emoji"] as String, elem["name"] as String]
		var id: String = elem["id"] as String
		btn.pressed.connect(func() -> void: emit_signal("picked", id))
		_options_row.add_child(btn)
	visible = true


func hide_overlay() -> void:
	visible = false
