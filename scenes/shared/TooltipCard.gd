class_name TooltipCard
extends CanvasLayer

var _panel: PanelContainer
var _name_lbl: Label
var _stat_vals: Dictionary = {}


func _ready() -> void:
	layer = 100
	_build_ui()


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(210, 0)
	_panel.visible = false

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
	_name_lbl.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_name_lbl)

	var stats_sep := HSeparator.new()
	vbox.add_child(stats_sep)

	var stat_keys: Array[String] = ["Tier", "Level", "Cooldown", "Base Dmg", "Eff. Dmg", "Price"]
	for key: String in stat_keys:
		var row := HBoxContainer.new()
		var k_lbl := Label.new()
		k_lbl.text = key
		k_lbl.add_theme_font_size_override("font_size", 13)
		k_lbl.modulate = Color(0.72, 0.72, 0.78)
		k_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(k_lbl)
		var v_lbl := Label.new()
		v_lbl.add_theme_font_size_override("font_size", 13)
		v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(v_lbl)
		_stat_vals[key] = v_lbl
		vbox.add_child(row)

	var ab_sep := HSeparator.new()
	vbox.add_child(ab_sep)

	var ab_header := Label.new()
	ab_header.text = "ABILITIES"
	ab_header.add_theme_font_size_override("font_size", 11)
	ab_header.modulate = Color(0.55, 0.55, 0.62)
	vbox.add_child(ab_header)

	var ab_lbl := Label.new()
	ab_lbl.text = "— none yet —"
	ab_lbl.add_theme_font_size_override("font_size", 12)
	ab_lbl.modulate = Color(0.42, 0.42, 0.48)
	vbox.add_child(ab_lbl)

	add_child(_panel)


func show_for(element: Dictionary) -> void:
	var emoji: String = element.get("emoji", "") as String
	var name: String = element.get("name", "") as String
	var tier: int = element.get("tier", 1) as int
	var level: int = element.get("level", 1) as int
	var cooldown: float = element.get("cooldown", 0.0) as float
	var base_dmg: int = element.get("damage", 0) as int
	var eff_dmg: int = base_dmg * level + tier
	var price: int = element.get("price", 0) as int

	_name_lbl.text = "%s  %s" % [emoji, name]
	(_stat_vals["Tier"] as Label).text = "T%d" % tier
	(_stat_vals["Level"] as Label).text = "Lv%d" % level
	(_stat_vals["Cooldown"] as Label).text = "%.1fs" % cooldown
	(_stat_vals["Base Dmg"] as Label).text = str(base_dmg)
	(_stat_vals["Eff. Dmg"] as Label).text = str(eff_dmg)
	(_stat_vals["Price"] as Label).text = "%dg" % price

	_panel.visible = true
	_update_position()


func hide_card() -> void:
	_panel.visible = false


func _process(_delta: float) -> void:
	if _panel.visible:
		_update_position()


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
