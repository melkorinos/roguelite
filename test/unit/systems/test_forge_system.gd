extends GutTest


func _state_with(id_a: String, id_b: String) -> Dictionary:
	var state := GameState.create()
	var ea: Dictionary = ElementData.find(id_a).duplicate()
	ea["element_id"] = id_a
	ea["level"] = 1
	var eb: Dictionary = ElementData.find(id_b).duplicate()
	eb["element_id"] = id_b
	eb["level"] = 1
	state["inventory"][0] = ea
	state["inventory"][1] = eb
	return state


# ── level_up ─────────────────────────────────────────────────────────────────

func test_level_up_increments_level() -> void:
	var state := _state_with("water", "water")
	var s := ForgeSystem.level_up(state, 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["level"], 2)


func test_level_up_removes_consumed_slot() -> void:
	var state := _state_with("water", "water")
	var s := ForgeSystem.level_up(state, 0, 1)
	assert_null(s["inventory"][1])


func test_level_up_fails_for_different_elements() -> void:
	var state := _state_with("water", "fire")
	var s := ForgeSystem.level_up(state, 0, 1)
	assert_eq(s["inventory"], state["inventory"])


func test_level_up_fails_for_mismatched_levels() -> void:
	var state := _state_with("water", "water")
	(state["inventory"][1] as Dictionary)["level"] = 2
	var s := ForgeSystem.level_up(state, 0, 1)
	assert_eq(s["inventory"], state["inventory"])


func test_level_up_does_not_mutate_original() -> void:
	var state := _state_with("water", "water")
	var original_level: int = (state["inventory"][0] as Dictionary)["level"]
	ForgeSystem.level_up(state, 0, 1)
	assert_eq((state["inventory"][0] as Dictionary)["level"], original_level)


# ── forge ─────────────────────────────────────────────────────────────────────

func test_forge_produces_correct_result() -> void:
	var state := _state_with("water", "fire")
	var s := ForgeSystem.forge(state, 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["element_id"], "steam")


func test_forge_result_starts_at_level_1() -> void:
	var state := _state_with("water", "fire")
	var s := ForgeSystem.forge(state, 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["level"], 1)


func test_forge_removes_consumed_slot() -> void:
	var state := _state_with("water", "fire")
	var s := ForgeSystem.forge(state, 0, 1)
	assert_null(s["inventory"][1])


func test_forge_adds_result_to_discovered_recipes() -> void:
	var state := _state_with("water", "fire")
	var s := ForgeSystem.forge(state, 0, 1)
	assert_true((s["discovered_recipes"] as Array).has("steam"))


func test_forge_first_t2_raises_shop_tier_to_2() -> void:
	var state := _state_with("water", "fire")
	assert_eq(state["shop_tier"], 1)
	var s := ForgeSystem.forge(state, 0, 1)
	assert_eq(s["shop_tier"], 2)


func test_forge_does_not_lower_shop_tier() -> void:
	var state := _state_with("water", "fire")
	state["shop_tier"] = 5
	var s := ForgeSystem.forge(state, 0, 1)
	assert_eq(s["shop_tier"], 5)


func test_forge_order_independent() -> void:
	var state_ab := _state_with("water", "fire")
	var state_ba := _state_with("fire", "water")
	var sa := ForgeSystem.forge(state_ab, 0, 1)
	var sb := ForgeSystem.forge(state_ba, 0, 1)
	assert_eq((sa["inventory"][0] as Dictionary)["element_id"],
			  (sb["inventory"][0] as Dictionary)["element_id"])


func test_forge_unknown_recipe_returns_state_unchanged() -> void:
	var state := _state_with("steam", "mud")
	var s := ForgeSystem.forge(state, 0, 1)
	assert_eq(s["inventory"], state["inventory"])


func test_forge_self_combo_water_produces_ice() -> void:
	var state := _state_with("water", "water")
	var s := ForgeSystem.forge(state, 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["element_id"], "ice")


func test_forge_self_combo_fire_produces_blaze() -> void:
	var state := _state_with("fire", "fire")
	var s := ForgeSystem.forge(state, 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["element_id"], "blaze")


func test_forge_self_combo_air_produces_gale() -> void:
	var state := _state_with("air", "air")
	var s := ForgeSystem.forge(state, 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["element_id"], "gale")


func test_forge_self_combo_earth_produces_boulder() -> void:
	var state := _state_with("earth", "earth")
	var s := ForgeSystem.forge(state, 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["element_id"], "boulder")


func test_forge_self_combo_removes_consumed_slot() -> void:
	var state := _state_with("water", "water")
	var s := ForgeSystem.forge(state, 0, 1)
	assert_null(s["inventory"][1])


func test_forge_self_combo_adds_to_discovered_recipes() -> void:
	var state := _state_with("water", "water")
	var s := ForgeSystem.forge(state, 0, 1)
	assert_true((s["discovered_recipes"] as Array).has("ice"))


func test_forge_self_combo_raises_shop_tier() -> void:
	var state := _state_with("water", "water")
	assert_eq(state["shop_tier"], 1)
	var s := ForgeSystem.forge(state, 0, 1)
	assert_eq(s["shop_tier"], 2)


func test_forge_self_combo_result_starts_at_level_1() -> void:
	var state := _state_with("fire", "fire")
	var s := ForgeSystem.forge(state, 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["level"], 1)


func test_forge_does_not_mutate_original() -> void:
	var state := _state_with("water", "fire")
	var orig_id: String = (state["inventory"][0] as Dictionary)["element_id"]
	ForgeSystem.forge(state, 0, 1)
	assert_eq((state["inventory"][0] as Dictionary)["element_id"], orig_id)


# ── preview ───────────────────────────────────────────────────────────────────

func test_preview_same_element_shows_next_level() -> void:
	var state := _state_with("steam", "steam")
	var p := ForgeSystem.preview(state, 0, 1)
	assert_true(p.contains("Lv2"))


func test_preview_recipe_shows_result_name() -> void:
	var state := _state_with("water", "fire")
	var p := ForgeSystem.preview(state, 0, 1)
	assert_true(p.contains("Steam"))


func test_preview_discovered_recipe_shows_name() -> void:
	var state := _state_with("water", "fire")
	(state["discovered_recipes"] as Array).append("steam")
	var p := ForgeSystem.preview(state, 0, 1)
	assert_true(p.contains("Steam"))


func test_preview_no_recipe_returns_no_recipe_string() -> void:
	var state := _state_with("steam", "mud")
	var p := ForgeSystem.preview(state, 0, 1)
	assert_eq(p, "No recipe")


func test_preview_self_combo_shows_result_name() -> void:
	var state := _state_with("water", "water")
	var p := ForgeSystem.preview(state, 0, 1)
	assert_true(p.contains("Ice"))


func test_preview_self_combo_discovered_shows_element_name() -> void:
	var state := _state_with("water", "water")
	(state["discovered_recipes"] as Array).append("ice")
	var p := ForgeSystem.preview(state, 0, 1)
	assert_true(p.contains("Ice"))


# ── move_to_forge_slot ────────────────────────────────────────────────────────

func _state_with_inv(id: String, inv_slot: int = 0) -> Dictionary:
	var state := GameState.create()
	var elem: Dictionary = ElementData.find(id).duplicate()
	elem["element_id"] = id
	elem["level"] = 1
	state["inventory"][inv_slot] = elem
	return state


func test_move_to_forge_slot_places_item_in_bench() -> void:
	var state := _state_with_inv("water")
	var s := ForgeSystem.move_to_forge_slot(state, 0, 0)
	assert_not_null(s["forge_slots"][0])
	assert_eq((s["forge_slots"][0] as Dictionary)["element_id"], "water")
	assert_null(s["inventory"][0])


func test_move_to_forge_slot_returns_displaced_item_to_inventory() -> void:
	var state := _state_with_inv("water", 0)
	var displaced: Dictionary = ElementData.find("fire").duplicate()
	displaced["element_id"] = "fire"; displaced["level"] = 1
	state["forge_slots"][0] = displaced
	var s := ForgeSystem.move_to_forge_slot(state, 0, 0)
	var found_fire: bool = false
	for item: Variant in s["inventory"]:
		if item != null and (item as Dictionary)["element_id"] == "fire":
			found_fire = true
	assert_true(found_fire)


func test_move_to_forge_slot_noop_when_inv_slot_empty() -> void:
	var state := GameState.create()
	var s := ForgeSystem.move_to_forge_slot(state, 0, 0)
	assert_null(s["forge_slots"][0])


func test_move_to_forge_slot_does_not_mutate_original() -> void:
	var state := _state_with_inv("water")
	ForgeSystem.move_to_forge_slot(state, 0, 0)
	assert_not_null(state["inventory"][0])


# ── forge_quick_slot ──────────────────────────────────────────────────────────

func test_forge_quick_slot_fills_first_empty_bench_slot() -> void:
	var state := _state_with_inv("water")
	var s := ForgeSystem.forge_quick_slot(state, 0)
	assert_not_null(s["forge_slots"][0])
	assert_eq((s["forge_slots"][0] as Dictionary)["element_id"], "water")
	assert_null(s["inventory"][0])


func test_forge_quick_slot_fills_second_slot_when_first_full() -> void:
	var state := _state_with_inv("air", 0)
	var fire: Dictionary = ElementData.find("fire").duplicate()
	fire["element_id"] = "fire"; fire["level"] = 1
	state["forge_slots"][0] = fire
	var s := ForgeSystem.forge_quick_slot(state, 0)
	assert_not_null(s["forge_slots"][1])
	assert_eq((s["forge_slots"][1] as Dictionary)["element_id"], "air")


func test_forge_quick_slot_noop_when_inv_slot_empty() -> void:
	var state := GameState.create()
	var s := ForgeSystem.forge_quick_slot(state, 0)
	assert_null(s["forge_slots"][0])
	assert_null(s["forge_slots"][1])


# ── remove_from_forge_slot ────────────────────────────────────────────────────

func test_remove_from_forge_slot_returns_item_to_inventory() -> void:
	var state := GameState.create()
	var elem: Dictionary = ElementData.find("earth").duplicate()
	elem["element_id"] = "earth"; elem["level"] = 1
	state["forge_slots"][1] = elem
	var s := ForgeSystem.remove_from_forge_slot(state, 1)
	assert_null(s["forge_slots"][1])
	var found: bool = false
	for item: Variant in s["inventory"]:
		if item != null and (item as Dictionary)["element_id"] == "earth":
			found = true
	assert_true(found)


func test_remove_from_forge_slot_on_empty_is_noop() -> void:
	var state := GameState.create()
	var s := ForgeSystem.remove_from_forge_slot(state, 0)
	assert_null(s["forge_slots"][0])


func test_remove_from_forge_slot_does_not_mutate_original() -> void:
	var state := GameState.create()
	var elem: Dictionary = ElementData.find("water").duplicate()
	elem["element_id"] = "water"; elem["level"] = 1
	state["forge_slots"][0] = elem
	ForgeSystem.remove_from_forge_slot(state, 0)
	assert_not_null(state["forge_slots"][0])


# ── extended cross-combo recipes ───────────────────────────────────────────────

func test_all_recipes_produce_findable_elements() -> void:
	for recipe: Dictionary in RecipeData.all_recipes():
		var result_id: String = recipe["result"] as String
		var elem := ElementData.find(result_id)
		assert_false(elem.is_empty(), "recipe result '" + result_id + "' not found in ElementData")


func test_all_recipes_order_independent() -> void:
	for recipe: Dictionary in RecipeData.all_recipes():
		var a: String = recipe["a"] as String
		var b: String = recipe["b"] as String
		assert_eq(
			RecipeData.find_result(a, b),
			RecipeData.find_result(b, a),
			a + "+" + b + " should be order-independent"
		)
