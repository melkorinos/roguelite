class_name AbilitySystem

# Execution engine for element Abilities. Pure static functions over the GameState
# dict, mirroring StatusSystem/BattleSystem. Ability definitions come from
# AbilityData (keyed by element id) but an element may carry an inline "ability"
# dict which takes precedence — this keeps the engine testable without data.
#
# Ability shape:
#   { "trigger": String, "effects": Array[Dictionary],
#     "interval_deciseconds": int (periodic only), "multicast": int (extra fires),
#     "adjacency_upgrade": bool, "description": String }
#
# Atomic effect kinds (each a Dictionary in "effects"):
#   { "kind": "apply_status",     "status": String, "amount": int, "target": "own"|"opponent" }
#   { "kind": "deal_damage",      "amount": int, "target": "opponent" }
#   { "kind": "modify_cooldown",  "deciseconds": int, "target": "own"|"opponent" }
#   { "kind": "freeze",           "deciseconds": int, "count": int, "target": "opponent" }
#   { "kind": "set_status_field", "status": String, "field": String, "value": Variant, "target": "own"|"opponent" }


# ── Combat events ─────────────────────────────────────────────────────────────
# Two event shapes flow through the reactive seam (resolve_reactive). Producers
# (BattleSystem) build them with the factories below so the shape lives in one
# place; consumers branch on whether a "trigger" key is present.
#
#   Fire event    — visual + reactive: { side, slot, damage, effect, is_miss }
#   Trigger event — reactive only:     { trigger, side, slot }  (slot -1 = side-wide)
#
# Only fire events are stored in state["battle_events"] for the view layer
# (Battle.gd); trigger events (ticks, armor-strip, haste) are consumed within the
# tick and never rendered. Use is_visual_event() to split the two.

static func fire_event(side: String, slot: int, damage: int, effect: String) -> Dictionary:
	return { "side": side, "slot": slot, "damage": damage, "effect": effect, "is_miss": false }


static func miss_event(side: String, slot: int) -> Dictionary:
	return { "side": side, "slot": slot, "damage": 0, "effect": "", "is_miss": true }


static func trigger_event(trigger: String, side: String, slot: int = -1) -> Dictionary:
	return { "trigger": trigger, "side": side, "slot": slot }


static func is_visual_event(event: Dictionary) -> bool:
	return not event.has("trigger")


# ── ability lookup ────────────────────────────────────────────────────────────

# PERF (deferred 2026-06-04): ability_for, on_hit_status_chances, and the reactive
# grid scans are O(grid) per fire/event. Per-combat caches (a precomputed on-hit
# list, a trigger→[slots] map, cached ability_for) would cut this — deferred until
# abilities/elements stabilize, since precomputing now would churn during brainstorming.
static func ability_for(element: Dictionary) -> Dictionary:
	if element.has("ability"):
		return element["ability"] as Dictionary
	return AbilityData.get_ability(element.get("element_id", "") as String)


static func multicast_count(element: Dictionary) -> int:
	return ability_for(element).get("multicast", 0) as int


# ── side plumbing ─────────────────────────────────────────────────────────────

static func _resolve_target(target: String, source_side: String) -> String:
	if target == "own":
		return source_side
	return CombatSide.opponent_of(source_side)


static func _side_keys(side: String) -> Dictionary:
	return CombatSide.keys(side)


# ── effect application (mutates the passed state) ─────────────────────────────

# Returns the number of status applications made (for the Summary effects tally).
static func _apply_atom(state: Dictionary, effect: Dictionary, source_side: String) -> int:
	var kind: String = effect.get("kind", "") as String
	match kind:
		"apply_status":
			var target_side: String = _resolve_target(effect.get("target", "opponent") as String, source_side)
			var keys: Dictionary = _side_keys(target_side)
			var statuses: Dictionary = state[keys["statuses"]] as Dictionary
			var status: String = effect["status"] as String
			var amount: int = effect.get("amount", 1) as int
			for _n: int in amount:
				var result: Dictionary = StatusSystem.apply_effect(statuses, status)
				statuses = result["statuses"] as Dictionary
				state[keys["hp"]] = (state[keys["hp"]] as int) + (result["hp_delta"] as int)
			state[keys["statuses"]] = statuses
			return amount
		"deal_damage":
			var target_side: String = _resolve_target(effect.get("target", "opponent") as String, source_side)
			var keys: Dictionary = _side_keys(target_side)
			state[keys["hp"]] = maxi(0, (state[keys["hp"]] as int) - (effect["amount"] as int))
			return 0
		"modify_cooldown":
			var target_side: String = _resolve_target(effect.get("target", "opponent") as String, source_side)
			var keys: Dictionary = _side_keys(target_side)
			var statuses: Dictionary = state[keys["statuses"]] as Dictionary
			statuses["cooldown_modifier_deciseconds"] = (statuses["cooldown_modifier_deciseconds"] as int) + (effect["deciseconds"] as int)
			return 0
		"freeze":
			var target_side: String = _resolve_target(effect.get("target", "opponent") as String, source_side)
			var keys: Dictionary = _side_keys(target_side)
			var grid: Array = state[keys["grid"]] as Array
			var frozen: Array = state[keys["frozen"]] as Array
			var duration_seconds: float = float(effect["deciseconds"] as int) / 10.0
			var count: int = effect.get("count", 1) as int
			var frozen_applied: int = 0
			for _c: int in count:
				var slot: int = BattleSystem.select_freeze_target(grid, state[keys["last_frozen"]] as int)
				if slot >= 0:
					frozen[slot] = duration_seconds
					state[keys["last_frozen"]] = slot
					frozen_applied += 1
			return frozen_applied
		"set_status_field":
			var target_side: String = _resolve_target(effect.get("target", "opponent") as String, source_side)
			var keys: Dictionary = _side_keys(target_side)
			var statuses: Dictionary = state[keys["statuses"]] as Dictionary
			var status_dict: Dictionary = statuses[effect["status"] as String] as Dictionary
			var field: String = effect["field"] as String
			var value: Variant = effect["value"]
			if typeof(value) == TYPE_BOOL:
				status_dict[field] = value
			else:
				status_dict[field] = (status_dict[field] as int) + (value as int)
			return 0
	return 0


# source_slot >= 0 attributes the applied status count to that element's Summary row.
static func _apply_effects(state: Dictionary, effects: Array, source_side: String, source_slot: int = -1) -> void:
	var applied: int = 0
	for effect: Variant in effects:
		var e: Dictionary = effect as Dictionary
		if _conditions_met(state, e.get("when", []) as Array, source_side):
			applied += _apply_atom(state, e, source_side)
	if source_slot >= 0 and applied > 0:
		_record_effects(state, source_side, source_slot, applied)


static func _record_effects(state: Dictionary, side: String, slot: int, count: int) -> void:
	var battle_stats: Dictionary = state.get("battle_stats", {}) as Dictionary
	if not battle_stats.has(side):
		return
	var rows: Array = battle_stats[side] as Array
	if slot >= 0 and slot < rows.size():
		var row: Dictionary = rows[slot] as Dictionary
		row["effects"] = (row.get("effects", 0) as int) + count


# ── conditions (the "when" guard on any effect) ───────────────────────────────

# True when every condition in the list holds. An empty list is always true.
static func _conditions_met(state: Dictionary, conditions: Array, source_side: String) -> bool:
	for condition: Variant in conditions:
		if not _condition_met(state, condition as Dictionary, source_side):
			return false
	return true


static func _condition_met(state: Dictionary, condition: Dictionary, source_side: String) -> bool:
	match condition.get("kind", "") as String:
		"target_has_status":
			var target_side: String = _resolve_target(condition.get("target", "opponent") as String, source_side)
			var statuses: Dictionary = state[_side_keys(target_side)["statuses"]] as Dictionary
			return _status_count(statuses, condition["status"] as String) >= (condition.get("at_least", 1) as int)
	return true


# The headline integer for a status — used by conditions to test thresholds.
static func _status_count(statuses: Dictionary, status: String) -> int:
	var dict: Dictionary = statuses[status] as Dictionary
	match status:
		"burn", "poison", "weaken": return dict["stacks"] as int
		"shock": return dict["n"] as int
		"armor", "plating": return dict["value"] as int
		"blind": return dict["percent"] as int
		"curse": return dict["ticks_remaining"] as int
	return 0


# ── resolvers (return a new state, immutable to caller) ───────────────────────

# Resolves combat_start and static passive abilities once, for both sides.
static func resolve_combat_start(state: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	for side: String in ["player", "opponent"]:
		var grid: Array = s[_side_keys(side)["grid"]] as Array
		for i: int in grid.size():
			if grid[i] == null:
				continue
			var ability: Dictionary = ability_for(grid[i] as Dictionary)
			var trigger: String = ability.get("trigger", "") as String
			if trigger == "combat_start" or trigger == "passive":
				_apply_effects(s, ability.get("effects", []) as Array, side, i)
	return s


# Advances periodic ability timers by delta seconds and fires any that reach their
# interval. Timers live in player_ability_timers / opponent_ability_timers.
# Public form duplicates (immutable); the tick loop uses the _inplace form to avoid
# a full-state deep copy every frame.
static func resolve_periodic(state: Dictionary, delta: float) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	resolve_periodic_inplace(s, delta)
	return s


static func resolve_periodic_inplace(state: Dictionary, delta: float) -> void:
	for side: String in ["player", "opponent"]:
		var grid: Array = state[_side_keys(side)["grid"]] as Array
		var timers: Array = state[CombatSide.keys(side)["ability_timers"]] as Array
		for i: int in grid.size():
			if grid[i] == null:
				continue
			var ability: Dictionary = ability_for(grid[i] as Dictionary)
			if (ability.get("trigger", "") as String) != "periodic":
				continue
			var interval_seconds: float = float(ability.get("interval_deciseconds", 0) as int) / 10.0
			if interval_seconds <= 0.0:
				continue
			timers[i] = (timers[i] as float) + delta
			while (timers[i] as float) >= interval_seconds:
				timers[i] = (timers[i] as float) - interval_seconds
				_apply_effects(state, ability.get("effects", []) as Array, side, i)


# Resolves depth-1 reactive abilities against this tick's fire events. Each event
# carries the firing side, the effect string it applied, and the damage it dealt.
# A reactive ability's effects are applied once per matching event but emit no
# further events (depth-1) and never multicast.
# Depth-1 reactive abilities against this tick's events. Public form duplicates;
# the tick loop uses the _inplace form. A per-tick **circuit breaker**
# (MAX_REACTIONS_PER_TICK) caps total activations so a pathological "infinite build"
# can't spike a single tick — far above any legitimate board's worst case.
const MAX_REACTIONS_PER_TICK: int = 1024

static func resolve_reactive(state: Dictionary, events: Array, combat_rng: RandomNumberGenerator = null) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	resolve_reactive_inplace(s, events, combat_rng)
	return s


static func resolve_reactive_inplace(state: Dictionary, events: Array, combat_rng: RandomNumberGenerator = null) -> void:
	var activations: int = 0
	for event: Variant in events:
		var e: Dictionary = event as Dictionary
		if e.get("is_miss", false) as bool:
			continue
		var side: String = e["side"] as String
		# Fire events derive triggers from their effect string and carry a source
		# slot (for adjacency); typed events (ticks, armor-strip) carry the trigger
		# directly and may be side-wide (no slot).
		var triggers: Array
		var source_slot: int = -1
		if e.has("trigger"):
			triggers = [e["trigger"] as String]
			source_slot = e.get("slot", -1) as int
		else:
			triggers = _event_triggers(e["effect"] as String, e["damage"] as int)
			source_slot = e["slot"] as int
		if triggers.is_empty():
			continue
		var grid: Array = state[_side_keys(side)["grid"]] as Array
		var dimensions: Vector2i = GridSystem.dimensions(grid.size())
		for i: int in grid.size():
			if grid[i] == null:
				continue
			var ability: Dictionary = ability_for(grid[i] as Dictionary)
			if not _reactive_matches(ability, triggers):
				continue
			# adjacency_upgrade abilities only react to an adjacent source (when a
			# source slot is known — side-wide events skip the check).
			if source_slot >= 0 and (ability.get("adjacency_upgrade", false) as bool) and FeatureFlags.combat_adjacency:
				if not GridSystem.neighbors(i, dimensions.x, dimensions.y).has(source_slot):
					continue
			# Probabilistic reactives (Miasma) roll against the seeded RNG.
			if ability.has("chance") and combat_rng != null:
				if combat_rng.randf() * 100.0 >= float(ability["chance"] as int):
					continue
			activations += 1
			if activations > MAX_REACTIONS_PER_TICK:
				return  # circuit breaker — stop processing reactions this tick
			_apply_effects(state, ability.get("effects", []) as Array, side, i)


static func _event_triggers(effect: String, damage: int) -> Array:
	var triggers: Array = []
	match effect:
		"burn": triggers.append("on_burn_applied")
		"heal": triggers.append("on_heal_applied")
		"leech": triggers.append("on_leech")
		"haste": triggers.append("on_haste_applied")
	if effect in ["burn", "poison", "shock", "weaken", "blind", "curse"]:
		triggers.append("on_status_applied:" + effect)
	if damage > 0:
		triggers.append("on_damage_dealt")
	return triggers


static func _reactive_matches(ability: Dictionary, triggers: Array) -> bool:
	var trigger: String = ability.get("trigger", "") as String
	if trigger == "":
		return false
	if trigger == "on_status_applied":
		return triggers.has("on_status_applied:" + (ability.get("status", "") as String))
	return triggers.has(trigger)


# ── player commands (Innate Ability / Replay seam) ────────────────────────────

# Applies one timed player command's ability effects, once. A command is
# { at_seconds, side, ability, fired }. Public form duplicates; the tick loop's
# command drain uses apply_command in place.
static func resolve_command(state: Dictionary, command: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	apply_command(s, command)
	return s


static func apply_command(state: Dictionary, command: Dictionary) -> void:
	var ability: Dictionary = command["ability"] as Dictionary
	_apply_effects(state, ability.get("effects", []) as Array, command["side"] as String)


# ── passive on-hit query ──────────────────────────────────────────────────────

# Aggregates the probabilistic on-hit effects across a side's grid. Returns a list
# of { "status": String, "chance": int (percent), "target": String }. The caller
# rolls each against the combat-seeded RNG so replays stay deterministic.
static func on_hit_status_chances(grid: Array) -> Array:
	var chances: Array = []
	for slot: Variant in grid:
		if slot == null:
			continue
		var ability: Dictionary = ability_for(slot as Dictionary)
		if (ability.get("trigger", "") as String) != "passive_on_hit":
			continue
		for effect: Variant in ability.get("effects", []) as Array:
			var e: Dictionary = effect as Dictionary
			chances.append({
				"status": e["status"] as String,
				"chance": e.get("chance", 0) as int,
				"target": e.get("target", "opponent") as String,
			})
	return chances
