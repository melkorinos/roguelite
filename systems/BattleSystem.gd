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

	var bstats: Dictionary = s["battle_stats"] as Dictionary
	var pstats: Array = bstats["player"] as Array
	var ostats: Array = bstats["opponent"] as Array

	# Player grid
	var pgrid: Array = s["battle_grid"]
	var ptimers: Array = s["element_timers"]
	for i: int in 4:
		if pgrid[i] == null:
			continue
		var elem: Dictionary = pgrid[i] as Dictionary
		var t: float = (ptimers[i] as float) + delta
		if t >= (elem["cooldown"] as float):
			t -= (elem["cooldown"] as float)
			var dmg: int = ElementData.effective_damage(elem)
			s["opponent_hp"] = maxi(0, (s["opponent_hp"] as int) - dmg)
			events.append({"side": "player", "slot": i})
			var ps: Dictionary = pstats[i] as Dictionary
			ps["fires"] = (ps["fires"] as int) + 1
			ps["damage"] = (ps["damage"] as int) + dmg
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
		if t >= (elem["cooldown"] as float):
			t -= (elem["cooldown"] as float)
			var dmg: int = ElementData.effective_damage(elem)
			s["player_hp"] = maxi(0, (s["player_hp"] as int) - dmg)
			events.append({"side": "opponent", "slot": i})
			var os: Dictionary = ostats[i] as Dictionary
			os["fires"] = (os["fires"] as int) + 1
			os["damage"] = (os["damage"] as int) + dmg
		otimers[i] = t
	s["opponent_timers"] = otimers

	s["battle_events"] = events
	var timer: float = (s["battle_timer"] as float) + delta
	s["battle_timer"] = timer

	if (s["player_hp"] as int) <= 0 or (s["opponent_hp"] as int) <= 0 or timer >= BATTLE_TIME_LIMIT:
		s["phase"] = "result"

	return s


static func compute_result(state: Dictionary) -> String:
	var player_hp: int = state["player_hp"]
	var opp_hp: int = state["opponent_hp"]
	if player_hp > opp_hp:
		return "player_wins"
	elif opp_hp > player_hp:
		return "opponent_wins"
	return "draw"
