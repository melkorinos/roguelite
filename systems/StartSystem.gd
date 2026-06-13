class_name StartSystem

# Run-start "Starting Pick" (ADR 0016): the player is offered KEYSTONE_OFFER_COUNT
# Keystone Augments and hard-commits to one for the whole Run. Pure functions over the
# GameState dict; once per run, gated by state["starting_pick_done"]. The chosen Keystone
# is added to state["augments"] via AugmentSystem; its scope-tagged atoms then apply at
# their own sites (run-state / shop / combat). Roster + magnitudes live in KeystoneData
# and TuningData.KEYSTONE_*.


# The Keystones offered at the Starting Pick. Structured spread (Framework B): guarantees
# at least one Family-axis and one Status-axis card so an offer is never single-minded,
# then fills the rest with any remaining Keystone. Deterministic when an rng is supplied
# (tests); global randi() otherwise, for run-to-run variety.
static func starting_options(count: int = TuningData.KEYSTONE_OFFER_COUNT, rng: RandomNumberGenerator = null) -> Array:
	var pool: Array = KeystoneData.all().duplicate()
	_shuffle(pool, rng)
	var picks: Array = []
	var picked_ids: Dictionary = {}
	# Pass 1: guarantee one Family-axis and one Status-axis card (if the pool offers them).
	for axis_kind: String in ["family", "status"]:
		if picks.size() >= count:
			break
		for keystone: Variant in pool:
			var k: Dictionary = keystone as Dictionary
			if (k["axis_kind"] as String) == axis_kind and not picked_ids.has(k["id"] as String):
				picks.append(k)
				picked_ids[k["id"] as String] = true
				break
	# Pass 2: fill the remaining slots with any not-yet-picked Keystone.
	for keystone: Variant in pool:
		if picks.size() >= count:
			break
		var k: Dictionary = keystone as Dictionary
		if not picked_ids.has(k["id"] as String):
			picks.append(k)
			picked_ids[k["id"] as String] = true
	return picks


# Adds the chosen Keystone Augment to the run and marks the pick done. No-op if the pick
# was already made or the id is unknown.
static func apply_starting_pick(state: Dictionary, keystone_id: String) -> Dictionary:
	if state.get("starting_pick_done", false) as bool:
		return state
	var keystone: Dictionary = KeystoneData.find(keystone_id)
	if keystone.is_empty():
		return state
	var s: Dictionary = AugmentSystem.add_augment(state, keystone)
	s["starting_pick_done"] = true
	return s


# In-place seeded Fisher-Yates; uses the supplied rng (Replay/test determinism) or the
# global randi() when none is given.
static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i: int in range(arr.size() - 1, 0, -1):
		var j: int = (rng.randi() if rng != null else randi()) % (i + 1)
		var tmp: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
