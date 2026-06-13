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


# The single combat-setup path. Sizes both sides' per-combat fields from their own
# boards (Grid Growth, ADR 0014: the player's count from battle_grid, the opponent's
# from opponent_grid), sets phase, both sides' HP + bar max, seeds the combat RNG, and
# fires combat_start abilities. Mutates and returns `state` (callers pass a duplicate
# or a fresh GameState). Decisions that vary by caller — how HP is scaled, who the
# opponent is, which seed — are made BEFORE this and handed in via `config`:
#   { "player_hp": int, "opponent_hp": int, "combat_seed": int }
# to_battle is the live adapter (round-scaled HP, hash seed, Ghost board); the balance
# harness is the second (mirror HP, sweep seed) — so the harness can't drift into
# measuring a different combat than players fight.
static func begin_combat(state: Dictionary, opponent_grid: Array, config: Dictionary) -> Dictionary:
	var player_count: int = (state["battle_grid"] as Array).size()
	var opponent_count: int = opponent_grid.size()
	# CombatState owns the per-combat shape: every per-slot array, the status pools,
	# and the Battle Summary stat rows, all sized to each side's board.
	state = CombatState.reset(state, player_count, opponent_count)
	state["phase"] = "battle"
	state["opponent_grid"] = opponent_grid
	state["player_hp"] = config["player_hp"] as int
	state["player_starting_hp"] = config["player_hp"] as int
	state["opponent_hp"] = config["opponent_hp"] as int
	state["opponent_starting_hp"] = config["opponent_hp"] as int
	var combat_rng := RandomNumberGenerator.new()
	combat_rng.seed = config["combat_seed"] as int
	state["combat_rng_state"] = combat_rng.state
	return AbilitySystem.resolve_combat_start(state)


static func to_battle(state: Dictionary, opponent_snapshot: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	var opp_grid: Array = opponent_snapshot.get("grid", CombatState.empty_slots()) as Array
	var round_num: int = s["round"] as int
	s["opponent_snapshot"] = opponent_snapshot
	# Live adapter over begin_combat: round-scaled player HP, round-derived opponent HP,
	# and a per-round hash seed so Replay and async Ghost playback reproduce the fight.
	return begin_combat(s, opp_grid, {
		"player_hp": _scaled_player_hp(s),
		"opponent_hp": BattleSystem.compute_opponent_hp(round_num),
		"combat_seed": hash("combat:%d" % round_num),
	})


# Single source of truth for how a finished combat resolves into a Round outcome.
# describe_result (the result screen), advance_round (Run progression), and Battle.gd
# (the achievement event) all read THIS — so the win rule and the Life/wins math live
# in exactly one place and can't drift apart. Pure: never mutates `state`.
#
# Returns:
#   outcome       "player_wins" | "opponent_wins" | "draw"
#   is_win        bool — win or draw (Run-positive); a draw counts as a win
#   wins_after    int  — wins after this Round
#   lives_lost    int  — Life lost this Round (0 on a win/draw)
#   lives_after   int  — Life after this Round
#   is_victory    bool — wins_after reached WIN_THRESHOLD
#   is_eliminated bool — a loss that drove Life to 0
#   next_phase    "shop" | "victory" | "eliminated"
#   event         "round_win" | "round_loss" | "match_win" | "match_eliminated"
static func resolve_round(state: Dictionary) -> Dictionary:
	var outcome: String = BattleSystem.compute_result(state)
	var is_win: bool = outcome == "player_wins" or outcome == "draw"
	var wins: int = state["wins"] as int
	var lives: int = state["lives"] as int
	var lives_lost: int = 0
	if not is_win:
		var opp_hp: int = state["opponent_hp"] as int
		var opp_start: int = state["opponent_starting_hp"] as int
		lives_lost = _lives_lost(float(opp_hp) / float(maxi(opp_start, 1)))
	var wins_after: int = wins + (1 if is_win else 0)
	var lives_after: int = lives - lives_lost
	var is_victory: bool = wins_after >= TuningData.WIN_THRESHOLD
	var is_eliminated: bool = (not is_win) and lives_after <= 0
	var next_phase: String = "shop"
	var event: String = "round_win" if is_win else "round_loss"
	if is_victory:
		next_phase = "victory"
		event = "match_win"
	elif is_eliminated:
		next_phase = "eliminated"
		event = "match_eliminated"
	return {
		"outcome": outcome,
		"is_win": is_win,
		"wins_after": wins_after,
		"lives_lost": lives_lost,
		"lives_after": lives_after,
		"is_victory": is_victory,
		"is_eliminated": is_eliminated,
		"next_phase": next_phase,
		"event": event,
	}


static func advance_round(state: Dictionary) -> Dictionary:
	var outcome: Dictionary = resolve_round(state)
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
	s["wins"] = outcome["wins_after"] as int
	s["lives"] = outcome["lives_after"] as int
	s["phase"] = outcome["next_phase"] as String
	return s


# Render-facing view of the Round outcome — the result screen reads these keys.
# A superset shape (resolve_round) is fine; the view picks the fields it needs.
static func describe_result(state: Dictionary) -> Dictionary:
	return resolve_round(state)


static func forfeit(state: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	s["phase"] = "eliminated"
	return s
