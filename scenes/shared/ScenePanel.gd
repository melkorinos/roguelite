class_name ScenePanel
extends MarginContainer

# A beveled "hardware" panel — the shared frame language (spec-shop-frame-system).
# A thick raised-metal frame (one consistent top-left light source) + a stepped inner
# accent line, on a near-black interior. The frame is painted in _draw() (behind the
# content); content margins inset children past it. Header row (glyph + title + an
# optional right-aligned action chip) sits above a body container the scene fills.
#
# Usage: panel = ScenePanel.new(); parent.add_child(panel); panel.setup("FOR SALE","🛒",
# ThemeData.AREA_SHOP); panel.body().add_child(...); panel.set_action(some_chip)

var accent: Color = ThemeData.AREA_SHOP

var _title_text: String = ""
var _glyph: String = ""
var _title_lbl: Label
var _action_slot: HBoxContainer
var _body: VBoxContainer


func _ready() -> void:
	var pad: int = ThemeData.FRAME_THICKNESS + ThemeData.FRAME_STEP_GAP + 8
	add_theme_constant_override("margin_left", pad)
	add_theme_constant_override("margin_right", pad)
	add_theme_constant_override("margin_top", pad)
	add_theme_constant_override("margin_bottom", pad)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	add_child(col)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	col.add_child(header)

	_title_lbl = Label.new()
	UIScale.apply(_title_lbl, UIScale.PANEL_HEADER)
	header.add_child(_title_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_action_slot = HBoxContainer.new()
	_action_slot.add_theme_constant_override("separation", 6)
	header.add_child(_action_slot)

	_body = VBoxContainer.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 8)
	col.add_child(_body)

	resized.connect(queue_redraw)
	_refresh()


# Set the panel's title, header glyph, and area accent. Safe to call before or after _ready.
func setup(title: String, glyph: String, area_accent: Color) -> void:
	_title_text = title
	_glyph = glyph
	accent = area_accent
	_refresh()


# Drop a chip/button (Reroll, FIGHT, …) into the header's right-aligned action slot.
func set_action(node: Control) -> void:
	if _action_slot == null:
		return
	for child: Node in _action_slot.get_children():
		child.queue_free()
	_action_slot.add_child(node)


# The container the host scene fills with the area's content.
func body() -> VBoxContainer:
	return _body


func _refresh() -> void:
	if _title_lbl != null:
		_title_lbl.text = ("%s  %s" % [_glyph, _title_text]).strip_edges()
		_title_lbl.add_theme_color_override("font_color", accent.lightened(0.25))
	queue_redraw()


# Paints the frame: interior + thick accent border + rounding (one StyleBoxFlat), a
# raised bevel (top/left lightened, bottom/right darkened — consistent light source),
# and a stepped inner accent line.
func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)

	var box := StyleBoxFlat.new()
	box.bg_color = ThemeData.PANEL_INTERIOR
	box.set_border_width_all(ThemeData.FRAME_THICKNESS)
	box.border_color = accent
	box.set_corner_radius_all(ThemeData.FRAME_RADIUS)
	draw_style_box(box, rect)

	var t: float = float(ThemeData.FRAME_THICKNESS)
	var r: float = float(ThemeData.FRAME_RADIUS)
	var inset: float = t * 0.5
	var hi: Color = accent.lightened(ThemeData.FRAME_BEVEL_LIGHT)
	var lo: Color = accent.darkened(ThemeData.FRAME_BEVEL_DARK)
	var w: float = size.x
	var h: float = size.y
	# Bevel edges along the middle of the border band; stop short of corners so rounding reads clean.
	draw_line(Vector2(r, inset), Vector2(w - r, inset), hi, 2.0)            # top — lit
	draw_line(Vector2(inset, r), Vector2(inset, h - r), hi, 2.0)            # left — lit
	draw_line(Vector2(r, h - inset), Vector2(w - r, h - inset), lo, 2.0)    # bottom — shadow
	draw_line(Vector2(w - inset, r), Vector2(w - inset, h - r), lo, 2.0)    # right — shadow

	var step := StyleBoxFlat.new()
	step.draw_center = false
	step.set_border_width_all(2)
	step.border_color = Color(accent.r, accent.g, accent.b, ThemeData.FRAME_STEP_ALPHA)
	step.set_corner_radius_all(maxi(2, ThemeData.FRAME_RADIUS - ThemeData.FRAME_STEP_GAP))
	var gi: float = t + float(ThemeData.FRAME_STEP_GAP)
	draw_style_box(step, rect.grow(-gi))
