extends GutTest

# ForgeSystem is exercised through its two-verb interface: attempt(state, op) and
# preview(state, op). These thin local helpers name each op so the tests read clearly.

func _merge_inv(state: Dictionary, a: int, b: int) -> Dictionary:
	return ForgeSystem.attempt(state, {"kind": "merge", "zone": "inventory", "a": a, "b": b})["state"]


func _forge_pair(state: Dictionary, a: int, b: int) -> Dictionary:
	return ForgeSystem.attempt(state, {"kind": "forge_pair", "a": a, "b": b})["state"]


func _preview_pair(state: Dictionary, a: int, b: int) -> String:
	return ForgeSystem.preview(state, {"kind": "forge_pair", "a": a, "b": b})


func _to_bench_inv(state: Dictionary, forge_slot: int, inv: int) -> Dictionary:
	return ForgeSystem.attempt(state, {"kind": "to_bench", "forge_slot": forge_slot, "from": {"zone": "inventory", "slot": inv}})["state"]


func _quick_inv(state: Dictionary, inv: int) -> Dictionary:
	return ForgeSystem.attempt(state, {"kind": "to_bench", "forge_slot": -1, "from": {"zone": "inventory", "slot": inv}})["state"]


func _from_bench(state: Dictionary, forge_slot: int) -> Dictionary:
	return ForgeSystem.attempt(state, {"kind": "from_bench", "forge_slot": forge_slot})["state"]


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


# ── merge (level-up) ─────────────────────────────────────────────────────────

func test_level_up_increments_level() -> void:
	var s := _merge_inv(_state_with("water", "water"), 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["level"], 2)


func test_level_up_removes_consumed_slot() -> void:
	var s := _merge_inv(_state_with("water", "water"), 0, 1)
	assert_null(s["inventory"][1])


func test_level_up_fails_for_different_elements() -> void:
	var state := _state_with("water", "fire")
	var s := _merge_inv(state, 0, 1)
	assert_eq(s["inventory"], state["inventory"])


func test_level_up_fails_for_mismatched_levels() -> void:
	var state := _state_with("water", "water")
	(state["inventory"][1] as Dictionary)["level"] = 2
	var s := _merge_inv(state, 0, 1)
	assert_eq(s["inventory"], state["inventory"])


func test_level_up_does_not_mutate_original() -> void:
	var state := _state_with("water", "water")
	var original_level: int = (state["inventory"][0] as Dictionary)["level"]
	_merge_inv(state, 0, 1)
	assert_eq((state["inventory"][0] as Dictionary)["level"], original_level)


func test_merge_grid_levels_up_in_place() -> void:
	var state := GameState.create()
	for slot: int in [0, 1]:
		var elem: Dictionary = ElementData.find("fire").duplicate()
		elem["element_id"] = "fire"; elem["level"] = 1
		state["battle_grid"][slot] = elem
	var s := ForgeSystem.attempt(state, {"kind": "merge", "zone": "grid", "a": 0, "b": 1})["state"]
	assert_eq((s["battle_grid"][0] as Dictionary)["level"], 2)
	assert_null(s["battle_grid"][1])


# ── forge_pair ─────────────────────────────────────────────────────────────────

func test_forge_produces_correct_result() -> void:
	var s := _forge_pair(_state_with("water", "fire"), 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["element_id"], "steam")


func test_forge_result_starts_at_level_1() -> void:
	var s := _forge_pair(_state_with("water", "fire"), 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["level"], 1)


func test_forge_removes_consumed_slot() -> void:
	var s := _forge_pair(_state_with("water", "fire"), 0, 1)
	assert_null(s["inventory"][1])


func test_forge_adds_result_to_discovered_recipes() -> void:
	var s := _forge_pair(_state_with("water", "fire"), 0, 1)
	assert_true((s["discovered_recipes"] as Array).has("steam"))


func test_forge_adds_result_to_run_discoveries() -> void:
	var s := _forge_pair(_state_with("water", "fire"), 0, 1)
	assert_true((s["run_discoveries"] as Array).has("steam"))


func test_forge_run_discoveries_are_distinct() -> void:
	var state := _state_with("water", "fire")
	(state["run_discoveries"] as Array).append("steam")
	var s := _forge_pair(state, 0, 1)
	var count: int = 0
	for id: Variant in s["run_discoveries"] as Array:
		if (id as String) == "steam":
			count += 1
	assert_eq(count, 1)


func test_forge_order_independent() -> void:
	var sa := _forge_pair(_state_with("water", "fire"), 0, 1)
	var sb := _forge_pair(_state_with("fire", "water"), 0, 1)
	assert_eq((sa["inventory"][0] as Dictionary)["element_id"],
			  (sb["inventory"][0] as Dictionary)["element_id"])


func test_forge_unknown_recipe_returns_state_unchanged() -> void:
	var state := _state_with("steam", "mud")
	var result := ForgeSystem.attempt(state, {"kind": "forge_pair", "a": 0, "b": 1})
	assert_eq(result["outcome"], "no_recipe")
	assert_eq((result["state"] as Dictionary)["inventory"], state["inventory"])


func test_forge_self_combo_water_produces_sea() -> void:
	var s := _forge_pair(_state_with("water", "water"), 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["element_id"], "sea")


func test_forge_self_combo_fire_produces_blaze() -> void:
	var s := _forge_pair(_state_with("fire", "fire"), 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["element_id"], "blaze")


func test_forge_self_combo_air_produces_gust() -> void:
	var s := _forge_pair(_state_with("air", "air"), 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["element_id"], "gust")


func test_forge_self_combo_earth_produces_boulder() -> void:
	var s := _forge_pair(_state_with("earth", "earth"), 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["element_id"], "boulder")


func test_forge_self_combo_removes_consumed_slot() -> void:
	var s := _forge_pair(_state_with("water", "water"), 0, 1)
	assert_null(s["inventory"][1])


func test_forge_self_combo_adds_to_discovered_recipes() -> void:
	var s := _forge_pair(_state_with("water", "water"), 0, 1)
	assert_true((s["discovered_recipes"] as Array).has("sea"))


func test_forge_self_combo_adds_to_run_discoveries() -> void:
	var s := _forge_pair(_state_with("water", "water"), 0, 1)
	assert_true((s["run_discoveries"] as Array).has("sea"))


func test_forge_self_combo_result_starts_at_level_1() -> void:
	var s := _forge_pair(_state_with("fire", "fire"), 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["level"], 1)


func test_forge_does_not_mutate_original() -> void:
	var state := _state_with("water", "fire")
	var orig_id: String = (state["inventory"][0] as Dictionary)["element_id"]
	_forge_pair(state, 0, 1)
	assert_eq((state["inventory"][0] as Dictionary)["element_id"], orig_id)


# ── forge_bench (outcomes) ──────────────────────────────────────────────────────

func _state_with_bench(id_a: String, id_b: String, level_a: int = 1, level_b: int = 1) -> Dictionary:
	var state := GameState.create()
	var ea: Dictionary = ElementData.find(id_a).duplicate()
	ea["element_id"] = id_a; ea["level"] = level_a
	var eb: Dictionary = ElementData.find(id_b).duplicate()
	eb["element_id"] = id_b; eb["level"] = level_b
	state["forge_slots"][0] = ea
	state["forge_slots"][1] = eb
	return state


func test_forge_bench_ok_produces_result_in_inventory() -> void:
	var result := ForgeSystem.attempt(_state_with_bench("water", "fire"), {"kind": "forge_bench"})
	assert_eq(result["outcome"], "ok")
	assert_eq((result["state"] as Dictionary)["forge_slots"], [null, null])
	var found: bool = false
	for item: Variant in (result["state"] as Dictionary)["inventory"] as Array:
		if item != null and (item as Dictionary)["element_id"] == "steam":
			found = true
	assert_true(found)


func test_forge_bench_incomplete_when_a_slot_is_empty() -> void:
	var state := GameState.create()
	state["forge_slots"][0] = ElementData.find("water").duplicate()
	var result := ForgeSystem.attempt(state, {"kind": "forge_bench"})
	assert_eq(result["outcome"], "incomplete")


func test_forge_bench_no_recipe_returns_ingredients() -> void:
	var result := ForgeSystem.attempt(_state_with_bench("steam", "mud"), {"kind": "forge_bench"})
	assert_eq(result["outcome"], "no_recipe")
	assert_eq((result["state"] as Dictionary)["forge_slots"], [null, null])


func test_forge_bench_reports_level_mismatch() -> void:
	var result := ForgeSystem.attempt(_state_with_bench("water", "fire", 1, 2), {"kind": "forge_bench"})
	assert_eq(result["outcome"], "ok")
	assert_true(result["level_mismatch"] as bool)


# ── preview ───────────────────────────────────────────────────────────────────

func test_preview_same_element_shows_next_level() -> void:
	assert_true(_preview_pair(_state_with("steam", "steam"), 0, 1).contains("Lv2"))


func test_preview_recipe_shows_result_name() -> void:
	assert_true(_preview_pair(_state_with("water", "fire"), 0, 1).contains("Steam"))


func test_preview_no_recipe_returns_no_recipe_string() -> void:
	assert_eq(_preview_pair(_state_with("steam", "mud"), 0, 1), "No recipe")


func test_preview_self_combo_shows_result_name() -> void:
	assert_true(_preview_pair(_state_with("water", "water"), 0, 1).contains("Sea"))


func test_preview_bench_shows_result_name() -> void:
	assert_true(ForgeSystem.preview(_state_with_bench("water", "fire"), {"kind": "forge_bench"}).contains("Steam"))


# ── to_bench (move / quick) ─────────────────────────────────────────────────────

func _state_with_inv(id: String, inv_slot: int = 0) -> Dictionary:
	var state := GameState.create()
	var elem: Dictionary = ElementData.find(id).duplicate()
	elem["element_id"] = id
	elem["level"] = 1
	state["inventory"][inv_slot] = elem
	return state


func test_to_bench_places_item_in_bench() -> void:
	var s := _to_bench_inv(_state_with_inv("water"), 0, 0)
	assert_eq((s["forge_slots"][0] as Dictionary)["element_id"], "water")
	assert_null(s["inventory"][0])


func test_to_bench_returns_displaced_item_to_inventory() -> void:
	var state := _state_with_inv("water", 0)
	var displaced: Dictionary = ElementData.find("fire").duplicate()
	displaced["element_id"] = "fire"; displaced["level"] = 1
	state["forge_slots"][0] = displaced
	var s := _to_bench_inv(state, 0, 0)
	var found_fire: bool = false
	for item: Variant in s["inventory"]:
		if item != null and (item as Dictionary)["element_id"] == "fire":
			found_fire = true
	assert_true(found_fire)


func test_to_bench_noop_when_inv_slot_empty() -> void:
	var s := _to_bench_inv(GameState.create(), 0, 0)
	assert_null(s["forge_slots"][0])


func test_to_bench_does_not_mutate_original() -> void:
	var state := _state_with_inv("water")
	_to_bench_inv(state, 0, 0)
	assert_not_null(state["inventory"][0])


func test_quick_fills_first_empty_bench_slot() -> void:
	var s := _quick_inv(_state_with_inv("water"), 0)
	assert_eq((s["forge_slots"][0] as Dictionary)["element_id"], "water")
	assert_null(s["inventory"][0])


func test_quick_fills_second_slot_when_first_full() -> void:
	var state := _state_with_inv("air", 0)
	var fire: Dictionary = ElementData.find("fire").duplicate()
	fire["element_id"] = "fire"; fire["level"] = 1
	state["forge_slots"][0] = fire
	var s := _quick_inv(state, 0)
	assert_eq((s["forge_slots"][1] as Dictionary)["element_id"], "air")


func test_quick_noop_when_inv_slot_empty() -> void:
	var s := _quick_inv(GameState.create(), 0)
	assert_null(s["forge_slots"][0])
	assert_null(s["forge_slots"][1])


func test_to_bench_from_grid_pulls_off_the_board() -> void:
	var state := GameState.create()
	var elem: Dictionary = ElementData.find("earth").duplicate()
	elem["element_id"] = "earth"; elem["level"] = 1
	state["battle_grid"][2] = elem
	var s := ForgeSystem.attempt(state, {"kind": "to_bench", "forge_slot": -1, "from": {"zone": "grid", "slot": 2}})["state"]
	assert_null(s["battle_grid"][2])
	assert_eq((s["forge_slots"][0] as Dictionary)["element_id"], "earth")


# ── from_bench ──────────────────────────────────────────────────────────────────

func test_from_bench_returns_item_to_inventory() -> void:
	var state := GameState.create()
	var elem: Dictionary = ElementData.find("earth").duplicate()
	elem["element_id"] = "earth"; elem["level"] = 1
	state["forge_slots"][1] = elem
	var s := _from_bench(state, 1)
	assert_null(s["forge_slots"][1])
	var found: bool = false
	for item: Variant in s["inventory"]:
		if item != null and (item as Dictionary)["element_id"] == "earth":
			found = true
	assert_true(found)


func test_from_bench_on_empty_is_noop() -> void:
	var s := _from_bench(GameState.create(), 0)
	assert_null(s["forge_slots"][0])


func test_from_bench_does_not_mutate_original() -> void:
	var state := GameState.create()
	var elem: Dictionary = ElementData.find("water").duplicate()
	elem["element_id"] = "water"; elem["level"] = 1
	state["forge_slots"][0] = elem
	_from_bench(state, 0)
	assert_not_null(state["forge_slots"][0])


# ── attempt dispatch ────────────────────────────────────────────────────────────

func test_attempt_unknown_op_is_noop() -> void:
	var state := GameState.create()
	var result := ForgeSystem.attempt(state, {"kind": "nonsense"})
	assert_eq(result["outcome"], "no_op")
	assert_eq(result["state"], state)


# ── recipe data integrity ───────────────────────────────────────────────────────

func test_all_recipes_produce_findable_elements() -> void:
	for recipe: Dictionary in RecipeData.all_recipes():
		var result_id: String = recipe["result"] as String
		assert_false(ElementData.find(result_id).is_empty(), "recipe result '" + result_id + "' not found in ElementData")


func test_all_recipes_order_independent() -> void:
	for recipe: Dictionary in RecipeData.all_recipes():
		var a: String = recipe["a"] as String
		var b: String = recipe["b"] as String
		assert_eq(RecipeData.find_result(a, b), RecipeData.find_result(b, a), a + "+" + b + " should be order-independent")
