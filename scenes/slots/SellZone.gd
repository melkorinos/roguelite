class_name SellZone
extends PanelContainer

signal sold(from_type: String, from_index: int)

var _hint_lbl: Label
var _base_style: StyleBoxFlat
var _hover_style: StyleBoxFlat


func _ready() -> void:
	_base_style = StyleBoxFlat.new()
	_base_style.bg_color = Color(0.1, 0.1, 0.14, 0.6)
	_base_style.set_border_width_all(1)
	_base_style.border_color = Color(0.35, 0.35, 0.45, 0.6)
	_base_style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", _base_style)

	_hover_style = StyleBoxFlat.new()
	_hover_style.bg_color = Color(0.1, 0.3, 0.12, 0.7)
	_hover_style.set_border_width_all(2)
	_hover_style.border_color = Color(0.2, 0.9, 0.3, 0.9)
	_hover_style.set_corner_radius_all(4)

	_hint_lbl = Label.new()
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint_lbl.add_theme_font_size_override("font_size", 20)
	_hint_lbl.modulate = Color(0.3, 1.0, 0.45, 0.95)
	_hint_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_lbl.visible = false
	add_child(_hint_lbl)


func show_hint(sell_price: int) -> void:
	_hint_lbl.text = "⬇  Sell: %dg" % sell_price
	_hint_lbl.visible = true
	add_theme_stylebox_override("panel", _hover_style)


func hide_hint() -> void:
	_hint_lbl.visible = false
	add_theme_stylebox_override("panel", _base_style)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var t: String = (data as Dictionary).get("type", "") as String
	return t == "inventory" or t == "grid"


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var d: Dictionary = data as Dictionary
	sold.emit(d["type"] as String, d["slot"] as int)
