class_name PhaseSystem


static func to_battle(state: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	s["phase"] = "battle"
	s["battle_timer"] = 0.0
	s["element_timers"] = [0.0, 0.0, 0.0, 0.0]
	s["opponent_grid"] = BattleSystem.create_opponent_grid(s["round"] as int)
	s["opponent_timers"] = [0.0, 0.0, 0.0, 0.0]
	s["battle_events"] = []
	s["opponent_hp"] = BattleSystem.compute_opponent_hp(s["opponent_grid"])
	s["battle_stats"] = {
		"player": [{"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}],
		"opponent": [{"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}],
	}
	return s


static func advance_round(state: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	s["round"] = (s["round"] as int) + 1
	s["player_hp"] = 30
	s["phase"] = "shop"
	s["battle_events"] = []
	s["shop_items"] = [null, null, null, null, null]
	return s
