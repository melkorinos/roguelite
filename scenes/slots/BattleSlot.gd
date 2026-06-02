class_name BattleSlot
extends PanelContainer

signal slot_dropped(from_type: String, from_index: int, to_index: int)
signal drag_started(element_id: String, grid_slot: int, sell_price: int)
signal drag_ended()
signal tooltip_requested(element: Dictionary)
signal tooltip_hide_requested()

const SIZE := Vector2(120, 120)

var slot_index: int = -1
var has_item: bool = false
var draggable: bool = true
var element_id: String = ""

var _item_dict: Dictionary = {}
var _hover_timer: Timer
var _progress: ProgressBar
var _emoji_lbl: Label
var _name_lbl: Label
var _emoji_text: String = ""


func _ready() -> void:
	custom_minimum_size = SIZE
	pivot_offset = SIZE / 2.0
	_hover_timer = Timer.new()
	_hover_timer.wait_time = 0.3
	_hover_timer.one_shot = true
	add_child(_hover_timer)
	_hover_timer.timeout.connect(_on_hover_timeout)
	mouse_entered.connect(_on_mouse_entered_hover)
	mouse_exited.connect(_on_mouse_exited_hover)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 2)

	_progress = ProgressBar.new()
	_progress.min_value = 0.0
	_progress.max_value = 1.0
	_progress.value = 0.0
	_progress.show_percentage = false
	_progress.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(_progress)

	_emoji_lbl = Label.new()
	_emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_emoji_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIScale.apply(_emoji_lbl, UIScale.SLOT_EMOJI)
	_emoji_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_emoji_lbl)

	_name_lbl = Label.new()
	_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIScale.apply(_name_lbl, UIScale.SLOT_NAME)
	vbox.add_child(_name_lbl)

	add_child(vbox)
	_apply_empty()


func set_element(item: Variant) -> void:
	if item == null:
		_item_dict = {}
		_apply_empty()
		return
	_item_dict = (item as Dictionary).duplicate()
	has_item = true
	var elem: Dictionary = item as Dictionary
	element_id = elem.get("element_id", elem.get("id", "")) as String
	_emoji_text = elem["emoji"]
	_emoji_lbl.text = elem["emoji"]
	_name_lbl.text = "%s L%d" % [elem["name"], elem["level"] as int]
	_progress.value = 0.0
	modulate = Color.WHITE


func _apply_empty() -> void:
	has_item = false
	element_id = ""
	_emoji_text = ""
	_emoji_lbl.text = "+"
	_name_lbl.text = ""
	_progress.value = 0.0
	modulate = Color(0.55, 0.55, 0.55, 0.7)


func set_cooldown_progress(ratio: float) -> void:
	_progress.value = clampf(ratio, 0.0, 1.0)


func play_fire_animation() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.28, 1.28), 0.07)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.18)


func _on_mouse_entered_hover() -> void:
	if has_item:
		_hover_timer.start()


func _on_mouse_exited_hover() -> void:
	_hover_timer.stop()
	tooltip_hide_requested.emit()


func _on_hover_timeout() -> void:
	if has_item:
		tooltip_requested.emit(_item_dict)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		drag_ended.emit()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not draggable or not has_item:
		return null
	var grid: Array = GameManager.state["battle_grid"]
	var elem: Variant = grid[slot_index]
	var sell_price: int = 0
	if elem != null:
		@warning_ignore("integer_division")
		sell_price = (elem as Dictionary).get("price", 0) as int / 2
	var preview := Label.new()
	preview.text = _emoji_text
	UIScale.apply(preview, UIScale.DRAG_SLOT)
	set_drag_preview(preview)
	drag_started.emit(element_id, slot_index, sell_price)
	return {"type": "grid", "slot": slot_index}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not draggable:
		return false
	if not data is Dictionary:
		return false
	var d: Dictionary = data
	if not d.has("slot") or not d.has("type"):
		return false
	if d["type"] == "grid" and (d["slot"] as int) == slot_index:
		return false
	return true


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var d: Dictionary = data
	slot_dropped.emit(d["type"] as String, d["slot"] as int, slot_index)
