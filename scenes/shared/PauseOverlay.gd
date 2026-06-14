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
	dimmer.color = ThemeData.OVERLAY_DIMMER
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)

	var accent: Color = ThemeData.AREA_MENU

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(280, 0)
	_panel.add_theme_stylebox_override("panel", UIStyle.dialog_panel(accent))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIScale.apply(title, UIScale.TOOLTIP_TITLE)
	title.add_theme_color_override("font_color", accent.lightened(0.35))
	vbox.add_child(title)

	var resume_btn := _make_btn("▶  Resume", accent)
	vbox.add_child(resume_btn)
	resume_btn.pressed.connect(func() -> void: emit_signal("resumed"))

	var settings_btn := _make_btn("⚙  Settings", accent)
	vbox.add_child(settings_btn)
	settings_btn.pressed.connect(func() -> void: emit_signal("settings_requested"))

	# Forfeit is the destructive action — it reads in battle-red.
	var forfeit_btn := _make_btn("🏳  Forfeit Run", ThemeData.AREA_BATTLE)
	vbox.add_child(forfeit_btn)
	forfeit_btn.pressed.connect(func() -> void: emit_signal("forfeit_requested"))

	var menu_btn := _make_btn("🏠  Main Menu", accent)
	vbox.add_child(menu_btn)
	menu_btn.pressed.connect(func() -> void: emit_signal("quit_to_menu_requested"))

	var desktop_btn := _make_btn("✕  Quit to Desktop", accent)
	desktop_btn.modulate = ThemeData.UI_MUTED_TEXT
	vbox.add_child(desktop_btn)
	desktop_btn.pressed.connect(func() -> void: emit_signal("quit_to_desktop_requested"))

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	center.add_child(_panel)


func _make_btn(label: String, accent: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(240, 0)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	UIStyle.accent_button(btn, accent)
	return btn


func show_overlay() -> void:
	visible = true


func hide_overlay() -> void:
	visible = false


func is_open() -> bool:
	return visible
