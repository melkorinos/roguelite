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

	_tick_side(s, _make_side_ctx(true), delta, events, use_effects, bstats)
	_tick_side(s, _make_side_ctx(false), delta, events, use_effects, bstats)

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
	}


static func _tick_side(s: Dictionary, ctx: Dictionary, delta: float, events: Array, use_effects: bool, bstats: Dictionary) -> void:
	var own_statuses_key: String = ctx["own_statuses_key"] as String
	var opp_statuses_key: String = ctx["opp_statuses_key"] as String
	var own_hp_key: String = ctx["own_hp_key"] as String
	var opp_hp_key: String = ctx["opp_hp_key"] as String
	var side: String = ctx["side"] as String
	var grid: Array = s[ctx["grid_key"] as String] as Array
	var timers: Array = s[ctx["timers_key"] as String] as Array
	var stats: Array = bstats[ctx["stats_key"] as String] as Array

	for i: int in 4:
		if grid[i] == null:
			continue
		var elem: Dictionary = grid[i] as Dictionary
		var t: float = (timers[i] as float) + delta
		var eff_cd: float = elem["cooldown"] as float
		if use_effects:
			var shock_n: int = ((s[own_statuses_key] as Dictionary)["shock"] as Dictionary)["n"] as int
			eff_cd *= (1.0 + StatusSystem.slow_pct(shock_n) / 100.0)
		if t >= eff_cd:
			t -= eff_cd
			var fire: bool = true
			if use_effects:
				var blind_pct: float = ((s[own_statuses_key] as Dictionary)["blind"] as Dictionary)["pct"] as float
				if blind_pct > 0.0 and randf() < blind_pct:
					fire = false
			if fire:
				var raw: int = ElementData.effective_damage(elem)
				var dmg: int = raw
				if use_effects:
					var hit: Dictionary = StatusSystem.compute_incoming_damage(raw, s[own_statuses_key] as Dictionary, s[opp_statuses_key] as Dictionary)
					dmg = hit["damage"] as int
					s[opp_statuses_key] = hit["defender_statuses"] as Dictionary
				s[opp_hp_key] = maxi(0, (s[opp_hp_key] as int) - dmg)
				var effect_str: String = elem.get("effect", "") as String
				events.append({"side": side, "slot": i, "damage": dmg, "effect": effect_str, "is_miss": false})
				var slot_stats: Dictionary = stats[i] as Dictionary
				slot_stats["fires"] = (slot_stats["fires"] as int) + 1
				slot_stats["damage"] = (slot_stats["damage"] as int) + dmg
				if use_effects and elem.has("effect"):
					_apply_element_effect(s, effect_str, own_statuses_key, opp_statuses_key, own_hp_key, timers, dmg)
			else:
				events.append({"side": side, "slot": i, "damage": 0, "effect": "", "is_miss": true})
		timers[i] = t


# dmg_dealt: actual damage that landed (used for leech heal).
static func _apply_element_effect(s: Dictionary, effect: String, own_statuses_key: String, opp_statuses_key: String, own_hp_key: String, timers: Array, dmg_dealt: int) -> void:
	match effect:
		"haste":
			var res: Dictionary = StatusSystem.apply_effect(s[own_statuses_key] as Dictionary, "haste")
			s[own_statuses_key] = res["statuses"] as Dictionary
			for j: int in timers.size():
				timers[j] = maxf(0.0, (timers[j] as float) - 0.3)
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


static func compute_result(state: Dictionary) -> String:
	var player_hp: int = state["player_hp"]
	var opp_hp: int = state["opponent_hp"]
	if player_hp > opp_hp:
		return "player_wins"
	elif opp_hp > player_hp:
		return "opponent_wins"
	return "draw"
