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


static func _day_seeded_grid(day: int, round_num: int, max_tier: int) -> Array:
	var pool: Array[Dictionary] = []
	for elem: Dictionary in ElementData.all_elements():
		if (elem["tier"] as int) <= max_tier:
			pool.append(elem)

	if pool.is_empty():
		return [null, null, null, null]

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(day) + str(round_num))

	# Fisher-Yates shuffle on index array using seeded rng
	var indices: Array[int] = []
	for i: int in pool.size():
		indices.append(i)
	for i: int in range(indices.size() - 1, 0, -1):
		var j: int = rng.randi() % (i + 1)
		var tmp: int = indices[i]
		indices[i] = indices[j]
		indices[j] = tmp

	var grid: Array = [null, null, null, null]
	var count: int = mini(_max_slots_for_round(round_num), pool.size())
	for i: int in count:
		var elem: Dictionary = pool[indices[i]].duplicate()
		elem["element_id"] = elem["id"]
		elem["level"] = 1
		grid[i] = elem

	return grid


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
