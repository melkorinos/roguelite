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


# ── ability lookup ────────────────────────────────────────────────────────────

static func ability_for(element: Dictionary) -> Dictionary:
	if element.has("ability"):
		return element["ability"] as Dictionary
	return AbilityData.get_ability(element.get("element_id", "") as String)


static func multicast_count(element: Dictionary) -> int:
	return ability_for(element).get("multicast", 0) as int


# ── side plumbing ─────────────────────────────────────────────────────────────

static func _other_side(side: String) -> String:
	return "opponent" if side == "player" else "player"


static func _resolve_target(target: String, source_side: String) -> String:
	if target == "own":
		return source_side
	return _other_side(source_side)


static func _side_keys(side: String) -> Dictionary:
	if side == "player":
		return {
			"statuses": "player_statuses", "hp": "player_hp", "grid": "battle_grid",
			"frozen": "player_frozen_seconds", "last_frozen": "player_last_frozen_slot",
		}
	return {
		"statuses": "opponent_statuses", "hp": "opponent_hp", "grid": "opponent_grid",
		"frozen": "opponent_frozen_seconds", "last_frozen": "opponent_last_frozen_slot",
	}


# ── effect application (mutates the passed state) ─────────────────────────────

static func _apply_atom(state: Dictionary, effect: Dictionary, source_side: String) -> void:
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
		"deal_damage":
			var target_side: String = _resolve_target(effect.get("target", "opponent") as String, source_side)
			var keys: Dictionary = _side_keys(target_side)
			state[keys["hp"]] = maxi(0, (state[keys["hp"]] as int) - (effect["amount"] as int))
		"modify_cooldown":
			var target_side: String = _resolve_target(effect.get("target", "opponent") as String, source_side)
			var keys: Dictionary = _side_keys(target_side)
			var statuses: Dictionary = state[keys["statuses"]] as Dictionary
			statuses["cooldown_modifier_deciseconds"] = (statuses["cooldown_modifier_deciseconds"] as int) + (effect["deciseconds"] as int)
		"freeze":
			var target_side: String = _resolve_target(effect.get("target", "opponent") as String, source_side)
			var keys: Dictionary = _side_keys(target_side)
			var grid: Array = state[keys["grid"]] as Array
			var frozen: Array = state[keys["frozen"]] as Array
			var duration_seconds: float = float(effect["deciseconds"] as int) / 10.0
			var count: int = effect.get("count", 1) as int
			for _c: int in count:
				var slot: int = BattleSystem.select_freeze_target(grid, state[keys["last_frozen"]] as int)
				if slot >= 0:
					frozen[slot] = duration_seconds
					state[keys["last_frozen"]] = slot
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


static func _apply_effects(state: Dictionary, effects: Array, source_side: String) -> void:
	for effect: Variant in effects:
		var e: Dictionary = effect as Dictionary
		if _conditions_met(state, e.get("when", []) as Array, source_side):
			_apply_atom(state, e, source_side)


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
				_apply_effects(s, ability.get("effects", []) as Array, side)
	return s


# Advances periodic ability timers by delta seconds and fires any that reach their
# interval. Timers live in player_ability_timers / opponent_ability_timers.
static func resolve_periodic(state: Dictionary, delta: float) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	for side: String in ["player", "opponent"]:
		var grid: Array = s[_side_keys(side)["grid"]] as Array
		var timers: Array = s[side + "_ability_timers"] as Array
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
				_apply_effects(s, ability.get("effects", []) as Array, side)
	return s


# Resolves depth-1 reactive abilities against this tick's fire events. Each event
# carries the firing side, the effect string it applied, and the damage it dealt.
# A reactive ability's effects are applied once per matching event but emit no
# further events (depth-1) and never multicast.
static func resolve_reactive(state: Dictionary, events: Array) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	for event: Variant in events:
		var e: Dictionary = event as Dictionary
		if e.get("is_miss", false) as bool:
			continue
		var side: String = e["side"] as String
		var triggers: Array = _event_triggers(e["effect"] as String, e["damage"] as int)
		if triggers.is_empty():
			continue
		var grid: Array = s[_side_keys(side)["grid"]] as Array
		var source_slot: int = e["slot"] as int
		var dimensions: Vector2i = GridSystem.dimensions(grid.size())
		for i: int in grid.size():
			if grid[i] == null:
				continue
			var ability: Dictionary = ability_for(grid[i] as Dictionary)
			if not _reactive_matches(ability, triggers):
				continue
			# adjacency_upgrade abilities only react to an orthogonally-adjacent source.
			if (ability.get("adjacency_upgrade", false) as bool) and FeatureFlags.combat_adjacency:
				if not GridSystem.neighbors(i, dimensions.x, dimensions.y).has(source_slot):
					continue
			_apply_effects(s, ability.get("effects", []) as Array, side)
	return s


static func _event_triggers(effect: String, damage: int) -> Array:
	var triggers: Array = []
	match effect:
		"burn": triggers.append("on_burn_applied")
		"heal": triggers.append("on_heal_applied")
		"leech": triggers.append("on_leech")
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
