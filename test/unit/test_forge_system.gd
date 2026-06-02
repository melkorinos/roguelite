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
