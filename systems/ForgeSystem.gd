class_name ForgeSystem

# Deep interface: two verbs over an "op" vocabulary. Callers describe WHAT they want
# (an op Dictionary) and read a uniform { state, outcome } back, instead of choosing
# among nine entry points with three different return shapes.
#
#   attempt(state, op) -> { "state": Dictionary, "outcome": String, ... }
#   preview(state, op) -> String
#
# op.kind:
#   "merge"       { zone:"inventory"|"grid", a:int, b:int }   same element + level → level+1
#   "forge_pair"  { a:int, b:int }                            two inventory slots via a recipe
#   "forge_bench" { }                                         forge the two bench slots
#   "to_bench"    { forge_slot:int (-1 = auto), from:{ zone:"inventory"|"grid", slot:int } }
#   "from_bench"  { forge_slot:int }                          bench slot → first free inventory
#
# outcome ∈ "ok" | "no_op" | "no_recipe" | "incomplete" | "inv_full"
#         | "level_too_low" (a forge whose inputs are below FORGE_MIN_INPUT_LEVEL —
#           you must Merge them up first; ADR 0008)
#         | "no_gold" (forge gold cost not met — inert while FORGE_GOLD_COST is 0).
# "forge_bench" additionally returns "level_mismatch": bool.
#
# Forge gating (ADR 0008): both inputs must be Level ≥ FORGE_MIN_INPUT_LEVEL and the
# result lands FORGE_RESULT_LEVEL_PENALTY levels below its inputs (floored at 1).
# Merge has no such gate — it is how you produce the leveled ingredients.


static func attempt(state: Dictionary, op: Dictionary) -> Dictionary:
	var result: Dictionary = _attempt(state, op)
	# Any merge/forge can produce the leveled element that earns a Battle Slot
	# (Grid Growth, ADR 0014). Re-evaluated on the result of every op — idempotent
	# (a no-op when nothing newly qualifies), so it's safe to run unconditionally.
	result["state"] = apply_grid_growth(result["state"] as Dictionary)
	return result


static func _attempt(state: Dictionary, op: Dictionary) -> Dictionary:
	match op.get("kind", "") as String:
		"merge":       return _merge(state, op.get("zone", "inventory") as String, op["a"] as int, op["b"] as int)
		"forge_pair":  return _forge_pair(state, op["a"] as int, op["b"] as int)
		"forge_bench": return _forge_bench(state)
		"to_bench":    return _to_bench(state, op.get("forge_slot", -1) as int, op["from"] as Dictionary)
		"from_bench":  return _from_bench(state, op["forge_slot"] as int)
	return _noop(state)


# ── Grid Growth (ADR 0014) ──────────────────────────────────────────────────────
# Grants Battle Slots when the player first OWNS an element of a tier at a level
# named in TuningData.GRID_GROWTH_TRIGGERS. Path-agnostic (Merge or Forge result),
# each trigger once per run (tracked in grid_growth_fired), never past
# GRID_HARD_MAX. Pure: returns the same `state` reference when nothing new fires,
# otherwise a grown duplicate. Idempotent — safe to call after any state change.
static func apply_grid_growth(state: Dictionary) -> Dictionary:
	var count: int = state.get("battle_slot_count", TuningData.GRID_BASE_SLOTS) as int
	if count >= TuningData.GRID_HARD_MAX:
		return state
	var fired: Array = state.get("grid_growth_fired", []) as Array
	var triggers: Array = TuningData.GRID_GROWTH_TRIGGERS
	var to_fire: Array[int] = []
	var projected: int = count
	for idx: int in triggers.size():
		if projected >= TuningData.GRID_HARD_MAX:
			break
		if fired.has(idx):
			continue
		var trig: Dictionary = triggers[idx]
		if _owns_tier_at_level(state, trig["tier"] as int, trig["level"] as int):
			to_fire.append(idx)
			projected += 1
	if to_fire.is_empty():
		return state
	var s: Dictionary = state.duplicate(true)
	var grid: Array = s["battle_grid"]
	for idx: int in to_fire:
		s["battle_slot_count"] = (s["battle_slot_count"] as int) + 1
		grid.append(null)
		(s["grid_growth_fired"] as Array).append(idx)
	return s


# True when the player owns (inventory, battle grid, or forge bench) at least one
# element of `tier` at level ≥ `level`.
static func _owns_tier_at_level(state: Dictionary, tier: int, level: int) -> bool:
	for key: String in ["inventory", "battle_grid", "forge_slots"]:
		for item: Variant in state.get(key, []) as Array:
			if item == null:
				continue
			var d: Dictionary = item as Dictionary
			if (d.get("tier", 0) as int) == tier and (d.get("level", 0) as int) >= level:
				return true
	return false


static func preview(state: Dictionary, op: Dictionary) -> String:
	match op.get("kind", "") as String:
		"forge_bench": return _preview_bench(state)
		"forge_pair":  return _preview_pair(state, op["a"] as int, op["b"] as int)
	return ""


# The Element instance a successful operation would produce — the same result
# preview() describes with "→", or null when there is none (incomplete, no recipe,
# or inputs below the forge-input Level). Lets a caller render the result as an
# Element Card without re-deriving the ADR-0008 level rule.
static func result_element(state: Dictionary, op: Dictionary) -> Variant:
	match op.get("kind", "") as String:
		"forge_bench":
			var slots: Array = state["forge_slots"]
			return _result_for(slots[0], slots[1], false)
		"forge_pair":
			var inv: Array = state["inventory"]
			return _result_for(inv[op["a"] as int], inv[op["b"] as int], true)
	return null


static func _noop(state: Dictionary) -> Dictionary:
	return { "state": state, "outcome": "no_op" }


# ── merge (level-up): same element + same level → level+1, in inventory or grid ──
static func _merge(state: Dictionary, zone: String, slot_a: int, slot_b: int) -> Dictionary:
	var key: String = "inventory" if zone == "inventory" else "battle_grid"
	var arr: Array = state[key]
	var ea: Variant = arr[slot_a]
	var eb: Variant = arr[slot_b]
	if ea == null or eb == null:
		return _noop(state)
	var da: Dictionary = ea as Dictionary
	var db: Dictionary = eb as Dictionary
	if da.get("element_id", "") != db.get("element_id", ""):
		return _noop(state)
	if (da["level"] as int) != (db["level"] as int):
		return _noop(state)
	var result_slot: int = mini(slot_a, slot_b)
	var clear_slot: int = maxi(slot_a, slot_b)
	var s: Dictionary = state.duplicate(true)
	var upgraded: Dictionary = (s[key][result_slot] as Dictionary).duplicate()
	upgraded["level"] = (da["level"] as int) + 1
	s[key][result_slot] = upgraded
	s[key][clear_slot] = null
	return { "state": s, "outcome": "ok" }


# ── forge a pair of inventory slots via a recipe. Inputs must be Level ≥ min (ADR
# 0008); result level = inputs − penalty, floored at 1. ─────────────────────────
static func _forge_pair(state: Dictionary, slot_a: int, slot_b: int) -> Dictionary:
	var inv: Array = state["inventory"]
	var ea: Variant = inv[slot_a]
	var eb: Variant = inv[slot_b]
	if ea == null or eb == null:
		return _noop(state)
	var da: Dictionary = ea as Dictionary
	var db: Dictionary = eb as Dictionary
	var result_id: String = RecipeData.find_result(da["element_id"], db["element_id"])
	if result_id.is_empty():
		return { "state": state, "outcome": "no_recipe" }
	var result_def: Dictionary = ElementData.find(result_id)
	if result_def.is_empty():
		return { "state": state, "outcome": "no_recipe" }
	if _inputs_below_min_level(da, db):
		return { "state": state, "outcome": "level_too_low" }
	if (state["gold"] as int) < TuningData.FORGE_GOLD_COST:
		return { "state": state, "outcome": "no_gold" }
	var s: Dictionary = state.duplicate(true)
	s["gold"] = (s["gold"] as int) - TuningData.FORGE_GOLD_COST
	s["inventory"][slot_a] = ElementData.instantiate(result_id, _forged_level(da["level"] as int, db["level"] as int))
	s["inventory"][slot_b] = null
	_record_discovery(s, result_id)
	return { "state": s, "outcome": "ok" }


# ── forge the two bench slots; result → first free inventory slot ───────────────
static func _forge_bench(state: Dictionary) -> Dictionary:
	var slots: Array = state["forge_slots"]
	var ea: Variant = slots[0]
	var eb: Variant = slots[1]
	if ea == null or eb == null:
		return { "state": state, "outcome": "incomplete", "level_mismatch": false }
	var da: Dictionary = ea as Dictionary
	var db: Dictionary = eb as Dictionary
	var result_id: String = RecipeData.find_result(da["element_id"], db["element_id"])
	if result_id.is_empty():
		# No recipe: return both ingredients to inventory and clear the bench.
		var s_no: Dictionary = state.duplicate(true)
		s_no["forge_slots"] = [null, null]
		var inv_no: Array = s_no["inventory"]
		for item: Variant in [ea, eb]:
			var empty: int = _first_empty_inv_slot(inv_no)
			if empty >= 0:
				inv_no[empty] = (item as Dictionary).duplicate()
		return { "state": s_no, "outcome": "no_recipe", "level_mismatch": false }
	var result_def: Dictionary = ElementData.find(result_id)
	if result_def.is_empty():
		return { "state": state, "outcome": "no_recipe", "level_mismatch": false }
	# Inputs too low: keep both items staged in the bench (unlike no_recipe, which
	# returns them) so the player can pull them out and Merge up — they CAN forge.
	if _inputs_below_min_level(da, db):
		return { "state": state, "outcome": "level_too_low", "level_mismatch": false }
	if (state["gold"] as int) < TuningData.FORGE_GOLD_COST:
		return { "state": state, "outcome": "no_gold", "level_mismatch": false }
	var s: Dictionary = state.duplicate(true)
	var free_slot: int = _first_empty_inv_slot(s["inventory"])
	if free_slot < 0:
		return { "state": state, "outcome": "inv_full", "level_mismatch": false }
	s["gold"] = (s["gold"] as int) - TuningData.FORGE_GOLD_COST
	var level_a: int = da["level"] as int
	var level_b: int = db["level"] as int
	s["inventory"][free_slot] = ElementData.instantiate(result_id, _forged_level(level_a, level_b))
	s["forge_slots"] = [null, null]
	_record_discovery(s, result_id)
	return { "state": s, "outcome": "ok", "level_mismatch": level_a != level_b }


# ── move an item (inventory or grid) into a bench slot ──────────────────────────
# forge_slot -1 = auto-pick: first free bench slot, else slot 1 (displacing it).
static func _to_bench(state: Dictionary, forge_slot: int, from: Dictionary) -> Dictionary:
	var from_key: String = "inventory" if (from["zone"] as String) == "inventory" else "battle_grid"
	var from_slot: int = from["slot"] as int
	if (state[from_key] as Array)[from_slot] == null:
		return _noop(state)
	var slots: Array = state["forge_slots"]
	var target: int = forge_slot
	if target < 0:
		target = 0 if slots[0] == null else 1
	var s: Dictionary = state.duplicate(true)
	var displaced: Variant = s["forge_slots"][target]
	if displaced != null:
		var free: int = _first_empty_inv_slot(s["inventory"])
		if free >= 0:
			s["inventory"][free] = (displaced as Dictionary).duplicate()
	s["forge_slots"][target] = (s[from_key][from_slot] as Dictionary).duplicate()
	s[from_key][from_slot] = null
	return { "state": s, "outcome": "ok" }


# ── move a bench item back to the first free inventory slot ─────────────────────
static func _from_bench(state: Dictionary, forge_slot: int) -> Dictionary:
	var item: Variant = state["forge_slots"][forge_slot]
	if item == null:
		return _noop(state)
	var free: int = _first_empty_inv_slot(state["inventory"])
	var s: Dictionary = state.duplicate(true)
	if free >= 0:
		s["inventory"][free] = (item as Dictionary).duplicate()
	s["forge_slots"][forge_slot] = null
	return { "state": s, "outcome": "ok" }


# ── previews ────────────────────────────────────────────────────────────────────

# A potential forge or level-up between two inventory slots.
static func _preview_pair(state: Dictionary, slot_a: int, slot_b: int) -> String:
	var inv: Array = state["inventory"]
	var ea: Variant = inv[slot_a]
	var eb: Variant = inv[slot_b]
	if ea == null or eb == null:
		return ""
	var da: Dictionary = ea as Dictionary
	var db: Dictionary = eb as Dictionary
	var result_id: String = RecipeData.find_result(da["element_id"], db["element_id"])
	if not result_id.is_empty():
		if _inputs_below_min_level(da, db):
			return "⚠ Level %d+ to forge" % TuningData.FORGE_MIN_INPUT_LEVEL
		var r: Dictionary = ElementData.find(result_id)
		return "→ %s %s" % [r["emoji"], r["name"]]
	if da["element_id"] == db["element_id"]:
		if (da["level"] as int) != (db["level"] as int):
			return "Levels must match"
		return "→ %s %s Lv%d" % [da["emoji"], da["name"], (da["level"] as int) + 1]
	return "No recipe"


# The two items currently sitting in the forge bench.
static func _preview_bench(state: Dictionary) -> String:
	var slots: Array = state["forge_slots"]
	var ea: Variant = slots[0]
	var eb: Variant = slots[1]
	if ea == null or eb == null:
		return ""
	var da: Dictionary = ea as Dictionary
	var db: Dictionary = eb as Dictionary
	var result_id: String = RecipeData.find_result(da["element_id"], db["element_id"])
	if not result_id.is_empty():
		if _inputs_below_min_level(da, db):
			return "⚠ Inputs must be Level %d+ — Merge them first" % TuningData.FORGE_MIN_INPUT_LEVEL
		var r: Dictionary = ElementData.find(result_id)
		var level_a: int = da["level"] as int
		var level_b: int = db["level"] as int
		var result_level: int = _forged_level(level_a, level_b)
		var warn: String = "  ⚠ level mismatch" if level_a != level_b else ""
		return "→ %s %s Lv%d%s" % [r["emoji"], r["name"], result_level, warn]
	return "✗ No recipe"


# ── internals ───────────────────────────────────────────────────────────────────

# Records a forged result into both the per-run discovery pool (drives the
# discovery-gated shop) and the persistent cross-run record (Compendium /
# achievements). Distinct results only.
static func _record_discovery(s: Dictionary, result_id: String) -> void:
	var discovered: Array = s["discovered_recipes"]
	if not discovered.has(result_id):
		discovered.append(result_id)
	var run_disc: Array = s["run_discoveries"]
	if not run_disc.has(result_id):
		run_disc.append(result_id)


# True when either forge input is below the minimum forge-input Level (ADR 0008).
static func _inputs_below_min_level(da: Dictionary, db: Dictionary) -> bool:
	return (da["level"] as int) < TuningData.FORGE_MIN_INPUT_LEVEL \
		or (db["level"] as int) < TuningData.FORGE_MIN_INPUT_LEVEL


# A forged result lands PENALTY levels below its (Level-gated) inputs, floored at 1.
# With min-input 2 and penalty 1, the floor case (two Level-2s) yields Level 1.
static func _forged_level(level_a: int, level_b: int) -> int:
	return maxi(1, mini(level_a, level_b) - TuningData.FORGE_RESULT_LEVEL_PENALTY)


# The Element instance produced by forging (recipe) or, when allow_merge, merging
# (same element + matching level → level+1) two slots, or null if neither applies.
# Mirrors the "→" branch of the preview functions so callers don't re-derive it.
static func _result_for(ea: Variant, eb: Variant, allow_merge: bool) -> Variant:
	if ea == null or eb == null:
		return null
	var da: Dictionary = ea as Dictionary
	var db: Dictionary = eb as Dictionary
	var result_id: String = RecipeData.find_result(da["element_id"], db["element_id"])
	if not result_id.is_empty():
		if _inputs_below_min_level(da, db):
			return null
		return ElementData.instantiate(result_id, _forged_level(da["level"] as int, db["level"] as int))
	if allow_merge and da["element_id"] == db["element_id"] and (da["level"] as int) == (db["level"] as int):
		var merged: Dictionary = da.duplicate()
		merged["level"] = (da["level"] as int) + 1
		return merged
	return null


static func _first_empty_inv_slot(inventory: Array) -> int:
	for i: int in inventory.size():
		if inventory[i] == null:
			return i
	return -1
