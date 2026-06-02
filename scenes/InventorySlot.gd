class_name InventorySlot
extends Button

signal slot_dropped(from_index: int, to_index: int)

var slot_index: int = -1
var has_item: bool = false


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not has_item:
		return null
	var preview := Label.new()
	preview.text = text.split("\n")[0]
	preview.add_theme_font_size_override("font_size", 40)
	set_drag_preview(preview)
	return {"slot": slot_index}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false
	if not has_item:
		return false
	var d: Dictionary = data
	return d.has("slot") and (d["slot"] as int) != slot_index


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var d: Dictionary = data
	slot_dropped.emit(d["slot"] as int, slot_index)
