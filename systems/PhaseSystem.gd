class_name PhaseSystem


static func _lives_lost(ratio: float) -> int:
	if ratio >= 0.70:
		return 30
	elif ratio >= 0.30:
		return 20
	return 10


static func to_battle(state: Dictionary, opponent_snapshot: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	s["phase"] = "battle"
	s["battle_timer"] = 0.0
	s["player_hp"] = 30
	s["element_timers"] = [0.0, 0.0, 0.0, 0.0]
	s["opponent_snapshot"] = opponent_snapshot
	s["opponent_grid"] = opponent_snapshot.get("grid", [null, null, null, null]) as Array
	s["opponent_timers"] = [0.0, 0.0, 0.0, 0.0]
	s["player_frozen_seconds"] = [0.0, 0.0, 0.0, 0.0]
	s["opponent_frozen_seconds"] = [0.0, 0.0, 0.0, 0.0]
	s["player_last_frozen_slot"] = -1
	s["opponent_last_frozen_slot"] = -1
	s["player_ability_timers"] = [0.0, 0.0, 0.0, 0.0]
	s["opponent_ability_timers"] = [0.0, 0.0, 0.0, 0.0]
	# Seed the combat RNG deterministically per round so Replay and async Ghost
	# playback reproduce the exact fight.
	var combat_rng := RandomNumberGenerator.new()
	combat_rng.seed = hash("combat:%d" % (s["round"] as int))
	s["combat_rng_state"] = combat_rng.state
	s["pending_commands"] = []
	s["battle_events"] = []
	var opp_hp: int = BattleSystem.compute_opponent_hp(s["opponent_grid"])
	s["opponent_hp"] = opp_hp
	s["opponent_starting_hp"] = opp_hp
	s["battle_stats"] = {
		"player": [{"fires": 0, "damage": 0, "effects": 0, "effects_by_status": {}}, {"fires": 0, "damage": 0, "effects": 0, "effects_by_status": {}}, {"fires": 0, "damage": 0, "effects": 0, "effects_by_status": {}}, {"fires": 0, "damage": 0, "effects": 0, "effects_by_status": {}}],
		"opponent": [{"fires": 0, "damage": 0, "effects": 0, "effects_by_status": {}}, {"fires": 0, "damage": 0, "effects": 0, "effects_by_status": {}}, {"fires": 0, "damage": 0, "effects": 0, "effects_by_status": {}}, {"fires": 0, "damage": 0, "effects": 0, "effects_by_status": {}}],
	}
	s["player_statuses"] = StatusSystem.empty_statuses()
	s["opponent_statuses"] = StatusSystem.empty_statuses()
	s["status_tick_timer"] = 0.0
	s = AbilitySystem.resolve_combat_start(s)
	return s


static func advance_round(state: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	s["round"] = (s["round"] as int) + 1
	s["gold"] = (s["gold"] as int) + 5
	s["player_hp"] = 30
	s["battle_events"] = []
	s["shop_items"] = [null, null, null, null, null]

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
		s["lives"] = (s["lives"] as int) - _lives_lost(ratio)
		if (s["lives"] as int) <= 0:
			s["phase"] = "eliminated"
			return s

	s["phase"] = "shop"
	return s


static func describe_result(state: Dictionary) -> Dictionary:
	var outcome: String = BattleSystem.compute_result(state)
	var wins: int = state["wins"] as int
	var lives: int = state["lives"] as int
	var opp_hp: int = state["opponent_hp"] as int
	var opp_start: int = state["opponent_starting_hp"] as int
	var lives_lost: int = 0
	var wins_after: int = wins
	if outcome == "player_wins" or outcome == "draw":
		wins_after = wins + 1
	else:
		var ratio: float = float(opp_hp) / float(maxi(opp_start, 1))
		lives_lost = _lives_lost(ratio)
	var lives_after: int = lives - lives_lost
	return {
		"outcome": outcome,
		"wins_after": wins_after,
		"lives_lost": lives_lost,
		"lives_after": lives_after,
		"is_victory": wins_after >= 10,
		"is_eliminated": lives_after <= 0 and outcome == "opponent_wins",
	}


static func forfeit(state: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	s["phase"] = "eliminated"
	return s
