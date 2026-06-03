class_name BattleSystem

const BATTLE_TIME_LIMIT: float = 30.0


static func create_opponent_grid(round_num: int) -> Array:
	var ids: Array[String] = []
	match round_num:
		1: ids = ["fire", "water"]
		2: ids = ["fire", "water", "air"]
		3: ids = ["fire", "steam", "air", "earth"]
		4: ids = ["lava", "storm", "cloud", "rain"]
		_: ids = ["lava", "lightning", "storm", "volcano"]
	@warning_ignore("integer_division")
	var level: int = 1 + round_num / 4
	var grid: Array = [null, null, null, null]
	for i: int in mini(ids.size(), 4):
		var def: Dictionary = ElementData.find(ids[i]).duplicate()
		def["element_id"] = def["id"]
		def["level"] = level
		grid[i] = def
	return grid


static func compute_opponent_hp(opp_grid: Array) -> int:
	var total: int = 0
	for slot: Variant in opp_grid:
		if slot != null:
			total += (slot as Dictionary).get("damage", 1) as int * 5
	return maxi(total, 15)


static func tick_battle(state: Dictionary, delta: float) -> Dictionary:
	if state["phase"] == "result":
		return state
	var s: Dictionary = state.duplicate(true)
	var events: Array = []
	var use_effects: bool = FeatureFlags.status_effects
	var bstats: Dictionary = s["battle_stats"] as Dictionary

	if use_effects:
		var tick_acc: float = (s["status_tick_timer"] as float) + delta
		while tick_acc >= 1.0:
			tick_acc -= 1.0
			var opp_tick: Dictionary = StatusSystem.tick(s["opponent_statuses"] as Dictionary)
			s["opponent_statuses"] = opp_tick["statuses"] as Dictionary
			s["opponent_hp"] = maxi(0, (s["opponent_hp"] as int) - (opp_tick["damage"] as int))
			var pl_tick: Dictionary = StatusSystem.tick(s["player_statuses"] as Dictionary)
			s["player_statuses"] = pl_tick["statuses"] as Dictionary
			s["player_hp"] = maxi(0, (s["player_hp"] as int) - (pl_tick["damage"] as int))
		s["status_tick_timer"] = tick_acc

	# Reconstruct the seeded combat RNG, advance it through both sides, persist it.
	var combat_rng := RandomNumberGenerator.new()
	combat_rng.state = s["combat_rng_state"] as int
	_tick_side(s, _make_side_ctx(true), delta, events, use_effects, bstats, combat_rng)
	_tick_side(s, _make_side_ctx(false), delta, events, use_effects, bstats, combat_rng)
	s["combat_rng_state"] = combat_rng.state

	# Depth-1 reactive abilities respond to this tick's fire events; periodic
	# abilities advance their own timers.
	s = AbilitySystem.resolve_reactive(s, events)
	s = AbilitySystem.resolve_periodic(s, delta)
	s["battle_events"] = events

	var timer: float = (s["battle_timer"] as float) + delta
	s["battle_timer"] = timer

	if (s["player_hp"] as int) <= 0 or (s["opponent_hp"] as int) <= 0 or timer >= BATTLE_TIME_LIMIT:
		s["phase"] = "result"

	return s


static func _make_side_ctx(is_player: bool) -> Dictionary:
	if is_player:
		return {
			"grid_key": "battle_grid",
			"timers_key": "element_timers",
			"own_statuses_key": "player_statuses",
			"opp_statuses_key": "opponent_statuses",
			"own_hp_key": "player_hp",
			"opp_hp_key": "opponent_hp",
			"side": "player",
			"stats_key": "player",
			"frozen_key": "player_frozen_seconds",
		}
	return {
		"grid_key": "opponent_grid",
		"timers_key": "opponent_timers",
		"own_statuses_key": "opponent_statuses",
		"opp_statuses_key": "player_statuses",
		"own_hp_key": "opponent_hp",
		"opp_hp_key": "player_hp",
		"side": "opponent",
		"stats_key": "opponent",
		"frozen_key": "opponent_frozen_seconds",
	}


static func _tick_side(s: Dictionary, ctx: Dictionary, delta: float, events: Array, use_effects: bool, bstats: Dictionary, combat_rng: RandomNumberGenerator) -> void:
	var own_statuses_key: String = ctx["own_statuses_key"] as String
	var grid: Array = s[ctx["grid_key"] as String] as Array
	var timers: Array = s[ctx["timers_key"] as String] as Array
	var frozen_seconds: Array = s[ctx["frozen_key"] as String] as Array
	var stats: Array = bstats[ctx["stats_key"] as String] as Array

	for i: int in grid.size():
		if grid[i] == null:
			continue
		# Frozen slots are paused: they skip their fire and their cooldown does not
		# advance while the freeze drains down.
		if (frozen_seconds[i] as float) > 0.0:
			frozen_seconds[i] = maxf(0.0, (frozen_seconds[i] as float) - delta)
			continue
		var elem: Dictionary = grid[i] as Dictionary
		var t: float = (timers[i] as float) + delta
		var base_deciseconds: int = elem["cooldown_deciseconds"] as int
		var effective_cooldown_seconds: float
		if use_effects:
			effective_cooldown_seconds = float(StatusSystem.effective_cooldown_deciseconds(base_deciseconds, s[own_statuses_key] as Dictionary)) / 10.0
		else:
			effective_cooldown_seconds = float(base_deciseconds) / 10.0
		if t >= effective_cooldown_seconds:
			t -= effective_cooldown_seconds
			var fire: bool = true
			if use_effects:
				var blind_percent: int = ((s[own_statuses_key] as Dictionary)["blind"] as Dictionary)["percent"] as int
				if blind_percent > 0 and combat_rng.randf() * 100.0 < float(blind_percent):
					fire = false
			if fire:
				# Multicast repeats the full fire block; each repeat is an
				# independent event so synergies trigger once per repeat.
				var repeats: int = 1 + AbilitySystem.multicast_count(elem)
				for _repeat: int in repeats:
					_fire_element_once(s, ctx, elem, i, stats, events, timers, use_effects, combat_rng)
			else:
				events.append({"side": ctx["side"] as String, "slot": i, "damage": 0, "effect": "", "is_miss": true})
		timers[i] = t


# Resolves a single fire of one element: damage hit, event, stats, and on-fire
# effect. Called once per multicast repeat.
static func _fire_element_once(s: Dictionary, ctx: Dictionary, elem: Dictionary, slot_index: int, stats: Array, events: Array, timers: Array, use_effects: bool, combat_rng: RandomNumberGenerator) -> void:
	var own_statuses_key: String = ctx["own_statuses_key"] as String
	var opp_statuses_key: String = ctx["opp_statuses_key"] as String
	var own_hp_key: String = ctx["own_hp_key"] as String
	var opp_hp_key: String = ctx["opp_hp_key"] as String
	var raw: int = ElementData.effective_damage(elem)
	var dmg: int = raw
	if use_effects:
		var hit: Dictionary = StatusSystem.compute_incoming_damage(raw, s[own_statuses_key] as Dictionary, s[opp_statuses_key] as Dictionary)
		dmg = hit["damage"] as int
		s[opp_statuses_key] = hit["defender_statuses"] as Dictionary
	s[opp_hp_key] = maxi(0, (s[opp_hp_key] as int) - dmg)
	var effect_str: String = elem.get("effect", "") as String
	events.append({"side": ctx["side"] as String, "slot": slot_index, "damage": dmg, "effect": effect_str, "is_miss": false})
	var slot_stats: Dictionary = stats[slot_index] as Dictionary
	slot_stats["fires"] = (slot_stats["fires"] as int) + 1
	slot_stats["damage"] = (slot_stats["damage"] as int) + dmg
	if use_effects and elem.has("effect"):
		_apply_element_effect(s, effect_str, own_statuses_key, opp_statuses_key, own_hp_key, timers, dmg)
	# Probabilistic on-hit passives (Dust, Static, Pollen, Flint, Sand), rolled
	# from the seeded RNG in slot order so replays reproduce exactly.
	if use_effects:
		var own_grid: Array = s[ctx["grid_key"] as String] as Array
		for chance_entry: Variant in AbilitySystem.on_hit_status_chances(own_grid):
			var entry: Dictionary = chance_entry as Dictionary
			if combat_rng.randf() * 100.0 < float(entry["chance"] as int):
				var statuses_key: String = own_statuses_key if (entry.get("target", "opponent") as String) == "own" else opp_statuses_key
				var res: Dictionary = StatusSystem.apply_effect(s[statuses_key] as Dictionary, entry["status"] as String)
				s[statuses_key] = res["statuses"] as Dictionary


# dmg_dealt: actual damage that landed (used for leech heal).
static func _apply_element_effect(s: Dictionary, effect: String, own_statuses_key: String, opp_statuses_key: String, own_hp_key: String, timers: Array, dmg_dealt: int) -> void:
	match effect:
		"haste":
			var res: Dictionary = StatusSystem.apply_effect(s[own_statuses_key] as Dictionary, "haste")
			s[own_statuses_key] = res["statuses"] as Dictionary
			var haste_seconds: float = float(StatusSystem.HASTE_REDUCTION_DECISECONDS) / 10.0
			for j: int in timers.size():
				timers[j] = maxf(0.0, (timers[j] as float) - haste_seconds)
		"heal":
			var res: Dictionary = StatusSystem.apply_effect(s[own_statuses_key] as Dictionary, "heal")
			s[own_statuses_key] = res["statuses"] as Dictionary
			s[own_hp_key] = (s[own_hp_key] as int) + (res["hp_delta"] as int)
		"cleanse":
			var res: Dictionary = StatusSystem.apply_effect(s[own_statuses_key] as Dictionary, "cleanse")
			s[own_statuses_key] = res["statuses"] as Dictionary
		"leech":
			s[own_hp_key] = (s[own_hp_key] as int) + dmg_dealt
		_:
			var res: Dictionary = StatusSystem.apply_effect(s[opp_statuses_key] as Dictionary, effect)
			s[opp_statuses_key] = res["statuses"] as Dictionary


# Picks a slot to freeze on the given grid. Prefers any occupied slot other than
# the last one frozen (anti-permalock); only re-freezes the last slot when it is
# the sole occupant. Returns -1 when no slot is occupied.
static func select_freeze_target(grid: Array, last_frozen_slot: int) -> int:
	var occupied: Array[int] = []
	for i: int in grid.size():
		if grid[i] != null:
			occupied.append(i)
	if occupied.is_empty():
		return -1
	for slot: int in occupied:
		if slot != last_frozen_slot:
			return slot
	return occupied[0]


static func compute_result(state: Dictionary) -> String:
	var player_hp: int = state["player_hp"]
	var opp_hp: int = state["opponent_hp"]
	if player_hp > opp_hp:
		return "player_wins"
	elif opp_hp > player_hp:
		return "opponent_wins"
	return "draw"
