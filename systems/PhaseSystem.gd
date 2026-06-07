class_name PhaseSystem


# Life lost on a defeat, proportional to how much opponent HP remained (0..1):
# a blowout costs MAX_LIFE_LOSS, a razor-thin loss costs almost nothing. No floor.
# Ratio is clamped so loss never exceeds MAX_LIFE_LOSS (defends against degenerate
# opponent_starting_hp values).
static func _lives_lost(ratio: float) -> int:
	return int(round(clampf(ratio, 0.0, 1.0) * float(TuningData.MAX_LIFE_LOSS)))


# Player HP for a combat: a round-scaled base plus any reward bonus (hp_bonus).
static func _scaled_player_hp(state: Dictionary) -> int:
	var round_num: int = state["round"] as int
	return TuningData.BASE_PLAYER_HP + (round_num - 1) * TuningData.HP_PER_ROUND + (state.get("hp_bonus", 0) as int)


static func to_battle(state: Dictionary, opponent_snapshot: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	# CombatState owns the per-combat shape: every per-slot array, the status
	# pools, and the Battle Summary stat rows, all sized to the board.
	s = CombatState.reset(s)
	s["phase"] = "battle"
	s["player_hp"] = _scaled_player_hp(s)
	s["player_starting_hp"] = s["player_hp"]
	s["opponent_snapshot"] = opponent_snapshot
	s["opponent_grid"] = opponent_snapshot.get("grid", CombatState.empty_slots()) as Array
	# Seed the combat RNG deterministically per round so Replay and async Ghost
	# playback reproduce the exact fight.
	var combat_rng := RandomNumberGenerator.new()
	combat_rng.seed = hash("combat:%d" % (s["round"] as int))
	s["combat_rng_state"] = combat_rng.state
	var opp_hp: int = BattleSystem.compute_opponent_hp(s["opponent_grid"])
	s["opponent_hp"] = opp_hp
	s["opponent_starting_hp"] = opp_hp
	s = AbilitySystem.resolve_combat_start(s)
	return s


static func advance_round(state: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	s["round"] = (s["round"] as int) + 1
	s["gold"] = (s["gold"] as int) + TuningData.GOLD_PER_ROUND
	s["player_hp"] = _scaled_player_hp(s)
	# Keep the HP-bar max in step with the (round-scaled) next-combat HP, so the shop
	# never shows current > max (e.g. 33/30 after round 1). Re-set per combat in to_battle.
	s["player_starting_hp"] = s["player_hp"]
	s["battle_events"] = []
	s["shop_items"] = CombatState.empty_slots(TuningData.SHOP_SLOT_COUNT)
	s["reroll_count"] = 0  # reroll cost escalates within a phase; reset each round

	var opp_hp: int = s["opponent_hp"] as int
	var opp_start: int = s["opponent_starting_hp"] as int

	var player_wins: bool = opp_hp <= 0
	if player_wins:
		s["wins"] = (s["wins"] as int) + 1
		if (s["wins"] as int) >= TuningData.WIN_THRESHOLD:
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
		"is_victory": wins_after >= TuningData.WIN_THRESHOLD,
		"is_eliminated": lives_after <= 0 and outcome == "opponent_wins",
	}


static func forfeit(state: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	s["phase"] = "eliminated"
	return s
