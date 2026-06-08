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


func _state_with(id_a: String, id_b: String, level_a: int = 1, level_b: int = 1) -> Dictionary:
	var state := GameState.create()
	var ea: Dictionary = ElementData.find(id_a).duplicate()
	ea["element_id"] = id_a
	ea["level"] = level_a
	var eb: Dictionary = ElementData.find(id_b).duplicate()
	eb["element_id"] = id_b
	eb["level"] = level_b
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
	var s: Dictionary = ForgeSystem.attempt(state, {"kind": "merge", "zone": "grid", "a": 0, "b": 1})["state"]
	assert_eq((s["battle_grid"][0] as Dictionary)["level"], 2)
	assert_null(s["battle_grid"][1])


# ── forge_pair (Level ≥2 inputs; result = min inputs − 1, floored at 1; ADR 0008) ─

func test_forge_produces_correct_result() -> void:
	var s := _forge_pair(_state_with("water", "fire", 2, 2), 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["element_id"], "steam")


func test_forge_result_is_one_below_min_inputs() -> void:
	# Two Level-2 inputs → Level-1 result (the floor case).
	var s := _forge_pair(_state_with("water", "fire", 2, 2), 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["level"], 1)


func test_forge_result_tracks_higher_input_levels() -> void:
	# Two Level-3 inputs → Level-2 result (min − penalty).
	var s := _forge_pair(_state_with("water", "fire", 3, 3), 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["level"], 2)


func test_forge_result_uses_min_of_mismatched_input_levels() -> void:
	# min(2, 3) − 1 = 1.
	var s := _forge_pair(_state_with("water", "fire", 2, 3), 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["level"], 1)


func test_forge_rejected_when_inputs_below_min_level() -> void:
	# A valid recipe but Level-1 inputs → denied; nothing changes.
	var state := _state_with("water", "fire", 1, 1)
	var result := ForgeSystem.attempt(state, {"kind": "forge_pair", "a": 0, "b": 1})
	assert_eq(result["outcome"], "level_too_low")
	assert_eq((result["state"] as Dictionary)["inventory"], state["inventory"])


func test_forge_rejected_when_one_input_below_min_level() -> void:
	var state := _state_with("water", "fire", 2, 1)
	var result := ForgeSystem.attempt(state, {"kind": "forge_pair", "a": 0, "b": 1})
	assert_eq(result["outcome"], "level_too_low")


func test_forge_removes_consumed_slot() -> void:
	var s := _forge_pair(_state_with("water", "fire", 2, 2), 0, 1)
	assert_null(s["inventory"][1])


func test_forge_adds_result_to_discovered_recipes() -> void:
	var s := _forge_pair(_state_with("water", "fire", 2, 2), 0, 1)
	assert_true((s["discovered_recipes"] as Array).has("steam"))


func test_forge_adds_result_to_run_discoveries() -> void:
	var s := _forge_pair(_state_with("water", "fire", 2, 2), 0, 1)
	assert_true((s["run_discoveries"] as Array).has("steam"))


func test_forge_run_discoveries_are_distinct() -> void:
	var state := _state_with("water", "fire", 2, 2)
	(state["run_discoveries"] as Array).append("steam")
	var s := _forge_pair(state, 0, 1)
	var count: int = 0
	for id: Variant in s["run_discoveries"] as Array:
		if (id as String) == "steam":
			count += 1
	assert_eq(count, 1)


func test_forge_order_independent() -> void:
	var sa := _forge_pair(_state_with("water", "fire", 2, 2), 0, 1)
	var sb := _forge_pair(_state_with("fire", "water", 2, 2), 0, 1)
	assert_eq((sa["inventory"][0] as Dictionary)["element_id"],
			  (sb["inventory"][0] as Dictionary)["element_id"])


func test_forge_unknown_recipe_returns_state_unchanged() -> void:
	var state := _state_with("steam", "mud", 2, 2)
	var result := ForgeSystem.attempt(state, {"kind": "forge_pair", "a": 0, "b": 1})
	assert_eq(result["outcome"], "no_recipe")
	assert_eq((result["state"] as Dictionary)["inventory"], state["inventory"])


func test_forge_self_combo_water_produces_sea() -> void:
	var s := _forge_pair(_state_with("water", "water", 2, 2), 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["element_id"], "sea")


func test_forge_self_combo_fire_produces_blaze() -> void:
	var s := _forge_pair(_state_with("fire", "fire", 2, 2), 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["element_id"], "blaze")


func test_forge_self_combo_air_produces_gust() -> void:
	var s := _forge_pair(_state_with("air", "air", 2, 2), 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["element_id"], "gust")


func test_forge_self_combo_earth_produces_boulder() -> void:
	var s := _forge_pair(_state_with("earth", "earth", 2, 2), 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["element_id"], "boulder")


func test_forge_self_combo_requires_leveled_inputs() -> void:
	# Self-combos are no exception — two Level-1 waters can't forge into sea.
	var result := ForgeSystem.attempt(_state_with("water", "water", 1, 1), {"kind": "forge_pair", "a": 0, "b": 1})
	assert_eq(result["outcome"], "level_too_low")


func test_forge_self_combo_removes_consumed_slot() -> void:
	var s := _forge_pair(_state_with("water", "water", 2, 2), 0, 1)
	assert_null(s["inventory"][1])


func test_forge_self_combo_adds_to_discovered_recipes() -> void:
	var s := _forge_pair(_state_with("water", "water", 2, 2), 0, 1)
	assert_true((s["discovered_recipes"] as Array).has("sea"))


func test_forge_self_combo_adds_to_run_discoveries() -> void:
	var s := _forge_pair(_state_with("water", "water", 2, 2), 0, 1)
	assert_true((s["run_discoveries"] as Array).has("sea"))


func test_forge_self_combo_result_is_one_below_inputs() -> void:
	var s := _forge_pair(_state_with("fire", "fire", 2, 2), 0, 1)
	assert_eq((s["inventory"][0] as Dictionary)["level"], 1)


func test_forge_does_not_mutate_original() -> void:
	var state := _state_with("water", "fire", 2, 2)
	var orig_id: String = (state["inventory"][0] as Dictionary)["element_id"]
	_forge_pair(state, 0, 1)
	assert_eq((state["inventory"][0] as Dictionary)["element_id"], orig_id)


# ── forge_bench (outcomes) ──────────────────────────────────────────────────────

# Bench inputs default to Level 2 (the forge minimum) so the happy-path bench tests
# actually forge; level-specific tests pass explicit levels.
func _state_with_bench(id_a: String, id_b: String, level_a: int = 2, level_b: int = 2) -> Dictionary:
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


# A valid recipe with under-levelled inputs is denied AND keeps both items staged
# in the bench (so the player can pull them out and Merge up) — unlike no_recipe.
func test_forge_bench_rejected_when_inputs_below_min_level() -> void:
	var state := _state_with_bench("water", "fire", 1, 1)
	var result := ForgeSystem.attempt(state, {"kind": "forge_bench"})
	assert_eq(result["outcome"], "level_too_low")
	assert_eq((result["state"] as Dictionary)["forge_slots"], state["forge_slots"])


func test_forge_bench_reports_level_mismatch() -> void:
	# Both inputs meet the Level-2 minimum but differ → forge succeeds, mismatch flagged.
	var result := ForgeSystem.attempt(_state_with_bench("water", "fire", 2, 3), {"kind": "forge_bench"})
	assert_eq(result["outcome"], "ok")
	assert_true(result["level_mismatch"] as bool)


# ── preview ───────────────────────────────────────────────────────────────────

func test_preview_same_element_shows_next_level() -> void:
	assert_true(_preview_pair(_state_with("steam", "steam"), 0, 1).contains("Lv2"))


func test_preview_recipe_shows_result_name() -> void:
	assert_true(_preview_pair(_state_with("water", "fire", 2, 2), 0, 1).contains("Steam"))


func test_preview_below_min_level_prompts_to_level_up() -> void:
	# A valid recipe with Level-1 inputs previews the requirement, not the result.
	var preview: String = _preview_pair(_state_with("water", "fire", 1, 1), 0, 1)
	assert_true(preview.contains("Level"))
	assert_false(preview.contains("Steam"))


func test_preview_no_recipe_returns_no_recipe_string() -> void:
	assert_eq(_preview_pair(_state_with("steam", "mud"), 0, 1), "No recipe")


func test_preview_self_combo_shows_result_name() -> void:
	assert_true(_preview_pair(_state_with("water", "water", 2, 2), 0, 1).contains("Sea"))


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
	var s: Dictionary = ForgeSystem.attempt(state, {"kind": "to_bench", "forge_slot": -1, "from": {"zone": "grid", "slot": 2}})["state"]
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


# Invariant (ADR 0010): every element below Tier 4 must be an ingredient in at least
# one recipe — i.e. it forges further. Tier 4 is the apex and is exempt. Guards
# against re-introducing forward dead-ends as the roster evolves.
func test_no_non_apex_forward_dead_ends() -> void:
	var ingredient_ids: Dictionary = {}
	for recipe: Dictionary in RecipeData.all_recipes():
		ingredient_ids[recipe["a"] as String] = true
		ingredient_ids[recipe["b"] as String] = true
	for elem: Dictionary in ElementData.all_elements():
		if (elem["tier"] as int) >= 4:
			continue
		assert_true(ingredient_ids.has(elem["id"] as String),
			"%s (T%d) forges no further — add a higher recipe (ADR 0010)" % [elem["id"] as String, elem["tier"] as int])


# Guard the indexed ElementData (candidate 1): the roster count + order must stay
# stable, since Compendium and tier iteration depend on all_elements() ordering.
func test_element_roster_count_and_order_stable() -> void:
	var all: Array[Dictionary] = ElementData.all_elements()
	assert_eq(all.size(), 132, "element roster size")
	assert_eq((all[0] as Dictionary)["id"] as String, "water", "first element")
	assert_eq((all[all.size() - 1] as Dictionary)["id"] as String, "aether", "last element")


func test_find_returns_def_or_empty() -> void:
	assert_eq(ElementData.find("steam")["name"] as String, "Steam")
	assert_true(ElementData.find("nonexistent").is_empty())


# No two recipes share the same (order-independent) ingredient pair — a duplicate pair
# would be dead data (find_result returns the first match) and likely a copy-paste bug.
func test_no_duplicate_recipe_pairs() -> void:
	var seen: Dictionary = {}
	for recipe: Dictionary in RecipeData.all_recipes():
		var a: String = recipe["a"] as String
		var b: String = recipe["b"] as String
		var key: String = (a + "+" + b) if a <= b else (b + "+" + a)
		assert_false(seen.has(key), "duplicate recipe pair: %s" % key)
		seen[key] = true


# ── recipes_with (forward lookup for the Forge discoverability hint; ADR 0009) ──

func _has_pair(rows: Array, partner: String, result: String) -> bool:
	for row: Variant in rows:
		var r: Dictionary = row as Dictionary
		if (r["partner"] as String) == partner and (r["result"] as String) == result:
			return true
	return false


func test_recipes_with_finds_cross_combo_partner() -> void:
	# water is a, fire is b in water+fire→steam → water forges WITH fire INTO steam.
	assert_true(_has_pair(RecipeData.recipes_with("water"), "fire", "steam"))


func test_recipes_with_is_order_independent() -> void:
	# fire is the b in water+fire → it must still surface water as a partner.
	assert_true(_has_pair(RecipeData.recipes_with("fire"), "water", "steam"))


func test_recipes_with_self_combo_partner_is_itself() -> void:
	assert_true(_has_pair(RecipeData.recipes_with("water"), "water", "sea"))


func test_recipes_with_empty_for_non_ingredient() -> void:
	# Tier-4 elements are never a recipe ingredient → nothing forges with them.
	assert_eq(RecipeData.recipes_with("aether").size(), 0)


func test_recipes_with_results_are_findable_elements() -> void:
	for row: Dictionary in RecipeData.recipes_with("fire"):
		assert_false(ElementData.find(row["result"] as String).is_empty())
		assert_false(ElementData.find(row["partner"] as String).is_empty())


# ── recipes_for (pair-preserving "made from" lookup; ADR 0009) ─────────────────

func _has_ab(rows: Array, id_a: String, id_b: String) -> bool:
	for row: Variant in rows:
		var r: Dictionary = row as Dictionary
		var a: String = r["a"] as String
		var b: String = r["b"] as String
		if (a == id_a and b == id_b) or (a == id_b and b == id_a):
			return true
	return false


func test_recipes_for_returns_the_ingredient_pair() -> void:
	var made: Array[Dictionary] = RecipeData.recipes_for("tempered")
	assert_eq(made.size(), 1)
	assert_true(_has_ab(made, "frost", "metal"))


func test_recipes_for_lists_every_alternate_path() -> void:
	# glacier has several forge paths; assert the canonical ones are all present
	# (count is left loose so adding alternate paths doesn't break this).
	var made: Array[Dictionary] = RecipeData.recipes_for("glacier")
	assert_true(_has_ab(made, "freeze", "permafrost"))
	assert_true(_has_ab(made, "blackice", "permafrost"))
	assert_true(_has_ab(made, "sea", "freeze"))
	assert_gte(made.size(), 3)


func test_recipes_for_empty_for_base_tier1() -> void:
	assert_eq(RecipeData.recipes_for("water").size(), 0)


func test_recipes_for_pairs_are_findable_elements() -> void:
	for pair: Dictionary in RecipeData.recipes_for("glacier"):
		assert_false(ElementData.find(pair["a"] as String).is_empty())
		assert_false(ElementData.find(pair["b"] as String).is_empty())
