extends GutTest


func _state() -> Dictionary:
	return GameState.create()


# ── starting_options ──────────────────────────────────────────────────────────

func test_starting_options_returns_requested_count() -> void:
	assert_eq(StartSystem.starting_options(3).size(), 3)


func test_starting_options_are_all_tier1() -> void:
	for opt: Variant in StartSystem.starting_options(3):
		assert_eq((opt as Dictionary)["tier"] as int, 1)


func test_starting_options_are_distinct() -> void:
	var seen: Dictionary = {}
	for opt: Variant in StartSystem.starting_options(3):
		var id: String = (opt as Dictionary)["id"] as String
		assert_false(seen.has(id), "duplicate option: " + id)
		seen[id] = true


# ── apply_starting_pick ───────────────────────────────────────────────────────

func test_apply_starting_pick_grants_buffed_element() -> void:
	var s := StartSystem.apply_starting_pick(_state(), "fire")
	var inv: Array = s["inventory"] as Array
	assert_eq((inv[0] as Dictionary)["element_id"] as String, "fire")
	assert_eq((inv[0] as Dictionary)["damage_multiplier"] as int, StartSystem.STARTING_BUFF_MULTIPLIER)
	assert_true(s["starting_pick_done"] as bool)


func test_apply_starting_pick_is_once_only() -> void:
	var s := StartSystem.apply_starting_pick(_state(), "fire")
	var again := StartSystem.apply_starting_pick(s, "water")
	# second pick is a no-op — water is not granted
	for slot: Variant in again["inventory"] as Array:
		if slot != null:
			assert_ne((slot as Dictionary)["element_id"] as String, "water")


func test_apply_starting_pick_ignores_unknown_element() -> void:
	var s := StartSystem.apply_starting_pick(_state(), "nonexistent")
	assert_false(s["starting_pick_done"] as bool)
	for slot: Variant in s["inventory"] as Array:
		assert_null(slot)


func test_apply_starting_pick_does_not_mutate_input() -> void:
	var st := _state()
	StartSystem.apply_starting_pick(st, "fire")
	assert_false(st["starting_pick_done"] as bool)
	assert_null((st["inventory"] as Array)[0])


# ── effective_damage multiplier ───────────────────────────────────────────────

func test_effective_damage_doubles_with_multiplier() -> void:
	var fire := ElementData.find("fire").duplicate()
	fire["level"] = 1
	var base: int = ElementData.effective_damage(fire)
	fire["damage_multiplier"] = 2
	# multiplier hits the base-damage term only: (dmg*2*level + tier)
	assert_eq(ElementData.effective_damage(fire), base + (fire["damage"] as int))


func test_effective_damage_unchanged_without_multiplier() -> void:
	var fire := ElementData.find("fire").duplicate()
	fire["level"] = 2
	assert_eq(ElementData.effective_damage(fire), (fire["damage"] as int) * 2 + (fire["tier"] as int))
