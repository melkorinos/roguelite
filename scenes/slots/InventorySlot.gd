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
	_apply_base_style()


func _apply_base_style() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = ThemeData.SLOT_BG_EMPTY
	normal.set_border_width_all(2)
	normal.border_color = ThemeData.SLOT_BORDER_EMPTY
	normal.set_corner_radius_all(6)
	add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = ThemeData.SLOT_BG_EMPTY.lightened(0.07)
	hover.set_border_width_all(2)
	hover.border_color = ThemeData.SLOT_BORDER_EMPTY.lightened(0.25)
	hover.set_corner_radius_all(6)
	add_theme_stylebox_override("hover", hover)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = ThemeData.SLOT_BG_EMPTY.darkened(0.10)
	pressed_style.set_border_width_all(2)
	pressed_style.border_color = ThemeData.SLOT_BORDER_EMPTY
	pressed_style.set_corner_radius_all(6)
	add_theme_stylebox_override("pressed", pressed_style)

	var focus_style := StyleBoxFlat.new()
	focus_style.bg_color = ThemeData.SLOT_BG_EMPTY
	focus_style.set_border_width_all(2)
	focus_style.border_color = ThemeData.SLOT_BORDER_EMPTY.lightened(0.35)
	focus_style.set_corner_radius_all(6)
	add_theme_stylebox_override("focus", focus_style)

	var disabled_style := StyleBoxFlat.new()
	disabled_style.bg_color = ThemeData.SLOT_BG_EMPTY.darkened(0.15)
	disabled_style.set_border_width_all(1)
	disabled_style.border_color = ThemeData.SLOT_BORDER_EMPTY.darkened(0.30)
	disabled_style.set_corner_radius_all(6)
	add_theme_stylebox_override("disabled", disabled_style)


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
	UIScale.apply(preview, UIScale.SLOT_EMOJI)
	set_drag_preview(preview)
	@warning_ignore("integer_division")
	drag_started.emit(element_id, slot_index, element_price / 2)
	return {"type": "inventory", "slot": slot_index}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return ShopSystem.can_drop(GameManager.state, data, {"zone": "inventory", "slot": slot_index})


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
