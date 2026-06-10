class_name StartSystem

# Run-start "Starting Pick": the player is offered N distinct T1 elements and the
# chosen one is granted at STARTING_PICK_LEVEL (a head start on the Merge/Forge climb).
# Was a ×damage buff, but T1 are all pure-effect now, so a level head-start is the
# meaningful reward. Pure functions over the GameState dict; once per run, gated by
# state["starting_pick_done"].
#
# (Future: the options will diversify beyond plain T1s — out of scope for now.)

# Tuning lives in TuningData (STARTING_OPTION_COUNT, STARTING_PICK_LEVEL).


# N distinct random T1 element definitions — the offered choices. Deterministic when
# an rng is supplied (tests / future seeded runs); uses global randi otherwise.
static func starting_options(count: int = TuningData.STARTING_OPTION_COUNT, rng: RandomNumberGenerator = null) -> Array:
	var pool: Array = []
	for elem: Dictionary in ElementData.all_elements():
		if (elem["tier"] as int) == 1:
			pool.append(elem)
	var picks: Array = []
	var draws: int = mini(count, pool.size())
	for _i: int in draws:
		var idx: int = (rng.randi() if rng != null else randi()) % pool.size()
		picks.append((pool[idx] as Dictionary).duplicate())
		pool.remove_at(idx)
	return picks


# Grants the chosen element to the first empty inventory slot at STARTING_PICK_LEVEL and
# marks the pick done. No-op if the pick was already made or the id is unknown.
static func apply_starting_pick(state: Dictionary, element_id: String) -> Dictionary:
	if state.get("starting_pick_done", false) as bool:
		return state
	var instance: Dictionary = ElementData.instantiate(element_id, TuningData.STARTING_PICK_LEVEL)
	if instance.is_empty():
		return state
	var s: Dictionary = state.duplicate(true)
	# Full inventory → the grant is silently dropped (matches prior behaviour); the pick
	# is still consumed.
	ShopSystem.grant_to_inventory(s, instance)
	s["starting_pick_done"] = true
	return s
