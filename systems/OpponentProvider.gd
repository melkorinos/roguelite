class_name OpponentProvider


# Opponent power now scales with the round, not the player's shop progress, so the
# difficulty curve is predictable and independent of how fast the player forges.
static func get_opponent(context: Dictionary) -> Dictionary:
	var day: int = context["day"] as int
	var round_num: int = context["round"] as int
	var max_tier: int = _max_tier_for_round(round_num)

	var grid := _day_seeded_grid(day, round_num, max_tier)
	if _grid_is_empty(grid):
		return GhostFixtures.get_fixture(max_tier)

	return {
		"player_id": "ghost_local",
		"player_name": "Day Ghost",
		"round": round_num,
		"grid": grid,
		"acquired_day": day,
		"source": "day_seeded",
	}


# Round → highest element tier the opponent may field (breakpoints in TuningData).
static func _max_tier_for_round(round_num: int) -> int:
	var tier: int = 1
	for brk: int in TuningData.OPPONENT_TIER_ROUND_BREAKS:
		if round_num > brk:
			tier += 1
	return tier


# A plausible round-scaled opponent board (G4): mostly the round's max tier with a
# little lower-tier filler, levelled up with the round, and biased toward a coherent
# family (elements sharing an ingredient). Deterministic — seeded by day+round so Replay
# and async playback reproduce it. Grid-agnostic via CombatState.SLOT_COUNT.
static func _day_seeded_grid(day: int, round_num: int, max_tier: int) -> Array:
	# The opponent board scales with the round (capped at the hard max), mirroring the
	# player's Grid Growth (ADR 0014) so a grown player isn't permanently fighting a
	# 4-slot ghost. Per-side combat sizing handles whatever length this returns.
	var slots: int = mini(_max_slots_for_round(round_num), TuningData.GRID_HARD_MAX)
	var grid: Array = CombatState.empty_slots(slots)
	var level: int = _level_for_round(round_num)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(day) + str(round_num))
	# Most slots field the round's max tier; the remainder sit one tier down (floored
	# at 1) — a board mid-climb rather than a uniform grab-bag.
	var top_count: int = int(ceil(float(slots) * TuningData.GHOST_TOP_TIER_FRACTION))
	var used_ids: Dictionary = {}
	var used_ingredients: Dictionary = {}
	for i: int in slots:
		var target_tier: int = max_tier if i < top_count else maxi(1, max_tier - 1)
		var def: Dictionary = _pick_ghost_element(target_tier, used_ids, used_ingredients, rng)
		if def.is_empty():
			continue
		used_ids[def["id"] as String] = true
		for ingredient: String in RecipeData.ingredients_of(def["id"] as String):
			used_ingredients[ingredient] = true
		grid[i] = ElementData.instantiate(def["id"] as String, level)
	return grid


# Picks one tier-`tier` element, preferring an unused one that shares a family
# (ingredient) with the elements already chosen. Falls back to any unused, then any.
static func _pick_ghost_element(tier: int, used_ids: Dictionary, used_ingredients: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var pool: Array[Dictionary] = _elements_of_tier(tier)
	if pool.is_empty():
		return {}
	var available: Array[Dictionary] = []
	for elem: Dictionary in pool:
		if not used_ids.has(elem["id"] as String):
			available.append(elem)
	if available.is_empty():
		available = pool
	if not used_ingredients.is_empty():
		var coherent: Array[Dictionary] = []
		for elem: Dictionary in available:
			for ingredient: String in RecipeData.ingredients_of(elem["id"] as String):
				if used_ingredients.has(ingredient):
					coherent.append(elem)
					break
		if not coherent.is_empty():
			available = coherent
	return available[rng.randi() % available.size()]


static func _elements_of_tier(tier: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for elem: Dictionary in ElementData.all_elements():
		if (elem["tier"] as int) == tier:
			result.append(elem)
	return result


# Ghost element level by round (breakpoints in TuningData), mirroring _max_tier_for_round
# — so opponent offence grows on the Level axis like a real board's does.
static func _level_for_round(round_num: int) -> int:
	var level: int = 1
	for brk: Variant in TuningData.GHOST_LEVEL_ROUND_BREAKS:
		if round_num > (brk as int):
			level += 1
	return level


static func _max_slots_for_round(round_num: int) -> int:
	var slots: int = TuningData.OPPONENT_SLOTS_BASE
	for brk: int in TuningData.OPPONENT_SLOTS_ROUND_BREAKS:
		if round_num > brk:
			slots += 1
	return slots


static func _grid_is_empty(grid: Array) -> bool:
	for slot: Variant in grid:
		if slot != null:
			return false
	return true
