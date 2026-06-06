class_name ElementCard
extends PanelContainer

# The always-visible Element Card (ADR-0005): one base that renders an element the
# same way in every slot context — shop tile and Battlegrid slot extend it. Owns
# the tier-styled panel, the emoji / name / (optional) price / (optional) Charge
# Bar visuals, and the shared 0.3 s hover → Item Tooltip behavior. Host slots add
# only what differs per context (drag, click, F-key) on top.
#
# Configuration is set by the subclass in its _ready() BEFORE calling super._ready()
# (Godot lifecycle: plain properties before the build), then the base builds the
# card from those flags.

signal tooltip_requested(element: Dictionary)
signal tooltip_hide_requested()

const HOVER_DELAY_SECONDS: float = 0.3

# ── configuration (set before super._ready()) ─────────────────────────────────
var show_charge: bool = false
var show_price: bool = false
var name_with_level: bool = false
var center_content: bool = false
var empty_glyph: String = "+"
var emoji_size: int = UIScale.SLOT_EMOJI
var name_size: int = UIScale.SLOT_NAME
var price_size: int = UIScale.SHOP_LABEL
var empty_bg: Color = ThemeData.SLOT_BG_EMPTY
var empty_border: Color = ThemeData.SLOT_BORDER_EMPTY

# ── live state ─────────────────────────────────────────────────────────────────
var has_item: bool = false
var element_id: String = ""
var emoji: String = ""

var _item: Dictionary = {}
var _hovered: bool = false
var _hover_suppressed: bool = false
var _hover_timer: Timer
var _style: StyleBoxFlat
var _charge_bar: ProgressBar
var _emoji_lbl: Label
var _name_lbl: Label
var _price_lbl: Label


func _ready() -> void:
	_style = StyleBoxFlat.new()
	_style.set_border_width_all(2)
	_style.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", _style)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if center_content:
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	if show_charge:
		# Charge Bar — fills 0→1 toward the next fire (Battlegrid context only).
		_charge_bar = ProgressBar.new()
		_charge_bar.min_value = 0.0
		_charge_bar.max_value = 1.0
		_charge_bar.value = 0.0
		_charge_bar.show_percentage = false
		_charge_bar.custom_minimum_size = Vector2(0, 8)
		_charge_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pb_bg := StyleBoxFlat.new()
		pb_bg.bg_color = ThemeData.BATTLE_PROGRESS_BG
		_charge_bar.add_theme_stylebox_override("background", pb_bg)
		var pb_fill := StyleBoxFlat.new()
		pb_fill.bg_color = ThemeData.BATTLE_PROGRESS_FILL
		_charge_bar.add_theme_stylebox_override("fill", pb_fill)
		vbox.add_child(_charge_bar)

	_emoji_lbl = Label.new()
	_emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_emoji_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_emoji_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_emoji_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIScale.apply(_emoji_lbl, emoji_size)
	vbox.add_child(_emoji_lbl)

	_name_lbl = Label.new()
	_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIScale.apply(_name_lbl, name_size)
	vbox.add_child(_name_lbl)

	if show_price:
		_price_lbl = Label.new()
		_price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_price_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UIScale.apply(_price_lbl, price_size)
		vbox.add_child(_price_lbl)

	add_child(vbox)

	_hover_timer = Timer.new()
	_hover_timer.wait_time = HOVER_DELAY_SECONDS
	_hover_timer.one_shot = true
	add_child(_hover_timer)
	_hover_timer.timeout.connect(_on_hover_timeout)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	clear()


# ── rendering ─────────────────────────────────────────────────────────────────

func render(element: Dictionary) -> void:
	_item = element.duplicate()
	has_item = true
	element_id = element.get("element_id", element.get("id", "")) as String
	emoji = element.get("emoji", "") as String
	_emoji_lbl.text = emoji
	if name_with_level:
		_name_lbl.text = "%s L%d" % [element.get("name", "") as String, element.get("level", 1) as int]
	else:
		_name_lbl.text = element.get("name", "") as String
	if _charge_bar != null:
		_charge_bar.value = 0.0
	if _price_lbl != null:
		_price_lbl.text = "%dg" % (element.get("price", 0) as int)
	var tier: int = element.get("tier", 1) as int
	_style.border_color = ThemeData.tier_border(tier)
	_style.bg_color = ThemeData.tier_bg(tier)


func clear() -> void:
	_item = {}
	has_item = false
	element_id = ""
	emoji = ""
	if _emoji_lbl != null:
		_emoji_lbl.text = empty_glyph
		_name_lbl.text = ""
	if _charge_bar != null:
		_charge_bar.value = 0.0
	if _price_lbl != null:
		_price_lbl.text = ""
	if _style != null:
		_style.border_color = empty_border
		_style.bg_color = empty_bg


func get_tier() -> int:
	return _item.get("tier", 1) as int if has_item else 1


# Charge Bar driver — clamped 0→1. No-op when the card has no charge bar.
func set_charge(ratio: float) -> void:
	if _charge_bar != null:
		_charge_bar.value = clampf(ratio, 0.0, 1.0)


# ── hover → Item Tooltip (shared behavior) ────────────────────────────────────

func _on_mouse_entered() -> void:
	_hovered = true
	if has_item and not _hover_suppressed:
		_hover_timer.start()


func _on_mouse_exited() -> void:
	_hovered = false
	_hover_timer.stop()
	tooltip_hide_requested.emit()


func _on_hover_timeout() -> void:
	if has_item:
		tooltip_requested.emit(_item)


# Drag-aware hosts call these so a tooltip never opens mid-drag.
func suppress_hover() -> void:
	_hover_suppressed = true
	_hover_timer.stop()
	tooltip_hide_requested.emit()


func resume_hover() -> void:
	_hover_suppressed = false
