class_name SellZone
extends PanelContainer

signal sold(from_type: String, from_index: int)

var _hint_lbl: Label
var _base_style: StyleBoxFlat
var _hover_style: StyleBoxFlat


func _ready() -> void:
	# Resting: transparent — the wrapping ScenePanel supplies the frame. Only the
	# drag-hover state (below) paints, to signal "drop here to sell".
	_base_style = StyleBoxFlat.new()
	_base_style.bg_color = Color(0, 0, 0, 0)
	_base_style.set_border_width_all(0)
	add_theme_stylebox_override("panel", _base_style)

	_hover_style = StyleBoxFlat.new()
	_hover_style.bg_color = ThemeData.SELL_HOVER_BG
	_hover_style.set_border_width_all(2)
	_hover_style.border_color = ThemeData.SELL_HOVER_BORDER
	_hover_style.set_corner_radius_all(6)

	_hint_lbl = Label.new()
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIScale.apply(_hint_lbl, UIScale.SELL_HINT)
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
	var zone: String = (data as Dictionary).get("zone", "") as String
	return zone == "inventory" or zone == "grid"


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var d: Dictionary = data as Dictionary
	sold.emit(d["zone"] as String, d["slot"] as int)
