class_name InventorySlot
extends Button

signal slot_dropped(from_type: String, from_index: int, to_index: int)
signal shop_buy_upgrade_requested(element_id: String, to_inv_index: int, shop_slot: int)
signal shop_buy_to_slot_requested(element_id: String, to_inv_index: int, shop_slot: int)
signal drag_started(element_id: String, inv_slot: int, sell_price: int)
signal drag_ended()
signal forge_quick_slot(slot_index: int)
signal tooltip_requested(element: Dictionary)
signal tooltip_hide_requested()

var slot_index: int = -1
var has_item: bool = false
var element_id: String = ""
var element_level: int = 0
var element_price: int = 0
var item_dict: Dictionary = {}

var _hovered: bool = false
var _hover_timer: Timer


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_hover_timer = Timer.new()
	_hover_timer.wait_time = 0.3
	_hover_timer.one_shot = true
	add_child(_hover_timer)
	_hover_timer.timeout.connect(_on_hover_timeout)


func _on_mouse_entered() -> void:
	_hovered = true
	if has_item:
		_hover_timer.start()


func _on_mouse_exited() -> void:
	_hovered = false
	_hover_timer.stop()
	tooltip_hide_requested.emit()


func _on_hover_timeout() -> void:
	if has_item:
		tooltip_requested.emit(item_dict)


func _unhandled_key_input(event: InputEvent) -> void:
	if not _hovered or not has_item:
		return
	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and not ke.echo and ke.keycode == KEY_F:
			get_viewport().set_input_as_handled()
			forge_quick_slot.emit(slot_index)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		drag_ended.emit()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not has_item:
		return null
	var preview := Label.new()
	preview.text = text.split("\n")[0]
	preview.add_theme_font_size_override("font_size", 40)
	set_drag_preview(preview)
	@warning_ignore("integer_division")
	drag_started.emit(element_id, slot_index, element_price / 2)
	return {"type": "inventory", "slot": slot_index}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var d: Dictionary = data as Dictionary
	if not d.has("type"):
		return false

	if d["type"] == "inventory":
		# Only level-up: same element, same level, different slot.
		if not has_item:
			return false
		if (d["slot"] as int) == slot_index:
			return false
		var inv: Array = GameManager.state["inventory"]
		var from_item: Variant = inv[d["slot"] as int]
		if from_item == null:
			return false
		var from_elem: Dictionary = from_item as Dictionary
		if from_elem["element_id"] != element_id:
			return false
		return (from_elem["level"] as int) == element_level

	if d["type"] == "shop":
		if not has_item:
			# Plain buy: just need enough gold.
			return (GameManager.state["gold"] as int) >= (d["price"] as int)
		# Buy + level-up: same element, slot must be level 1 (shop items are always level 1).
		if (d["element_id"] as String) != element_id:
			return false
		if element_level != 1:
			return false
		return (GameManager.state["gold"] as int) >= (d["price"] as int)

	if d["type"] == "grid":
		return true

	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var d: Dictionary = data as Dictionary
	if d["type"] == "shop":
		var shop_slot: int = d.get("shop_slot", -1) as int
		if has_item:
			shop_buy_upgrade_requested.emit(d["element_id"] as String, slot_index, shop_slot)
		else:
			shop_buy_to_slot_requested.emit(d["element_id"] as String, slot_index, shop_slot)
	else:
		slot_dropped.emit(d["type"] as String, d["slot"] as int, slot_index)
