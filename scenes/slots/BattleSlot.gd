class_name BattleSlot
extends ElementCard

# A Battlegrid / battle-side slot. Inherits the Element Card visual + hover→tooltip
# behavior from ElementCard; adds the Charge Bar, drag-and-drop, the F-key
# quick-forge, and the fire animation.

signal slot_dropped(from_type: String, from_index: int, to_index: int)
signal drag_started(element_id: String, grid_slot: int, sell_price: int)
signal drag_ended()
signal forge_quick_slot_grid(grid_slot: int)

var slot_index: int = -1
var draggable: bool = true


func _ready() -> void:
	card_width = LayoutData.CARD_BATTLE
	show_charge = true
	name_with_level = true
	empty_glyph = "+"
	empty_bg = ThemeData.BATTLE_SLOT_BG_EMPTY
	empty_border = ThemeData.BATTLE_SLOT_BORDER_EMPTY
	super._ready()
	pivot_offset = custom_minimum_size / 2.0


func set_element(item: Variant) -> void:
	if item == null:
		clear()
		modulate = Color(0.6, 0.6, 0.6, 0.75)
		return
	render(item as Dictionary)
	modulate = Color.WHITE


func play_fire_animation() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.28, 1.28), 0.07)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.18)


func _unhandled_key_input(event: InputEvent) -> void:
	if not _hovered or not has_item or not draggable:
		return
	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and not ke.echo and ke.keycode == KEY_F:
			get_viewport().set_input_as_handled()
			forge_quick_slot_grid.emit(slot_index)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		drag_ended.emit()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not draggable or not has_item:
		return null
	@warning_ignore("integer_division")
	var sell_price: int = (_item.get("price", 0) as int) / 2
	var preview := Label.new()
	preview.text = emoji
	UIScale.apply(preview, UIScale.DRAG_SLOT)
	set_drag_preview(preview)
	drag_started.emit(element_id, slot_index, sell_price)
	return {"type": "grid", "slot": slot_index}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not draggable:
		return false
	return ShopSystem.can_drop(GameManager.state, data, {"zone": "grid", "slot": slot_index})


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var d: Dictionary = data
	var from_type: String = d["type"] as String
	var from_slot: int = d["shop_slot"] as int if from_type == "shop" else d["slot"] as int
	slot_dropped.emit(from_type, from_slot, slot_index)
