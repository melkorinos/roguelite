class_name ShopItemTile
extends PanelContainer

signal buy_pressed(element_id: String, shop_slot: int)
signal tooltip_requested(element: Dictionary)
signal tooltip_hide_requested()

const SIZE := Vector2(110, 110)

var element_id: String = ""
var shop_slot_index: int = -1

var _price: int = 0
var _drag_started: bool = false
var _emoji_text: String = ""
var _elem_dict: Dictionary = {}
var _hover_timer: Timer
var _emoji_lbl: Label
var _name_lbl: Label
var _price_lbl: Label
var _style: StyleBoxFlat


func _ready() -> void:
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_hover_timer = Timer.new()
	_hover_timer.wait_time = 0.3
	_hover_timer.one_shot = true
	add_child(_hover_timer)
	_hover_timer.timeout.connect(_on_hover_timeout)
	mouse_entered.connect(_on_mouse_entered_hover)
	mouse_exited.connect(_on_mouse_exited_hover)

	_style = StyleBoxFlat.new()
	_style.set_border_width_all(2)
	_style.border_color = ThemeData.SLOT_BORDER_EMPTY
	_style.bg_color = ThemeData.SLOT_BG_EMPTY
	_style.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", _style)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	_emoji_lbl = Label.new()
	_emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_emoji_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIScale.apply(_emoji_lbl, UIScale.SHOP_EMOJI)
	_emoji_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_emoji_lbl)

	_name_lbl = Label.new()
	_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIScale.apply(_name_lbl, UIScale.SHOP_LABEL)
	vbox.add_child(_name_lbl)

	_price_lbl = Label.new()
	_price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIScale.apply(_price_lbl, UIScale.SHOP_LABEL)
	vbox.add_child(_price_lbl)

	add_child(vbox)


func setup(elem: Dictionary, gold: int, slot: int = -1) -> void:
	element_id = elem["id"]
	shop_slot_index = slot
	_price = elem["price"] as int
	_emoji_text = elem["emoji"]
	_elem_dict = elem.duplicate()
	_emoji_lbl.text = _emoji_text
	_name_lbl.text = elem["name"]
	_price_lbl.text = "%dg" % _price
	modulate = Color.WHITE if gold >= _price else Color(0.5, 0.5, 0.5, 0.8)
	var tier: int = elem.get("tier", 1) as int
	_style.border_color = ThemeData.tier_border(tier)
	_style.bg_color = ThemeData.tier_bg(tier)


func _on_mouse_entered_hover() -> void:
	if not _drag_started:
		_hover_timer.start()


func _on_mouse_exited_hover() -> void:
	_hover_timer.stop()
	tooltip_hide_requested.emit()


func _on_hover_timeout() -> void:
	tooltip_requested.emit(_elem_dict)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		_drag_started = true
		_hover_timer.stop()
		tooltip_hide_requested.emit()
	elif what == NOTIFICATION_DRAG_END:
		_drag_started = false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mbe: InputEventMouseButton = event as InputEventMouseButton
		if mbe.button_index == MOUSE_BUTTON_LEFT and not mbe.pressed:
			if not _drag_started:
				accept_event()
				buy_pressed.emit(element_id, shop_slot_index)


func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview := Label.new()
	preview.text = _emoji_text
	UIScale.apply(preview, UIScale.DRAG_SHOP)
	set_drag_preview(preview)
	return {"type": "shop", "element_id": element_id, "price": _price, "shop_slot": shop_slot_index}


# Inventory slots accept "shop" drops; the InventorySlot emits shop_buy_upgrade_requested.
# ShopItemTile itself does NOT need _can_drop_data — inventory drops should fall through
# to SellZone. Return false explicitly to ensure bubbling.
func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	return false
