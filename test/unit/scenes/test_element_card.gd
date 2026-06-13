extends GutTest

# Runtime render checks for the rebuilt Element Card (ADR-0017). Exercises the real
# render() node-build path (GradientTexture2D glow, metal / prismatic StyleBox, pods
# from ElementData.stat_pods, lineage underbar) so a bad Godot API call fails red here
# rather than as a silent blank tile in the shop. Cards build their tree in _ready, so
# every card is add_child_autofree'd (which fires _ready) before render().


func _new_card() -> ElementCard:
	var card := ShopItemTile.new()
	add_child_autofree(card)  # fires _ready → builds the node tree
	return card


# Locate the stats HBox (its children are the pods) without hard-coding the tree path.
func _pods(card: ElementCard) -> int:
	return _find_stats(card).get_child_count()


func _find_stats(node: Node) -> HBoxContainer:
	for child: Node in node.get_children():
		if child is HBoxContainer and child.get_child_count() > 0 and child.get_child(0) is PanelContainer:
			return child as HBoxContainer
		var found: HBoxContainer = _find_stats(child)
		if found != null:
			return found
	return null


func test_render_tier1_applier_builds_two_pods() -> void:
	var card := _new_card()
	card.render(ElementData.instantiate("fire", 1))
	assert_eq(card.element_id, "fire")
	assert_eq(_pods(card), 2, "T1 applier → CD + STATUS")


func test_render_dealer_builds_two_pods() -> void:
	var card := _new_card()
	card.render(ElementData.instantiate("lava", 2))
	assert_eq(_pods(card), 2, "dealer → CD + DMG")


func test_render_reactive_builds_one_pod() -> void:
	var card := _new_card()
	card.render(ElementData.instantiate("steam", 1))
	assert_eq(_pods(card), 1, "reactive pure-effect → CD only")


func test_render_tier4_uses_prismatic_frame() -> void:
	# T4 (Supernova) swaps the metal StyleBoxFlat for the prismatic StyleBoxTexture ring.
	var card := _new_card()
	card.render(ElementData.instantiate("supernova", 1))
	var box: StyleBox = card.get_theme_stylebox("panel")
	assert_true(box is StyleBoxTexture, "T4 frame must be the prismatic StyleBoxTexture")


func test_render_tier3_uses_metal_frame() -> void:
	var card := _new_card()
	card.render(ElementData.instantiate("volcano", 1))
	var box: StyleBox = card.get_theme_stylebox("panel")
	assert_true(box is StyleBoxFlat, "T1–T3 frame is a metal StyleBoxFlat")


func test_clear_resets_to_empty_glyph() -> void:
	var card := _new_card()
	card.render(ElementData.instantiate("fire", 1))
	card.clear()
	assert_false(card.has_item)
	assert_eq(card.element_id, "")
