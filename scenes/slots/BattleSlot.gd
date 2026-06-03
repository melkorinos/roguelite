class_name BattleSlot
extends PanelContainer

signal slot_dropped(from_type: String, from_index: int, to_index: int)
signal drag_started(element_id: String, grid_slot: int, sell_price: int)
signal drag_ended()
signal forge_quick_slot_grid(grid_slot: int)
signal tooltip_requested(element: Dictionary)
signal tooltip_hide_requested()

const SIZE := Vector2(120, 120)

var slot_index: int = -1
var has_item: bool = false
var draggable: bool = true
var element_id: String = ""

var _item_dict: Dictionary = {}
var _hovered: bool = false
var _hover_timer: Timer
var _progress: ProgressBar
var _emoji_lbl: Label
var _name_lbl: Label
var _emoji_text: String = ""
var _style: StyleBoxFlat


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

	_style = StyleBoxFlat.new()
	_style.set_border_width_all(2)
	_style.border_color = ThemeData.BATTLE_SLOT_BORDER_EMPTY
	_style.bg_color = ThemeData.BATTLE_SLOT_BG_EMPTY
	_style.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", _style)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 2)

	_progress = ProgressBar.new()
	_progress.min_value = 0.0
	_progress.max_value = 1.0
	_progress.value = 0.0
	_progress.show_percentage = false
	_progress.custom_minimum_size = Vector2(0, 8)
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = ThemeData.BATTLE_PROGRESS_BG
	_progress.add_theme_stylebox_override("background", pb_bg)
	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = ThemeData.BATTLE_PROGRESS_FILL
	_progress.add_theme_stylebox_override("fill", pb_fill)
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
	var tier: int = elem.get("tier", 1) as int
	_style.border_color = ThemeData.tier_border(tier)
	_style.bg_color = ThemeData.tier_bg(tier)


func _apply_empty() -> void:
	has_item = false
	element_id = ""
	_emoji_text = ""
	_emoji_lbl.text = "+"
	_name_lbl.text = ""
	_progress.value = 0.0
	modulate = Color(0.6, 0.6, 0.6, 0.75)
	if _style != null:
		_style.border_color = ThemeData.BATTLE_SLOT_BORDER_EMPTY
		_style.bg_color = ThemeData.BATTLE_SLOT_BG_EMPTY


func get_tier() -> int:
	return _item_dict.get("tier", 1) as int if has_item else 1


func set_cooldown_progress(ratio: float) -> void:
	_progress.value = clampf(ratio, 0.0, 1.0)


func play_fire_animation() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.28, 1.28), 0.07)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.18)


func _on_mouse_entered_hover() -> void:
	_hovered = true
	if has_item:
		_hover_timer.start()


func _on_mouse_exited_hover() -> void:
	_hovered = false
	_hover_timer.stop()
	tooltip_hide_requested.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if not _hovered or not has_item or not draggable:
		return
	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and not ke.echo and ke.keycode == KEY_F:
			get_viewport().set_input_as_handled()
			forge_quick_slot_grid.emit(slot_index)


func _on_hover_timeout() -> void:
	if has_item:
		tooltip_requested.emit(_item_dict)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		drag_ended.emit()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not draggable or not has_item:
		return null
	@warning_ignore("integer_division")
	var sell_price: int = _item_dict.get("price", 0) as int / 2
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
	if not d.has("type"):
		return false
	if d["type"] == "shop":
		var shop_slot: int = d.get("shop_slot", -1) as int
		return ShopSystem.can_transfer(GameManager.state, {"zone": "shop", "slot": shop_slot}, {"zone": "grid", "slot": slot_index})
	if not d.has("slot"):
		return false
	if d["type"] == "grid" and (d["slot"] as int) == slot_index:
		return false
	return true


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var d: Dictionary = data
	var from_type: String = d["type"] as String
	var from_slot: int = d["shop_slot"] as int if from_type == "shop" else d["slot"] as int
	slot_dropped.emit(from_type, from_slot, slot_index)
