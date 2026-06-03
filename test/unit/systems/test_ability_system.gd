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
