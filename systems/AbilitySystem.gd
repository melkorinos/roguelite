class_name AbilitySystem

# Execution engine for element Abilities. Pure static functions over the GameState
# dict, mirroring StatusSystem/BattleSystem. Ability definitions come from
# AbilityData (keyed by element id) but an element may carry an inline "ability"
# dict which takes precedence — this keeps the engine testable without data.
#
# Ability shape:
#   { "trigger": String, "effects": Array[Dictionary],
#     "interval_deciseconds": int (periodic only), "multicast": int (extra fires),
#     "every_n": int (on_activate only — fire effects every Nth activation),
#     "adjacency_upgrade": bool, "description": String }
#
# Atomic effect kinds (each a Dictionary in "effects"):
#   { "kind": "apply_status",     "status": String, "amount": int, "target": "own"|"opponent" }
#   { "kind": "deal_damage",      "amount": int, "target": "opponent" }
#   { "kind": "modify_cooldown",  "deciseconds": int, "target": "own"|"opponent" }
#   { "kind": "freeze",           "deciseconds": int, "count": int, "target": "opponent" }
#   { "kind": "set_status_field", "status": String, "field": String, "value": Variant, "target": "own"|"opponent" }
#   { "kind": "add_max_hp",       "amount": int, "target": "own" }            — raises HP + the bar max, for the fight
#   { "kind": "prime_dot",        "status": "burn"|"poison", "amount": int }  — one-shot bonus on the target's next DOT tick
#   { "kind": "prime_next_hit",   "amount": int, "target": "own" }            — one-shot bonus on this side's next direct hit
#   { "kind": "suppress",         "status": "heal"|"cleanse", "target": "own" } — blocks that side's heal/cleanse for the fight
#   { "kind": "set_side_field",   "field": String, "amount": int, "target": "own" } — adjusts a numeric side-wide field (cooldown/outgoing-damage)
#
# A "passive"-trigger ability may also carry an "aura" dict:
#   { "adjacent_damage_bonus": int }  — adjacent damage-dealers hit harder (level-scaled),
# queried at the damage site via adjacent_damage_bonus(); gated by FeatureFlags.combat_adjacency.


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


# The potency of the element at source_slot on its side — Level × tier multiplier
# (ElementData.scaled_potency), the quantity scalar for every status application.
# 1 when the slot is unknown (-1) or empty.
static func _source_potency(state: Dictionary, source_side: String, source_slot: int) -> int:
	if source_slot < 0:
		return 1
	var grid: Array = state.get(CombatSide.keys(source_side)["grid"], []) as Array
	if source_slot >= grid.size() or grid[source_slot] == null:
		return 1
	var element: Dictionary = grid[source_slot] as Dictionary
	return ElementData.scaled_potency(element.get("tier", 1) as int, element.get("level", 1) as int)


# ── effect application (mutates the passed state) ─────────────────────────────

# The atomic effect vocabulary. The single source for the facts an Ability author
# must know to write an effect: its required fields, the side it acts on when no
# explicit "target" is given, and whether its quantities scale by the source's
# potency (Level × tier multiplier). _apply_atom reads default_target from here, and
# test_ability_data validates every authored effect against it — so a typo'd kind or
# a missing field fails red in a test instead of silently no-opping in combat.
# haste_timers / leech_heal are synthesised by _on_fire_effects (never authored in
# AbilityData); they appear here so the dispatcher and the validator stay complete.
const ATOM_SCHEMAS: Dictionary = {
	"apply_status":     { "required": ["status"],                   "default_target": "opponent", "potency_aware": true },
	"deal_damage":      { "required": ["amount"],                   "default_target": "opponent", "potency_aware": false },
	"modify_cooldown":  { "required": ["deciseconds"],              "default_target": "opponent", "potency_aware": false },
	"freeze":           { "required": ["deciseconds"],              "default_target": "opponent", "potency_aware": false },
	"set_status_field": { "required": ["status", "field", "value"], "default_target": "opponent", "potency_aware": false },
	"haste_timers":     { "required": [],                           "default_target": "own",      "potency_aware": false },
	"leech_heal":       { "required": ["amount"],                   "default_target": "own",      "potency_aware": false },
	"add_max_hp":       { "required": ["amount"],                   "default_target": "own",      "potency_aware": true },
	"prime_dot":        { "required": ["status", "amount"],         "default_target": "opponent", "potency_aware": true },
	"prime_next_hit":   { "required": ["amount"],                   "default_target": "own",      "potency_aware": true },
	# Augment combat atom (ADR 0016): blocks the target side's heal/cleanse for the fight.
	# Shared with the ability vocabulary so abilities could use it too; no element does yet.
	"suppress":         { "required": ["status"],                   "default_target": "own",      "potency_aware": false },
	# Augment combat atom (ADR 0016): adjusts a numeric side-wide field by a flat amount
	# (cooldown_modifier_deciseconds, next_hit_bonus, outgoing_damage_flat). Field-name
	# validity is checked by AugmentSystem.validate_atom against EffectRegistry.
	"set_side_field":   { "required": ["field", "amount"],          "default_target": "own",      "potency_aware": false },
}


# Validates one authored effect dict against ATOM_SCHEMAS. Returns human-readable
# error strings (empty Array = valid). test_ability_data runs this over all 120
# Abilities so a bad atom can't ship as a silent combat no-op.
static func validate_atom(effect: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var kind: String = effect.get("kind", "") as String
	if not ATOM_SCHEMAS.has(kind):
		errors.append("unknown atom kind: '%s'" % kind)
		return errors
	for field: String in (ATOM_SCHEMAS[kind] as Dictionary)["required"] as Array:
		if not effect.has(field):
			errors.append("atom '%s' missing required field '%s'" % [kind, field])
	return errors


# Returns a { status_name: count } map of the status applications made (for the
# Summary breakdown). deal_damage / modify_cooldown / set_status_field apply no
# named status and return {}. The acted-on side's keys are resolved once from
# ATOM_SCHEMAS.default_target (an explicit effect "target" overrides it); an
# unknown kind is a no-op.
static func _apply_atom(state: Dictionary, effect: Dictionary, source_side: String, potency: int = 1, source_slot: int = -1) -> Dictionary:
	var kind: String = effect.get("kind", "") as String
	var schema: Dictionary = ATOM_SCHEMAS.get(kind, {}) as Dictionary
	if schema.is_empty():
		return {}
	var target_side: String = _resolve_target(effect.get("target", schema["default_target"] as String) as String, source_side)
	var keys: Dictionary = _side_keys(target_side)
	match kind:
		"apply_status":
			var statuses: Dictionary = state[keys["statuses"]] as Dictionary
			var status: String = effect["status"] as String
			var amount: int = effect.get("amount", 1) as int
			for _n: int in amount:
				var result: Dictionary = StatusSystem.apply_effect(statuses, status, potency, source_slot)
				statuses = result["statuses"] as Dictionary
				state[keys["hp"]] = (state[keys["hp"]] as int) + (result["hp_delta"] as int)
			state[keys["statuses"]] = statuses
			return { status: amount }
		"deal_damage":
			state[keys["hp"]] = maxi(0, (state[keys["hp"]] as int) - (effect["amount"] as int))
			return {}
		"modify_cooldown":
			var statuses: Dictionary = state[keys["statuses"]] as Dictionary
			statuses["cooldown_modifier_deciseconds"] = (statuses["cooldown_modifier_deciseconds"] as int) + (effect["deciseconds"] as int)
			return {}
		"freeze":
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
			return { "freeze": frozen_applied } if frozen_applied > 0 else {}
		"set_status_field":
			var statuses: Dictionary = state[keys["statuses"]] as Dictionary
			var status_dict: Dictionary = statuses[effect["status"] as String] as Dictionary
			var field: String = effect["field"] as String
			var value: Variant = effect["value"]
			if typeof(value) == TYPE_BOOL:
				status_dict[field] = value
			else:
				status_dict[field] = (status_dict[field] as int) + (value as int)
			return {}
		"haste_timers":
			# Air/Gust on-fire: shave every own cooldown timer by the per-application
			# Haste amount plus any reduction_bonus (set by Gust). Always own side.
			var haste: Dictionary = (state[keys["statuses"]] as Dictionary)["haste"] as Dictionary
			var haste_seconds: float = float(TuningData.HASTE_REDUCTION_DECISECONDS + (haste["reduction_bonus_deciseconds"] as int)) / 10.0
			var timers: Array = state[keys["timers"]] as Array
			for j: int in timers.size():
				timers[j] = maxf(0.0, (timers[j] as float) - haste_seconds)
			return {}
		"leech_heal":
			# Blood/Pulse/Ichor on-fire: heal own HP by this fire's damage plus the
			# leech.bonus, doubled when leech.double is set. amount = damage landed.
			var leech: Dictionary = (state[keys["statuses"]] as Dictionary)["leech"] as Dictionary
			var heal: int = (effect["amount"] as int) + (leech["bonus"] as int)
			if leech["double"] as bool:
				heal *= 2
			state[keys["hp"]] = (state[keys["hp"]] as int) + heal
			return { "leech": 1 }
		"add_max_hp":
			# Raises the side's HP AND its bar max for this fight (Ironwood, World Tree).
			# Level-scaled like every status quantity.
			var gain: int = (effect["amount"] as int) * potency
			state[keys["hp"]] = (state[keys["hp"]] as int) + gain
			var starting_key: String = keys["starting_hp"] as String
			if state.has(starting_key):
				state[starting_key] = (state[starting_key] as int) + gain
			return {}
		"prime_dot":
			# One-shot primer: the target side's NEXT burn/poison tick deals +amount.
			# Waits until that DOT actually ticks; does not stack a status.
			var dot: Dictionary = (state[keys["statuses"]] as Dictionary)[effect["status"] as String] as Dictionary
			dot["next_tick_bonus"] = (dot["next_tick_bonus"] as int) + (effect["amount"] as int) * potency
			return {}
		"prime_next_hit":
			# One-shot primer: this side's NEXT damaging direct hit deals +amount.
			var statuses: Dictionary = state[keys["statuses"]] as Dictionary
			statuses["next_hit_bonus"] = (statuses["next_hit_bonus"] as int) + (effect["amount"] as int) * potency
			return {}
		"suppress":
			# Pact suppression (ADR 0016): flag the target side so its own heal/cleanse
			# applications are blocked for the rest of the fight. status ∈ {heal, cleanse}.
			var statuses: Dictionary = state[keys["statuses"]] as Dictionary
			statuses["suppress_%s" % (effect["status"] as String)] = true
			return {}
		"set_side_field":
			# Adjusts a numeric side-wide field by a flat amount (ADR 0016). Guarded so a
			# typo'd or non-numeric field is a no-op rather than a crash.
			var statuses: Dictionary = state[keys["statuses"]] as Dictionary
			var field: String = effect["field"] as String
			if statuses.has(field) and typeof(statuses[field]) == TYPE_INT:
				statuses[field] = (statuses[field] as int) + (effect["amount"] as int)
			return {}
	return {}


# Sum of adjacent_damage_bonus auras held by neighbors of `slot`, each level-scaled
# (a Lv-N aura holder grants N × its bonus). Queried by BattleSystem at the damage
# site for damage-dealers only — pure-effect elements stay at 0 direct damage
# (ADR 0013). Gated by FeatureFlags.combat_adjacency like all adjacency reactives.
static func adjacent_damage_bonus(grid: Array, slot: int) -> int:
	if not FeatureFlags.combat_adjacency:
		return 0
	var dimensions: Vector2i = GridSystem.dimensions(grid.size())
	var total: int = 0
	for neighbor: int in GridSystem.neighbors(slot, dimensions.x, dimensions.y, grid.size()):
		if grid[neighbor] == null:
			continue
		var neighbor_element: Dictionary = grid[neighbor] as Dictionary
		var ability: Dictionary = ability_for(neighbor_element)
		if (ability.get("trigger", "") as String) != "passive" or not ability.has("aura"):
			continue
		var aura: Dictionary = ability["aura"] as Dictionary
		var bonus: int = aura.get("adjacent_damage_bonus", 0) as int
		total += bonus * maxi(1, neighbor_element.get("level", 1) as int)
	return total


# Public seam for non-board effect sources (Augments, ADR 0016): applies a list of
# atoms from a virtual source — no board slot (potency 1, no Summary attribution) — on
# `side`. Lets AugmentSystem reuse the combat atom vocabulary without reaching into the
# private _apply_effects. Mutates and returns `state`.
static func apply_external_effects(state: Dictionary, effects: Array, side: String) -> Dictionary:
	_apply_effects(state, effects, side, -1)
	return state


# source_slot >= 0 attributes the applied statuses to that element's Summary row.
# `potency` (Level × tier multiplier) scales every status quantity applied here.
# Derived from source_slot; 1 when unknown.
static func _apply_effects(state: Dictionary, effects: Array, source_side: String, source_slot: int = -1) -> void:
	var potency: int = _source_potency(state, source_side, source_slot)
	# Own-side HP delta over this application is the source element's healing (heal +
	# leech) — credited to its heal Contribution. Raw, so overheal counts.
	var own_hp_key: String = _side_keys(source_side)["hp"] as String
	var hp_before: int = state[own_hp_key] as int
	var applied: Dictionary = {}
	for effect: Variant in effects:
		var e: Dictionary = effect as Dictionary
		if _conditions_met(state, e.get("when", []) as Array, source_side):
			var made: Dictionary = _apply_atom(state, e, source_side, potency, source_slot)
			for status: Variant in made:
				applied[status] = (applied.get(status, 0) as int) + (made[status] as int)
	if source_slot >= 0 and not applied.is_empty():
		_record_effects(state, source_side, source_slot, applied)
	var healed: int = (state[own_hp_key] as int) - hp_before
	if source_slot >= 0 and healed > 0:
		_credit_heal_contrib(state, source_side, source_slot, healed)


# Credits `healed` HP to the source element's heal Contribution row (green bar).
static func _credit_heal_contrib(state: Dictionary, side: String, slot: int, healed: int) -> void:
	var battle_stats: Dictionary = state.get("battle_stats", {}) as Dictionary
	if not battle_stats.has(side):
		return
	var rows: Array = battle_stats[side] as Array
	if slot < 0 or slot >= rows.size():
		return
	var contrib: Dictionary = (rows[slot] as Dictionary)["contrib"] as Dictionary
	contrib["heal"] = (contrib["heal"] as int) + healed


static func _record_effects(state: Dictionary, side: String, slot: int, applied: Dictionary) -> void:
	var battle_stats: Dictionary = state.get("battle_stats", {}) as Dictionary
	if not battle_stats.has(side):
		return
	var rows: Array = battle_stats[side] as Array
	if slot < 0 or slot >= rows.size():
		return
	var row: Dictionary = rows[slot] as Dictionary
	var by_status: Dictionary = row.get("effects_by_status", {}) as Dictionary
	var total: int = 0
	for status: Variant in applied:
		var n: int = applied[status] as int
		by_status[status] = (by_status.get(status, 0) as int) + n
		total += n
	row["effects_by_status"] = by_status
	row["effects"] = (row.get("effects", 0) as int) + total


# ── on-fire Action (T1 element effect) ────────────────────────────────────────

# Applies a T1 element's on-fire Action through the same atomic-effect vocabulary
# as Abilities, so there is one applier rather than a parallel dispatcher in
# BattleSystem. Routes through _apply_effects, which also records the Battle
# Summary tally for source_slot. dmg_dealt is this fire's landed damage (leech).
static func apply_on_fire(state: Dictionary, effect: String, source_side: String, source_slot: int, dmg_dealt: int) -> void:
	_apply_effects(state, _on_fire_effects(effect, dmg_dealt), source_side, source_slot)


# Maps an on-fire effect string to its atomic effect list. Buffs (haste, heal,
# cleanse, leech) act on the firing side; every other effect lands on the opponent.
static func _on_fire_effects(effect: String, dmg_dealt: int) -> Array:
	match effect:
		"haste":
			return [{ "kind": "apply_status", "status": "haste", "amount": 1, "target": "own" },
				{ "kind": "haste_timers" }]
		"heal":
			return [{ "kind": "apply_status", "status": "heal", "amount": 1, "target": "own" }]
		"cleanse":
			return [{ "kind": "apply_status", "status": "cleanse", "amount": 1, "target": "own" }]
		"leech":
			return [{ "kind": "leech_heal", "amount": dmg_dealt }]
	return [{ "kind": "apply_status", "status": effect, "amount": 1, "target": "opponent" }]


# ── on-activate ability (the ability-tier sibling of the on-fire Action) ──────

# Applies an element's on_activate ability after it fires, through the same atomic
# vocabulary as every other ability. Where the legacy single-string "effect" field
# can only apply one status per fire, on_activate carries a compound effects array
# (e.g. Rootrot: [poison] + [weaken] every fire). Optional "every_n" gates the
# effects to every Nth activation, counted deterministically from the slot's fire
# tally (no RNG, no new state) — Shrapnel fires its [shock] every 3rd activation.
# fire_count is this slot's running fire count, already incremented for this fire.
# Like all non-fire-event abilities, the applied statuses emit no reactive events
# (depth-1). No-ops for any element whose ability is not on_activate.
static func apply_on_activate(state: Dictionary, ability: Dictionary, source_side: String, source_slot: int, fire_count: int) -> void:
	if (ability.get("trigger", "") as String) != "on_activate":
		return
	var every_n: int = ability.get("every_n", 1) as int
	if every_n > 1 and fire_count % every_n != 0:
		return
	_apply_effects(state, ability.get("effects", []) as Array, source_side, source_slot)


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
	if not EffectRegistry.EFFECTS.has(status):
		return 0
	var entry: Dictionary = EffectRegistry.EFFECTS[status] as Dictionary
	var field: String = entry.get("count_field", "") as String
	if field.is_empty() or not statuses.has(status):
		return 0
	return ((statuses[status] as Dictionary).get(field, 0)) as int


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
				if not GridSystem.neighbors(i, dimensions.x, dimensions.y, grid.size()).has(source_slot):
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
	if EffectRegistry.EFFECTS.has(effect):
		var entry: Dictionary = EffectRegistry.EFFECTS[effect] as Dictionary
		triggers.append_array(entry.get("triggers", []) as Array)
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
			var element: Dictionary = slot as Dictionary
			chances.append({
				"status": e["status"] as String,
				"chance": e.get("chance", 0) as int,
				"target": e.get("target", "opponent") as String,
				# potency for status scaling — Level × tier multiplier
				"potency": ElementData.scaled_potency(element.get("tier", 1) as int, element.get("level", 1) as int),
			})
	return chances
