class_name ForgeSlot
extends ElementCard

# A Forge bench slot. Now renders the same Element Card as the shop / inventory / battle
# board (ADR-0017) instead of a bespoke emoji+name tile, so the bench reads identically
# to everywhere else. Layers the bench interaction on top: accept an "inventory" drop,
# and click to pull the item back out. No hover tooltip (the card self-describes).

signal item_placed(forge_slot_index: int, from_inv_index: int)
signal item_removed(forge_slot_index: int)

var forge_slot_index: int = -1


func _ready() -> void:
	card_width = LayoutData.CARD_FORGE
	name_with_level = true
	empty_glyph = "?"
	empty_bg = ThemeData.SLOT_BG_EMPTY
	empty_border = ThemeData.SLOT_BORDER_EMPTY
	super._ready()
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_item(item: Variant) -> void:
	if item == null:
		clear()
		modulate = Color(0.65, 0.65, 0.65, 0.75)
		return
	render(item as Dictionary)
	modulate = Color.WHITE


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mbe := event as InputEventMouseButton
		if mbe.button_index == MOUSE_BUTTON_LEFT and not mbe.pressed and has_item:
			accept_event()
			item_removed.emit(forge_slot_index)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false
	return (data as Dictionary).get("type", "") == "inventory"


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	item_placed.emit(forge_slot_index, (data as Dictionary)["slot"] as int)
