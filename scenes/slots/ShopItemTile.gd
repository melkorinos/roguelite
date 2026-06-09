class_name ShopItemTile
extends ElementCard

# A shop FOR-SALE tile. Inherits the Element Card visual + hover→tooltip behavior
# from ElementCard; adds the price line (via show_price), click-to-buy, and drag
# as a "shop" source. Suppresses the tooltip while a drag is in progress.

signal buy_pressed(element_id: String, shop_slot: int)

const SIZE := Vector2(143, 143)

var shop_slot_index: int = -1

var _price: int = 0
var _drag_started: bool = false


func _ready() -> void:
	show_price = true
	center_content = true
	emoji_size = UIScale.SHOP_EMOJI
	name_size = UIScale.SHOP_LABEL
	price_size = UIScale.SHOP_LABEL
	empty_bg = ThemeData.SLOT_BG_EMPTY
	empty_border = ThemeData.SLOT_BORDER_EMPTY
	super._ready()
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP


func setup(elem: Dictionary, gold: int, slot: int = -1) -> void:
	shop_slot_index = slot
	_price = elem["price"] as int
	render(elem)
	modulate = Color.WHITE if gold >= _price else Color(0.5, 0.5, 0.5, 0.8)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		_drag_started = true
		suppress_hover()
	elif what == NOTIFICATION_DRAG_END:
		_drag_started = false
		resume_hover()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mbe: InputEventMouseButton = event as InputEventMouseButton
		if mbe.button_index == MOUSE_BUTTON_LEFT and not mbe.pressed:
			if not _drag_started:
				accept_event()
				buy_pressed.emit(element_id, shop_slot_index)


func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview := Label.new()
	preview.text = emoji
	UIScale.apply(preview, UIScale.DRAG_SHOP)
	set_drag_preview(preview)
	return {"type": "shop", "element_id": element_id, "price": _price, "shop_slot": shop_slot_index}


# Inventory slots accept "shop" drops; the InventorySlot emits the buy signal.
# ShopItemTile itself rejects drops so they bubble to the SellZone.
func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	return false
