class_name ForgeSlot
extends PanelContainer

signal item_placed(forge_slot_index: int, from_inv_index: int)
signal item_removed(forge_slot_index: int)
signal tooltip_requested(element: Dictionary)
signal tooltip_hide_requested()

const SIZE := Vector2(143, 143)

var forge_slot_index: int = -1
var has_item: bool = false

var _item_dict: Dictionary = {}
var _hover_timer: Timer
var _emoji_lbl: Label
var _name_lbl: Label
var _style: StyleBoxFlat


func _ready() -> void:
	custom_minimum_size = SIZE
	_hover_timer = Timer.new()
	_hover_timer.wait_time = 0.3
	_hover_timer.one_shot = true
	add_child(_hover_timer)
	_hover_timer.timeout.connect(_on_hover_timeout)
	mouse_entered.connect(_on_mouse_entered_hover)
	mouse_exited.connect(_on_mouse_exited_hover)

	_style = StyleBoxFlat.new()
	_style.set_border_width_all(2)
	_style.border_color = ThemeData.FORGE_SLOT_BORDER
	_style.bg_color = ThemeData.FORGE_SLOT_BG
	_style.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", _style)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	_emoji_lbl = Label.new()
	_emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_emoji_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIScale.apply(_emoji_lbl, UIScale.FORGE_EMOJI)
	_emoji_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_emoji_lbl)

	_name_lbl = Label.new()
	_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIScale.apply(_name_lbl, UIScale.SLOT_NAME)
	vbox.add_child(_name_lbl)

	add_child(vbox)
	_apply_empty()


func set_item(item: Variant) -> void:
	if item == null:
		_item_dict = {}
		_apply_empty()
		return
	_item_dict = (item as Dictionary).duplicate()
	has_item = true
	var elem: Dictionary = item as Dictionary
	_emoji_lbl.text = elem["emoji"]
	_name_lbl.text = "%s L%d" % [elem["name"], elem["level"] as int]
	# Show the item's own tier color in the bench (no more uniform forge purple).
	var tier: int = elem.get("tier", 1) as int
	_style.bg_color = ThemeData.tier_bg(tier)
	_style.border_color = ThemeData.tier_border(tier)
	modulate = Color.WHITE


func _apply_empty() -> void:
	has_item = false
	_emoji_lbl.text = "?"
	_name_lbl.text = "drop here"
	# Empty bench slot — neutral look (the tier color belongs to a real item).
	_style.bg_color = ThemeData.SLOT_BG_EMPTY
	_style.border_color = ThemeData.SLOT_BORDER_EMPTY
	modulate = Color(0.65, 0.65, 0.65, 0.75)


func _on_mouse_entered_hover() -> void:
	if has_item:
		_hover_timer.start()


func _on_mouse_exited_hover() -> void:
	_hover_timer.stop()
	tooltip_hide_requested.emit()


func _on_hover_timeout() -> void:
	if has_item:
		tooltip_requested.emit(_item_dict)


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
