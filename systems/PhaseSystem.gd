class_name PhaseSystem


static func to_battle(state: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	s["phase"] = "battle"
	s["battle_timer"] = 0.0
	s["player_hp"] = 30
	s["element_timers"] = [0.0, 0.0, 0.0, 0.0]
	s["opponent_grid"] = BattleSystem.create_opponent_grid(s["round"] as int)
	s["opponent_timers"] = [0.0, 0.0, 0.0, 0.0]
	s["battle_events"] = []
	var opp_hp: int = BattleSystem.compute_opponent_hp(s["opponent_grid"])
	s["opponent_hp"] = opp_hp
	s["opponent_starting_hp"] = opp_hp
	s["battle_stats"] = {
		"player": [{"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}],
		"opponent": [{"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}],
	}
	return s


static func advance_round(state: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	s["round"] = (s["round"] as int) + 1
	s["gold"] = (s["gold"] as int) + 5
	s["battle_events"] = []
	s["shop_items"] = [null, null, null, null, null]

	var player_hp: int = s["player_hp"] as int
	var opp_hp: int = s["opponent_hp"] as int
	var opp_start: int = s["opponent_starting_hp"] as int

	var player_wins: bool = opp_hp <= 0
	if player_wins:
		s["wins"] = (s["wins"] as int) + 1
		if (s["wins"] as int) >= 10:
			s["phase"] = "victory"
			return s
	else:
		var ratio: float = float(opp_hp) / float(maxi(opp_start, 1))
		var lives_lost: int = 1
		if ratio >= 0.70:
			lives_lost = 3
		elif ratio >= 0.30:
			lives_lost = 2
		s["lives"] = (s["lives"] as int) - lives_lost
		if (s["lives"] as int) <= 0:
			s["phase"] = "eliminated"
			return s

	s["phase"] = "shop"
	return s
