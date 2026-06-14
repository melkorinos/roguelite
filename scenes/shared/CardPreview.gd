class_name CardPreview
extends CanvasLayer

# A floating ElementCard preview, shown when the player hovers a non-draggable element
# reference (the forge "forge paths" chips). It renders the SAME ElementCard used in the
# shop/inventory/battle — no bespoke layout — and makes its [keyword] links live via a
# hosted GlossaryPopup. After the trigger releases, the preview stays up as long as the
# mouse is still over the card rect (a short timer polls), so the keyword links inside the
# card — which would otherwise steal the card's mouse_exit — remain reachable.

const HIDE_GRACE_SECONDS: float = 0.18

var _card: ElementCard
var _glossary: GlossaryPopup
var _hide_timer: Timer


func _ready() -> void:
	layer = 120

	_card = ElementCard.new()
	_card.card_width = LayoutData.CARD_PREVIEW
	_card.keywords_interactive = true
	_card.visible = false
	add_child(_card)
	_card.keyword_hovered.connect(func(keyword: String) -> void: _glossary.show_keyword(keyword))
	_card.keyword_unhovered.connect(func() -> void: _glossary.hide_popup())

	_glossary = GlossaryPopup.new()
	add_child(_glossary)

	_hide_timer = Timer.new()
	_hide_timer.wait_time = HIDE_GRACE_SECONDS
	_hide_timer.one_shot = true
	add_child(_hide_timer)
	_hide_timer.timeout.connect(_on_hide_tick)


# Show `element`'s card to the LEFT of the anchor rect (the forge paths sit on the right
# of the screen, so the preview opens inward over empty space).
func show_for(element: Dictionary, anchor: Rect2) -> void:
	_hide_timer.stop()
	_card.render(element)
	_card.visible = true
	_card.reset_size()
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var size: Vector2 = _card.get_combined_minimum_size()
	var pos := Vector2(anchor.position.x - size.x - 12.0, anchor.position.y)
	if pos.x < 8.0:
		pos.x = anchor.position.x + anchor.size.x + 12.0  # fall back to the right edge
	pos.y = clampf(pos.y, 8.0, maxf(8.0, vp.y - size.y - 8.0))
	_card.position = pos


# Called by the trigger (chip) on mouse-exit — defer the hide so a move onto the card,
# or onto a keyword link inside it, keeps the preview alive (checked geometrically).
func request_hide() -> void:
	_hide_timer.start()


func _on_hide_tick() -> void:
	if _card.visible and _card.get_global_rect().has_point(get_viewport().get_mouse_position()):
		_hide_timer.start()  # still over the card → keep it up
	else:
		_card.visible = false
		_glossary.hide_popup()
