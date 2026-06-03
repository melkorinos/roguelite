class_name PauseOverlay
extends CanvasLayer

signal resumed
signal settings_requested
signal quit_to_menu_requested
signal quit_to_desktop_requested
signal forfeit_requested

var _panel: PanelContainer


func _ready() -> void:
	layer = 110
	_build_ui()
	hide_overlay()


func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.color = Color(0.0, 0.0, 0.0, 0.55)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(260, 0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.13, 0.98)
	style.set_border_width_all(1)
	style.border_color = Color(0.45, 0.45, 0.65, 0.9)
	style.set_corner_radius_all(6)
	_panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIScale.apply(title, UIScale.TOOLTIP_TITLE)
	title.modulate = Color(0.75, 0.75, 0.85)
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var resume_btn := _make_btn("▶  Resume")
	vbox.add_child(resume_btn)
	resume_btn.pressed.connect(func() -> void: emit_signal("resumed"))

	var settings_btn := _make_btn("⚙  Settings")
	vbox.add_child(settings_btn)
	settings_btn.pressed.connect(func() -> void: emit_signal("settings_requested"))

	var forfeit_btn := _make_btn("🏳  Forfeit Run")
	forfeit_btn.modulate = Color(1.0, 0.6, 0.6)
	vbox.add_child(forfeit_btn)
	forfeit_btn.pressed.connect(func() -> void: emit_signal("forfeit_requested"))

	var menu_btn := _make_btn("🏠  Main Menu")
	vbox.add_child(menu_btn)
	menu_btn.pressed.connect(func() -> void: emit_signal("quit_to_menu_requested"))

	var desktop_btn := _make_btn("✕  Quit to Desktop")
	desktop_btn.modulate = Color(0.8, 0.8, 0.8)
	vbox.add_child(desktop_btn)
	desktop_btn.pressed.connect(func() -> void: emit_signal("quit_to_desktop_requested"))

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	center.add_child(_panel)


func _make_btn(label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(220, 0)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return btn


func show_overlay() -> void:
	visible = true


func hide_overlay() -> void:
	visible = false


func is_open() -> bool:
	return visible
