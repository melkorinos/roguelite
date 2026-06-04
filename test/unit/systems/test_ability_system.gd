extends GutTest


func _state() -> Dictionary:
	return GameState.create()


func _with_ability(side: String, slot: int, ability: Dictionary) -> Dictionary:
	var st: Dictionary = _state()
	var grid_key: String = "battle_grid" if side == "player" else "opponent_grid"
	st[grid_key][slot] = {
		"element_id": "test", "cooldown_deciseconds": 30, "damage": 1, "tier": 2,
		"ability": ability,
	}
	return st


func _dummy(side: String, slot: int, st: Dictionary) -> void:
	var grid_key: String = "battle_grid" if side == "player" else "opponent_grid"
	st[grid_key][slot] = { "element_id": "dummy", "cooldown_deciseconds": 30, "damage": 1, "tier": 1 }


# ── multicast_count ───────────────────────────────────────────────────────────

func test_multicast_count_reads_ability() -> void:
	var elem: Dictionary = { "ability": { "multicast": 1 } }
	assert_eq(AbilitySystem.multicast_count(elem), 1)


func test_multicast_count_defaults_to_zero() -> void:
	var elem: Dictionary = { "ability": {} }
	assert_eq(AbilitySystem.multicast_count(elem), 0)


# ── conditional effects (when-guards) ─────────────────────────────────────────

func test_conditional_effect_skipped_when_condition_unmet() -> void:
	# deal 2 only if opponent has >= 3 shock — opponent has 0, so skip.
	var ability: Dictionary = { "trigger": "combat_start", "effects": [
		{ "kind": "deal_damage", "amount": 2, "target": "opponent",
			"when": [{ "kind": "target_has_status", "target": "opponent", "status": "shock", "at_least": 3 }] }] }
	var st: Dictionary = _with_ability("player", 0, ability)
	var before: int = st["opponent_hp"] as int
	var s: Dictionary = AbilitySystem.resolve_combat_start(st)
	assert_eq(s["opponent_hp"] as int, before)


func test_conditional_effect_applied_when_condition_met() -> void:
	var ability: Dictionary = { "trigger": "combat_start", "effects": [
		{ "kind": "deal_damage", "amount": 2, "target": "opponent",
			"when": [{ "kind": "target_has_status", "target": "opponent", "status": "shock", "at_least": 3 }] }] }
	var st: Dictionary = _with_ability("player", 0, ability)
	((st["opponent_statuses"] as Dictionary)["shock"] as Dictionary)["n"] = 3
	var before: int = st["opponent_hp"] as int
	var s: Dictionary = AbilitySystem.resolve_combat_start(st)
	assert_eq(s["opponent_hp"] as int, before - 2)


func test_conditional_requires_all_conditions() -> void:
	# needs BOTH poison>=1 AND weaken>=1; only poison present → skip.
	var ability: Dictionary = { "trigger": "combat_start", "effects": [
		{ "kind": "deal_damage", "amount": 2, "target": "opponent", "when": [
			{ "kind": "target_has_status", "target": "opponent", "status": "poison", "at_least": 1 },
			{ "kind": "target_has_status", "target": "opponent", "status": "weaken", "at_least": 1 }] }] }
	var st: Dictionary = _with_ability("player", 0, ability)
	((st["opponent_statuses"] as Dictionary)["poison"] as Dictionary)["stacks"] = 2
	var before: int = st["opponent_hp"] as int
	var s: Dictionary = AbilitySystem.resolve_combat_start(st)
	assert_eq(s["opponent_hp"] as int, before)


# ── resolve_combat_start ──────────────────────────────────────────────────────

func test_combat_start_applies_armor_to_own_side() -> void:
	var ability: Dictionary = { "trigger": "combat_start",
		"effects": [{ "kind": "apply_status", "status": "armor", "amount": 4, "target": "own" }] }
	var s: Dictionary = AbilitySystem.resolve_combat_start(_with_ability("player", 0, ability))
	assert_eq(((s["player_statuses"] as Dictionary)["armor"] as Dictionary)["value"] as int, 4)


func test_combat_start_apply_status_amount_loops() -> void:
	var ability: Dictionary = { "trigger": "combat_start",
		"effects": [{ "kind": "apply_status", "status": "burn", "amount": 2, "target": "opponent" }] }
	var s: Dictionary = AbilitySystem.resolve_combat_start(_with_ability("player", 0, ability))
	assert_eq(((s["opponent_statuses"] as Dictionary)["burn"] as Dictionary)["stacks"] as int, 2)


func test_combat_start_deal_damage_to_opponent() -> void:
	var ability: Dictionary = { "trigger": "combat_start",
		"effects": [{ "kind": "deal_damage", "amount": 3, "target": "opponent" }] }
	var st: Dictionary = _with_ability("player", 0, ability)
	var before: int = st["opponent_hp"] as int
	var s: Dictionary = AbilitySystem.resolve_combat_start(st)
	assert_eq(s["opponent_hp"] as int, before - 3)


func test_combat_start_modify_cooldown_sets_opponent_penalty() -> void:
	var ability: Dictionary = { "trigger": "combat_start",
		"effects": [{ "kind": "modify_cooldown", "deciseconds": 8, "target": "opponent" }] }
	var s: Dictionary = AbilitySystem.resolve_combat_start(_with_ability("player", 0, ability))
	assert_eq((s["opponent_statuses"] as Dictionary)["cooldown_modifier_deciseconds"] as int, 8)


func test_combat_start_freeze_sets_target_and_last_frozen() -> void:
	var ability: Dictionary = { "trigger": "combat_start",
		"effects": [{ "kind": "freeze", "deciseconds": 50, "count": 1, "target": "opponent" }] }
	var st: Dictionary = _with_ability("player", 0, ability)
	_dummy("opponent", 0, st)
	_dummy("opponent", 1, st)
	var s: Dictionary = AbilitySystem.resolve_combat_start(st)
	assert_almost_eq((s["opponent_frozen_seconds"] as Array)[0] as float, 5.0, 0.001)
	assert_eq(s["opponent_last_frozen_slot"] as int, 0)


func test_combat_start_set_status_field_makes_curse_permanent() -> void:
	var ability: Dictionary = { "trigger": "passive",
		"effects": [{ "kind": "set_status_field", "status": "curse", "field": "is_permanent", "value": true, "target": "opponent" }] }
	var s: Dictionary = AbilitySystem.resolve_combat_start(_with_ability("player", 0, ability))
	assert_true(((s["opponent_statuses"] as Dictionary)["curse"] as Dictionary)["is_permanent"] as bool)


func test_combat_start_does_not_mutate_input() -> void:
	var ability: Dictionary = { "trigger": "combat_start",
		"effects": [{ "kind": "deal_damage", "amount": 3, "target": "opponent" }] }
	var st: Dictionary = _with_ability("player", 0, ability)
	var before: int = st["opponent_hp"] as int
	AbilitySystem.resolve_combat_start(st)
	assert_eq(st["opponent_hp"] as int, before)


# ── resolve_reactive (depth-1) ────────────────────────────────────────────────

func test_reactive_on_burn_applied_deals_bonus_damage() -> void:
	# Steam pattern: when burn is applied, deal 1 to opponent.
	var ability: Dictionary = { "trigger": "on_burn_applied",
		"effects": [{ "kind": "deal_damage", "amount": 1, "target": "opponent" }] }
	var st: Dictionary = _with_ability("player", 0, ability)
	var before: int = st["opponent_hp"] as int
	var events: Array = [{ "side": "player", "slot": 1, "damage": 2, "effect": "burn", "is_miss": false }]
	var s: Dictionary = AbilitySystem.resolve_reactive(st, events)
	assert_eq(s["opponent_hp"] as int, before - 1)


func test_reactive_fires_once_per_event_for_multicast() -> void:
	# Two burn events (a 2x multicast) → Steam reacts twice.
	var ability: Dictionary = { "trigger": "on_burn_applied",
		"effects": [{ "kind": "deal_damage", "amount": 1, "target": "opponent" }] }
	var st: Dictionary = _with_ability("player", 0, ability)
	var before: int = st["opponent_hp"] as int
	var events: Array = [
		{ "side": "player", "slot": 1, "damage": 2, "effect": "burn", "is_miss": false },
		{ "side": "player", "slot": 1, "damage": 2, "effect": "burn", "is_miss": false },
	]
	var s: Dictionary = AbilitySystem.resolve_reactive(st, events)
	assert_eq(s["opponent_hp"] as int, before - 2)


func test_reactive_ignores_miss_events() -> void:
	var ability: Dictionary = { "trigger": "on_damage_dealt",
		"effects": [{ "kind": "deal_damage", "amount": 1, "target": "opponent" }] }
	var st: Dictionary = _with_ability("player", 0, ability)
	var before: int = st["opponent_hp"] as int
	var events: Array = [{ "side": "player", "slot": 1, "damage": 0, "effect": "", "is_miss": true }]
	var s: Dictionary = AbilitySystem.resolve_reactive(st, events)
	assert_eq(s["opponent_hp"] as int, before)


func test_reactive_on_damage_dealt_applies_status() -> void:
	# Flint pattern: on any damage hit, apply shock.
	var ability: Dictionary = { "trigger": "on_damage_dealt",
		"effects": [{ "kind": "apply_status", "status": "shock", "amount": 1, "target": "opponent" }] }
	var st: Dictionary = _with_ability("player", 0, ability)
	var events: Array = [{ "side": "player", "slot": 1, "damage": 3, "effect": "", "is_miss": false }]
	var s: Dictionary = AbilitySystem.resolve_reactive(st, events)
	assert_eq(((s["opponent_statuses"] as Dictionary)["shock"] as Dictionary)["n"] as int, 1)


# ── adjacency-gated reactives (combat_adjacency) ──────────────────────────────

func _ember_like(slot: int) -> Dictionary:
	# adjacency_upgrade reactive: when heal fires nearby, apply burn to opponent.
	var ability: Dictionary = { "trigger": "on_heal_applied", "adjacency_upgrade": true,
		"effects": [{ "kind": "apply_status", "status": "burn", "amount": 1, "target": "opponent" }] }
	return _with_ability("player", slot, ability)


func test_adjacency_reactive_fires_when_source_adjacent() -> void:
	FeatureFlags.combat_adjacency = true
	var st: Dictionary = _ember_like(0)  # 2x2 grid: slot 0 neighbors are 1 and 2
	var events: Array = [{ "side": "player", "slot": 1, "damage": 0, "effect": "heal", "is_miss": false }]
	var s: Dictionary = AbilitySystem.resolve_reactive(st, events)
	assert_eq(((s["opponent_statuses"] as Dictionary)["burn"] as Dictionary)["stacks"] as int, 1)


func test_adjacency_reactive_blocked_when_source_not_adjacent() -> void:
	FeatureFlags.combat_adjacency = true
	var st: Dictionary = _ember_like(0)  # slot 3 is diagonal to slot 0 — not adjacent
	var events: Array = [{ "side": "player", "slot": 3, "damage": 0, "effect": "heal", "is_miss": false }]
	var s: Dictionary = AbilitySystem.resolve_reactive(st, events)
	assert_eq(((s["opponent_statuses"] as Dictionary)["burn"] as Dictionary)["stacks"] as int, 0)


func test_adjacency_ignored_when_flag_off() -> void:
	FeatureFlags.combat_adjacency = false
	var st: Dictionary = _ember_like(0)
	var events: Array = [{ "side": "player", "slot": 3, "damage": 0, "effect": "heal", "is_miss": false }]
	var s: Dictionary = AbilitySystem.resolve_reactive(st, events)
	assert_eq(((s["opponent_statuses"] as Dictionary)["burn"] as Dictionary)["stacks"] as int, 1)
	FeatureFlags.combat_adjacency = true  # restore default


func test_global_reactive_ignores_slot_distance() -> void:
	# A non-adjacency reactive fires regardless of where the source is.
	FeatureFlags.combat_adjacency = true
	var ability: Dictionary = { "trigger": "on_burn_applied",
		"effects": [{ "kind": "deal_damage", "amount": 1, "target": "opponent" }] }
	var st: Dictionary = _with_ability("player", 0, ability)
	var before: int = st["opponent_hp"] as int
	var events: Array = [{ "side": "player", "slot": 3, "damage": 2, "effect": "burn", "is_miss": false }]
	var s: Dictionary = AbilitySystem.resolve_reactive(st, events)
	assert_eq(s["opponent_hp"] as int, before - 1)


# ── typed-trigger events + chance-gated reactives ─────────────────────────────

func test_reactive_handles_typed_trigger_event() -> void:
	# Rust pattern: on_armor_stripped → deal damage. Event carries a trigger, not an effect.
	var ability: Dictionary = { "trigger": "on_armor_stripped",
		"effects": [{ "kind": "deal_damage", "amount": 1, "target": "opponent" }] }
	var st: Dictionary = _with_ability("player", 0, ability)
	var before: int = st["opponent_hp"] as int
	var events: Array = [{ "trigger": "on_armor_stripped", "side": "player", "slot": 1, "is_miss": false }]
	var s: Dictionary = AbilitySystem.resolve_reactive(st, events)
	assert_eq(s["opponent_hp"] as int, before - 1)


func test_reactive_typed_event_without_slot_fires() -> void:
	# on_poison_tick is side-wide (no source slot) — should still fire.
	var ability: Dictionary = { "trigger": "on_poison_tick",
		"effects": [{ "kind": "apply_status", "status": "blind", "amount": 1, "target": "opponent" }] }
	var st: Dictionary = _with_ability("player", 0, ability)
	var events: Array = [{ "trigger": "on_poison_tick", "side": "player", "is_miss": false }]
	var s: Dictionary = AbilitySystem.resolve_reactive(st, events)
	assert_eq(((s["opponent_statuses"] as Dictionary)["blind"] as Dictionary)["percent"] as int, 15)


func test_reactive_chance_zero_never_applies() -> void:
	var ability: Dictionary = { "trigger": "on_poison_tick", "chance": 0,
		"effects": [{ "kind": "apply_status", "status": "blind", "amount": 1, "target": "opponent" }] }
	var st: Dictionary = _with_ability("player", 0, ability)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var events: Array = [{ "trigger": "on_poison_tick", "side": "player", "is_miss": false }]
	var s: Dictionary = AbilitySystem.resolve_reactive(st, events, rng)
	assert_eq(((s["opponent_statuses"] as Dictionary)["blind"] as Dictionary)["percent"] as int, 0)


func test_reactive_chance_hundred_always_applies() -> void:
	var ability: Dictionary = { "trigger": "on_poison_tick", "chance": 100,
		"effects": [{ "kind": "apply_status", "status": "blind", "amount": 1, "target": "opponent" }] }
	var st: Dictionary = _with_ability("player", 0, ability)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var events: Array = [{ "trigger": "on_poison_tick", "side": "player", "is_miss": false }]
	var s: Dictionary = AbilitySystem.resolve_reactive(st, events, rng)
	assert_eq(((s["opponent_statuses"] as Dictionary)["blind"] as Dictionary)["percent"] as int, 15)


# ── circuit breaker (infinite-build guard) ────────────────────────────────────

func test_reactive_circuit_breaker_caps_activations() -> void:
	var ability: Dictionary = { "trigger": "on_damage_dealt",
		"effects": [{ "kind": "deal_damage", "amount": 1, "target": "opponent" }] }
	var st: Dictionary = _with_ability("player", 0, ability)
	st["opponent_hp"] = 100000
	var events: Array = []
	for _i: int in (AbilitySystem.MAX_REACTIONS_PER_TICK + 500):
		events.append({ "side": "player", "slot": 1, "damage": 1, "effect": "", "is_miss": false })
	var s: Dictionary = AbilitySystem.resolve_reactive(st, events)
	# Only MAX activations fire, each dealing 1 — the rest are dropped.
	assert_eq(s["opponent_hp"] as int, 100000 - AbilitySystem.MAX_REACTIONS_PER_TICK)


# ── resolve_periodic ──────────────────────────────────────────────────────────

func test_periodic_does_not_fire_before_interval() -> void:
	var ability: Dictionary = { "trigger": "periodic", "interval_deciseconds": 50,
		"effects": [{ "kind": "apply_status", "status": "shock", "amount": 1, "target": "opponent" }] }
	var s: Dictionary = AbilitySystem.resolve_periodic(_with_ability("player", 0, ability), 4.9)
	assert_eq(((s["opponent_statuses"] as Dictionary)["shock"] as Dictionary)["n"] as int, 0)


func test_periodic_fires_at_interval() -> void:
	var ability: Dictionary = { "trigger": "periodic", "interval_deciseconds": 50,
		"effects": [{ "kind": "apply_status", "status": "shock", "amount": 1, "target": "opponent" }] }
	var st: Dictionary = _with_ability("player", 0, ability)
	var a: Dictionary = AbilitySystem.resolve_periodic(st, 4.9)
	var b: Dictionary = AbilitySystem.resolve_periodic(a, 0.2)  # cumulative 5.1s
	assert_eq(((b["opponent_statuses"] as Dictionary)["shock"] as Dictionary)["n"] as int, 1)


# ── on_hit_status_chances ─────────────────────────────────────────────────────

func test_on_hit_status_chances_aggregates_passive_on_hit() -> void:
	var ability: Dictionary = { "trigger": "passive_on_hit",
		"effects": [{ "status": "weaken", "chance": 15, "target": "opponent" }] }
	var st: Dictionary = _with_ability("player", 0, ability)
	var chances: Array = AbilitySystem.on_hit_status_chances(st["battle_grid"] as Array)
	assert_eq(chances.size(), 1)
	assert_eq((chances[0] as Dictionary)["chance"] as int, 15)
