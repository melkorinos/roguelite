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
	var pstats: Array = bstats["player"] as Array
	var ostats: Array = bstats["opponent"] as Array

	# Status tick — fires every 1 second, independent of element cooldowns
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

	# Player grid
	var pgrid: Array = s["battle_grid"]
	var ptimers: Array = s["element_timers"]
	for i: int in 4:
		if pgrid[i] == null:
			continue
		var elem: Dictionary = pgrid[i] as Dictionary
		var t: float = (ptimers[i] as float) + delta
		var eff_cd: float = elem["cooldown"] as float
		if use_effects:
			var shock_n: int = ((s["player_statuses"] as Dictionary)["shock"] as Dictionary)["n"] as int
			eff_cd *= (1.0 + StatusSystem.slow_pct(shock_n) / 100.0)
		if t >= eff_cd:
			t -= eff_cd
			var fire: bool = true
			if use_effects:
				var blind_pct: float = ((s["player_statuses"] as Dictionary)["blind"] as Dictionary)["pct"] as float
				if blind_pct > 0.0 and randf() < blind_pct:
					fire = false
			if fire:
				var raw: int = ElementData.effective_damage(elem)
				var dmg: int = raw
				if use_effects:
					var hit: Dictionary = StatusSystem.compute_incoming_damage(raw, s["player_statuses"] as Dictionary, s["opponent_statuses"] as Dictionary)
					dmg = hit["damage"] as int
					s["opponent_statuses"] = hit["defender_statuses"] as Dictionary
				s["opponent_hp"] = maxi(0, (s["opponent_hp"] as int) - dmg)
				events.append({"side": "player", "slot": i})
				var ps: Dictionary = pstats[i] as Dictionary
				ps["fires"] = (ps["fires"] as int) + 1
				ps["damage"] = (ps["damage"] as int) + dmg
				if use_effects and elem.has("effect"):
					_apply_element_effect(s, elem["effect"] as String, true, ptimers, dmg)
		ptimers[i] = t
	s["element_timers"] = ptimers

	# Opponent grid
	var ogrid: Array = s["opponent_grid"]
	var otimers: Array = s["opponent_timers"]
	for i: int in 4:
		if ogrid[i] == null:
			continue
		var elem: Dictionary = ogrid[i] as Dictionary
		var t: float = (otimers[i] as float) + delta
		var eff_cd: float = elem["cooldown"] as float
		if use_effects:
			var shock_n: int = ((s["opponent_statuses"] as Dictionary)["shock"] as Dictionary)["n"] as int
			eff_cd *= (1.0 + StatusSystem.slow_pct(shock_n) / 100.0)
		if t >= eff_cd:
			t -= eff_cd
			var fire: bool = true
			if use_effects:
				var blind_pct: float = ((s["opponent_statuses"] as Dictionary)["blind"] as Dictionary)["pct"] as float
				if blind_pct > 0.0 and randf() < blind_pct:
					fire = false
			if fire:
				var raw: int = ElementData.effective_damage(elem)
				var dmg: int = raw
				if use_effects:
					var hit: Dictionary = StatusSystem.compute_incoming_damage(raw, s["opponent_statuses"] as Dictionary, s["player_statuses"] as Dictionary)
					dmg = hit["damage"] as int
					s["player_statuses"] = hit["defender_statuses"] as Dictionary
				s["player_hp"] = maxi(0, (s["player_hp"] as int) - dmg)
				events.append({"side": "opponent", "slot": i})
				var os: Dictionary = ostats[i] as Dictionary
				os["fires"] = (os["fires"] as int) + 1
				os["damage"] = (os["damage"] as int) + dmg
				if use_effects and elem.has("effect"):
					_apply_element_effect(s, elem["effect"] as String, false, otimers, dmg)
		otimers[i] = t
	s["opponent_timers"] = otimers

	s["battle_events"] = events
	var timer: float = (s["battle_timer"] as float) + delta
	s["battle_timer"] = timer

	if (s["player_hp"] as int) <= 0 or (s["opponent_hp"] as int) <= 0 or timer >= BATTLE_TIME_LIMIT:
		s["phase"] = "result"

	return s


# is_player_side: true = element belongs to player, false = opponent.
# timers: the firing side's timer array (for haste immediate reduction).
# dmg_dealt: actual damage that landed (used for leech heal).
static func _apply_element_effect(s: Dictionary, effect: String, is_player_side: bool, timers: Array, dmg_dealt: int) -> void:
	var own_key: String = "player_statuses" if is_player_side else "opponent_statuses"
	var opp_key: String = "opponent_statuses" if is_player_side else "player_statuses"
	var own_hp_key: String = "player_hp" if is_player_side else "opponent_hp"

	match effect:
		"haste":
			var res: Dictionary = StatusSystem.apply_effect(s[own_key] as Dictionary, "haste")
			s[own_key] = res["statuses"] as Dictionary
			for j: int in timers.size():
				timers[j] = maxf(0.0, (timers[j] as float) - 0.3)
		"heal":
			var res: Dictionary = StatusSystem.apply_effect(s[own_key] as Dictionary, "heal")
			s[own_key] = res["statuses"] as Dictionary
			s[own_hp_key] = (s[own_hp_key] as int) + (res["hp_delta"] as int)
		"cleanse":
			var res: Dictionary = StatusSystem.apply_effect(s[own_key] as Dictionary, "cleanse")
			s[own_key] = res["statuses"] as Dictionary
		"leech":
			s[own_hp_key] = (s[own_hp_key] as int) + dmg_dealt
		_:
			var res: Dictionary = StatusSystem.apply_effect(s[opp_key] as Dictionary, effect)
			s[opp_key] = res["statuses"] as Dictionary


static func compute_result(state: Dictionary) -> String:
	var player_hp: int = state["player_hp"]
	var opp_hp: int = state["opponent_hp"]
	if player_hp > opp_hp:
		return "player_wins"
	elif opp_hp > player_hp:
		return "opponent_wins"
	return "draw"
