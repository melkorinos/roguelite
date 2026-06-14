class_name GlossaryPopup
extends CanvasLayer

# The Keyword Popup — a small floating definition card for the [keyword] tags in an
# element's ability text (burn, poison, …). Shown only from non-draggable contexts
# (Compendium cards, the forge CardPreview) where hovering a keyword link is safe.
# Styled from the shared tokens (UIStyle.dialog_panel) so it matches the new theme.

const POPUP_WIDTH: float = 230.0

var _panel: PanelContainer
var _label: Label


func _ready() -> void:
	layer = 130  # above card previews
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(POPUP_WIDTH, 0)
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel", UIStyle.dialog_panel(ThemeData.AREA_HELP))

	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.custom_minimum_size = Vector2(POPUP_WIDTH - 36.0, 0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIScale.apply(_label, UIScale.TOOLTIP_BODY)
	_label.add_theme_color_override("font_color", ThemeData.AREA_HELP.lightened(0.45))
	_panel.add_child(_label)

	add_child(_panel)


# Show the definition for a keyword near the mouse; no-op for an unknown keyword.
func show_keyword(keyword: String) -> void:
	var definition: String = StatusGlossary.get_definition(keyword)
	if definition == "":
		return
	_label.text = "%s — %s" % [keyword.capitalize(), definition]
	_panel.visible = true
	_reposition()


func hide_popup() -> void:
	_panel.visible = false


func _reposition() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var pos: Vector2 = mouse + Vector2(14, 16)
	pos.x = minf(pos.x, vp.x - _panel.size.x - 8.0)
	pos.y = minf(pos.y, vp.y - _panel.size.y - 8.0)
	_panel.position = pos
