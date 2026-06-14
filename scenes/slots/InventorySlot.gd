class_name InventorySlot
extends ElementCard

# An inventory slot. Inherits the Element Card visual + hover→tooltip behavior from
# ElementCard (ADR-0017); layers inventory interaction on top: drag as an "inventory"
# source, accepting shop/inventory/grid drops, and the F-key quick-forge. The bespoke
# Button styling it used to carry is gone — the card styles itself from the element.

signal slot_dropped(from_type: String, from_index: int, to_index: int)
signal shop_buy_upgrade_requested(element_id: String, to_inv_index: int, shop_slot: int)
signal shop_buy_to_slot_requested(element_id: String, to_inv_index: int, shop_slot: int)
signal drag_started(element_id: String, inv_slot: int, sell_price: int)
signal drag_ended()
signal forge_quick_slot(slot_index: int)

var slot_index: int = -1


func _ready() -> void:
	card_width = LayoutData.CARD_INVENTORY
	empty_bg = ThemeData.SLOT_BG_EMPTY
	empty_border = ThemeData.SLOT_BORDER_EMPTY
	super._ready()
	mouse_filter = Control.MOUSE_FILTER_STOP


func _unhandled_key_input(event: InputEvent) -> void:
	if not _hovered or not has_item:
		return
	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and not ke.echo and ke.keycode == KEY_F:
			get_viewport().set_input_as_handled()
			forge_quick_slot.emit(slot_index)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		suppress_hover()
	elif what == NOTIFICATION_DRAG_END:
		resume_hover()
		drag_ended.emit()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not has_item:
		return null
	var preview := Label.new()
	preview.text = emoji
	UIScale.apply(preview, UIScale.DRAG_SLOT)
	set_drag_preview(preview)
	@warning_ignore("integer_division")
	var sell_price: int = (_item.get("price", 0) as int) / 2
	drag_started.emit(element_id, slot_index, sell_price)
	return DragLoc.inventory(slot_index)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return ShopSystem.can_drop(GameManager.state, data, {"zone": "inventory", "slot": slot_index})


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var d: Dictionary = data as Dictionary
	if d["zone"] == "shop":
		if has_item:
			shop_buy_upgrade_requested.emit(d["element_id"] as String, slot_index, d["slot"] as int)
		else:
			shop_buy_to_slot_requested.emit(d["element_id"] as String, slot_index, d["slot"] as int)
	else:
		slot_dropped.emit(d["zone"] as String, d["slot"] as int, slot_index)
