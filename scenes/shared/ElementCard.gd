class_name ElementCard
extends PanelContainer

# The always-visible Element Card (ADR-0005 + ADR-0017): one base that renders an
# element identically in every slot context — shop tile, inventory slot, and
# Battlegrid slot extend it. Three independent visual axes:
#   • Hue   = Canonical Family  → portrait radial glow + name tint + lineage underbar
#   • Tier  = frame MATERIAL    → bronze / silver / gold metal, T4 prismatic ring
#   • Level = glow INTENSITY    → portrait brightness + glow radius (static, v1)
# Stat pods come from the tested ElementData.stat_pods() (SPEC §B pod rule). One
# scalable size param (card_width; height = width × 1.45) with graceful degradation
# by width band (SPEC §D): ability text hides first, then secondary pods.
#
# Configuration is set by the subclass in its _ready() BEFORE calling super._ready()
# (plain properties before the build), then the base builds the card from those flags.

signal tooltip_requested(element: Dictionary)
signal tooltip_hide_requested()

const HOVER_DELAY_SECONDS: float = 0.3
const HEIGHT_RATIO: float = 1.45          # card height = width × this
const PORTRAIT_RATIO: float = 0.42        # portrait height as a fraction of width
const ABILITY_MIN_WIDTH: int = 140        # below this the ability text moves to the tooltip
const SECONDARY_POD_MIN_WIDTH: int = 110  # below this only the Cooldown pod survives

# ── configuration (set before super._ready()) ─────────────────────────────────
var card_width: int = UIScale.CARD_REFERENCE_WIDTH
var show_charge: bool = false
var show_price: bool = false
var name_with_level: bool = false
var empty_glyph: String = "+"
var empty_bg: Color = ThemeData.SLOT_BG_EMPTY
var empty_border: Color = ThemeData.SLOT_BORDER_EMPTY

# ── live state ─────────────────────────────────────────────────────────────────
var has_item: bool = false
var element_id: String = ""
var emoji: String = ""

var _item: Dictionary = {}
var _scale: float = 1.0
var _hovered: bool = false
var _hover_suppressed: bool = false
var _hover_timer: Timer

# ── nodes ──────────────────────────────────────────────────────────────────────
var _frame_style: StyleBoxFlat            # T1–T3 metal ring (outer panel)
var _frame_prismatic: StyleBoxTexture     # T4 prismatic ring (outer panel)
var _inner_style: StyleBoxFlat            # dark interior panel
var _inner_panel: PanelContainer
var _charge_bar: ProgressBar
var _portrait: Control
var _glow_rect: TextureRect
var _emoji_lbl: Label
var _underbar: HBoxContainer
var _underbar_left: ColorRect
var _underbar_right: ColorRect
var _name_lbl: Label
var _stats_row: HBoxContainer
var _ability_rich: RichTextLabel
var _price_lbl: Label


func _ready() -> void:
	_scale = float(card_width) / float(UIScale.CARD_REFERENCE_WIDTH)
	custom_minimum_size = Vector2(card_width, roundi(card_width * HEIGHT_RATIO))

	# Outer panel = the tier frame. Prismatic texture is built once (T4 only).
	_frame_style = StyleBoxFlat.new()
	_frame_style.set_corner_radius_all(_px(6))
	_frame_prismatic = _build_prismatic_box()
	add_theme_stylebox_override("panel", _frame_style)

	# Inner panel = the dark interior the content sits on; frame shows as a ring via
	# the outer panel's content margins.
	_inner_panel = PanelContainer.new()
	_inner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inner_style = StyleBoxFlat.new()
	_inner_style.bg_color = Color(0.05, 0.035, 0.03, 1.0)
	_inner_style.set_corner_radius_all(_px(4))
	var pad: int = _px(7)
	_inner_style.set_content_margin_all(pad)
	_inner_panel.add_theme_stylebox_override("panel", _inner_style)
	add_child(_inner_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", _px(5))
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inner_panel.add_child(vbox)

	if show_charge:
		# Charge Bar — fills 0→1 toward the next fire (Battlegrid context only).
		_charge_bar = ProgressBar.new()
		_charge_bar.min_value = 0.0
		_charge_bar.max_value = 1.0
		_charge_bar.value = 0.0
		_charge_bar.show_percentage = false
		_charge_bar.custom_minimum_size = Vector2(0, _px(7))
		_charge_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pb_bg := StyleBoxFlat.new()
		pb_bg.bg_color = ThemeData.BATTLE_PROGRESS_BG
		_charge_bar.add_theme_stylebox_override("background", pb_bg)
		var pb_fill := StyleBoxFlat.new()
		pb_fill.bg_color = ThemeData.BATTLE_PROGRESS_FILL
		_charge_bar.add_theme_stylebox_override("fill", pb_fill)
		vbox.add_child(_charge_bar)

	# Portrait — radial family glow (GradientTexture2D) with the emoji on top.
	_portrait = Control.new()
	_portrait.custom_minimum_size = Vector2(0, roundi(card_width * PORTRAIT_RATIO))
	_portrait.clip_contents = true
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow_rect = TextureRect.new()
	_glow_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_glow_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_glow_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_glow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.add_child(_glow_rect)
	_emoji_lbl = Label.new()
	_emoji_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_emoji_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_emoji_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIScale.apply_scaled(_emoji_lbl, UIScale.CARD_EMOJI, _scale)
	_portrait.add_child(_emoji_lbl)
	vbox.add_child(_portrait)

	# Lineage underbar (split bar of the two parents' family hues) — T2+ only.
	_underbar = HBoxContainer.new()
	_underbar.add_theme_constant_override("separation", 0)
	_underbar.custom_minimum_size = Vector2(0, _px(3))
	_underbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_underbar_left = ColorRect.new()
	_underbar_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_underbar_right = ColorRect.new()
	_underbar_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_underbar.add_child(_underbar_left)
	_underbar.add_child(_underbar_right)
	vbox.add_child(_underbar)

	# Name (family-tinted).
	_name_lbl = Label.new()
	_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIScale.apply_scaled(_name_lbl, UIScale.CARD_NAME, _scale)
	vbox.add_child(_name_lbl)

	# Stat pods (1–3).
	_stats_row = HBoxContainer.new()
	_stats_row.add_theme_constant_override("separation", _px(5))
	_stats_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_stats_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_stats_row)

	# Ability text (trigger prefix + keyword links).
	_ability_rich = RichTextLabel.new()
	_ability_rich.bbcode_enabled = true
	_ability_rich.fit_content = true
	_ability_rich.autowrap_mode = TextServer.AUTOWRAP_WORD
	_ability_rich.scroll_active = false
	_ability_rich.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ability_rich.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIScale.apply_rich_scaled(_ability_rich, UIScale.CARD_ABILITY, _scale)
	vbox.add_child(_ability_rich)

	if show_price:
		_price_lbl = Label.new()
		_price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_price_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UIScale.apply_scaled(_price_lbl, UIScale.CARD_POD_LABEL, _scale)
		vbox.add_child(_price_lbl)

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
	var tier: int = element.get("tier", 1) as int
	var level: int = element.get("level", 1) as int
	var hue: Color = ThemeData.family_color(ElementData.canonical_family(element_id))

	# Frame = tier material.
	_apply_frame(tier)

	# Portrait glow = family hue, brightened by level.
	_emoji_lbl.text = emoji
	_glow_rect.texture = _build_glow(hue, level)

	# Lineage underbar (T2+) — the two parents' canonical-family hues, split.
	_apply_lineage(tier)

	# Name.
	if name_with_level:
		_name_lbl.text = "%s L%d" % [element.get("name", "") as String, level]
	else:
		_name_lbl.text = element.get("name", "") as String
	_name_lbl.add_theme_color_override("font_color", _brighten(hue, 1.35))

	# Stat pods (tested pod rule).
	_render_pods(ElementData.stat_pods(_item), hue)

	# Ability text — hidden below the ability width band (tooltip carries it then).
	_ability_rich.visible = card_width >= ABILITY_MIN_WIDTH
	if _ability_rich.visible:
		_ability_rich.text = _ability_bbcode(element_id)

	if _charge_bar != null:
		_charge_bar.value = 0.0
	if _price_lbl != null:
		_price_lbl.text = "%dg" % (element.get("price", 0) as int)


func clear() -> void:
	_item = {}
	has_item = false
	element_id = ""
	emoji = ""
	if _emoji_lbl != null:
		_emoji_lbl.text = empty_glyph
		_name_lbl.text = ""
		_glow_rect.texture = null
		_underbar.visible = false
		_ability_rich.text = ""
		_ability_rich.visible = false
		for child: Node in _stats_row.get_children():
			child.queue_free()
	if _charge_bar != null:
		_charge_bar.value = 0.0
	if _price_lbl != null:
		_price_lbl.text = ""
	if _frame_style != null:
		add_theme_stylebox_override("panel", _frame_style)
		_frame_style.bg_color = empty_border
		_inner_style.bg_color = empty_bg


func get_tier() -> int:
	return _item.get("tier", 1) as int if has_item else 1


# Charge Bar driver — clamped 0→1. No-op when the card has no charge bar.
func set_charge(ratio: float) -> void:
	if _charge_bar != null:
		_charge_bar.value = clampf(ratio, 0.0, 1.0)


# ── frame / portrait / lineage / pods builders ────────────────────────────────

# Tier frame: T1–T3 = metal ring (the outer panel's bg shows through its content
# margins); T4 = prismatic textured ring. Margins make the bg read as a border.
func _apply_frame(tier: int) -> void:
	var ring: int = _px(3)
	if tier >= 4:
		_frame_prismatic.set_content_margin_all(ring)
		add_theme_stylebox_override("panel", _frame_prismatic)
	else:
		_frame_style.bg_color = ThemeData.frame_metal(tier)
		_frame_style.set_content_margin_all(ring)
		add_theme_stylebox_override("panel", _frame_style)
	_inner_style.bg_color = Color(0.05, 0.035, 0.03, 1.0)


func _apply_lineage(tier: int) -> void:
	if tier < 2:
		_underbar.visible = false
		return
	var parents: Array[String] = _parent_families()
	if parents.size() < 2:
		_underbar.visible = false
		return
	_underbar.visible = card_width >= SECONDARY_POD_MIN_WIDTH
	_underbar_left.color = ThemeData.family_color(parents[0])
	_underbar_right.color = ThemeData.family_color(parents[1])


# The two parents' canonical families for the lineage bar, from the first recipe
# that forges this element. Empty when no recipe (base elements) or unknown.
func _parent_families() -> Array[String]:
	var recipes: Array[Dictionary] = RecipeData.recipes_for(element_id)
	if recipes.is_empty():
		return []
	var pair: Dictionary = recipes[0]
	var fam_a: String = ElementData.canonical_family(pair["a"] as String)
	var fam_b: String = ElementData.canonical_family(pair["b"] as String)
	if fam_a == "" or fam_b == "":
		return []
	return [fam_a, fam_b]


func _render_pods(pods: Array[Dictionary], hue: Color) -> void:
	for child: Node in _stats_row.get_children():
		child.queue_free()
	# Below the secondary-pod band only the Cooldown pod survives.
	var shown: Array[Dictionary] = pods
	if card_width < SECONDARY_POD_MIN_WIDTH and pods.size() > 1:
		shown = [pods[0]]
	var value_size: int = UIScale.CARD_POD_VALUE
	var label_size: int = UIScale.CARD_POD_LABEL
	if shown.size() == 1:
		value_size = UIScale.CARD_POD_VALUE_SOLO
	elif shown.size() >= 3:
		value_size = UIScale.CARD_POD_VALUE_TRIO
		label_size = UIScale.CARD_POD_LABEL_TRIO
	for pod: Dictionary in shown:
		_stats_row.add_child(_build_pod(pod, hue, value_size, label_size))


func _build_pod(pod: Dictionary, hue: Color, value_size: int, label_size: int) -> PanelContainer:
	var highlight: bool = pod.get("highlight", false) as bool
	var tint: Color = _brighten(hue, 1.5) if highlight else Color(0.91, 0.92, 0.95)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.45)
	style.set_corner_radius_all(_px(12))
	style.set_content_margin_all(_px(4))
	panel.add_theme_stylebox_override("panel", style)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var value := Label.new()
	value.text = pod.get("value", "") as String
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_color_override("font_color", tint)
	UIScale.apply_scaled(value, value_size, _scale)
	col.add_child(value)
	var label := Label.new()
	label.text = (pod.get("label", "") as String).to_upper()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", tint if highlight else Color(0.60, 0.61, 0.72))
	UIScale.apply_scaled(label, label_size, _scale)
	col.add_child(label)
	panel.add_child(col)
	return panel


# Ability bbcode: trigger prefix + the description with [keyword] glossary links.
# Mirrors TooltipCard's keyword transform so the two never drift on keyword set.
func _ability_bbcode(id: String) -> String:
	var ability: Dictionary = AbilityData.get_ability(id)
	var description: String = ability.get("description", "") as String
	if description == "":
		return ""
	var body: String = description
	for keyword: Variant in StatusGlossary.keywords():
		var k: String = keyword as String
		body = body.replace("[%s]" % k, "[url=%s][color=#8fd3ff]%s[/color][/url]" % [k, k])
	var trigger: String = AbilityData.trigger_label(ability)
	if trigger != "":
		return "[b][color=#8fd3ff]%s[/color][/b]  %s" % [trigger.to_upper(), body]
	return body


# ── helpers ────────────────────────────────────────────────────────────────────

# Pixel value scaled to this card's width, floored at 1 so thin elements never vanish.
func _px(reference: int) -> int:
	return maxi(1, roundi(float(reference) * _scale))


# Multiply an RGB toward white (clamped) — the SPEC's bright(hue, factor).
func _brighten(c: Color, factor: float) -> Color:
	return Color(minf(1.0, c.r * factor), minf(1.0, c.g * factor), minf(1.0, c.b * factor), 1.0)


# Radial family glow texture for the portrait; brighter and wider at higher Level.
func _build_glow(hue: Color, level: int) -> GradientTexture2D:
	var bright: float = ThemeData.level_bright(level)
	var core: Color = _brighten(hue, bright)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 0.82, 1.0])
	gradient.colors = PackedColorArray([
		Color(core.r, core.g, core.b, 0.55),
		Color(hue.r, hue.g, hue.b, 0.22),
		Color(0.047, 0.027, 0.020, 1.0),
		Color(0.047, 0.027, 0.020, 1.0),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.62)
	texture.fill_to = Vector2(0.5, 0.0)
	texture.width = 128
	texture.height = 96
	return texture


# T4 prismatic ring: the 6 family-spectrum stops baked into a linear gradient
# texture (static v1; animated conic motion is the deferred "card animations").
func _build_prismatic_box() -> StyleBoxTexture:
	var gradient := Gradient.new()
	var stops: Array[Color] = ThemeData.FRAME_PRISMATIC_STOPS
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for i: int in stops.size():
		offsets.append(float(i) / float(stops.size() - 1))
		colors.append(stops[i])
	gradient.offsets = offsets
	gradient.colors = colors
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(1.0, 1.0)
	texture.width = 64
	texture.height = 64
	var box := StyleBoxTexture.new()
	box.texture = texture
	return box


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
