extends GutTest

# Layer 3: invariant / property sims (the highest-leverage layer the handoff calls for).
# Instead of one hand-built fight, these run a CORPUS of seeded random boards through the
# deterministic combat backend and assert a rule that must hold for EVERY fight. A wrong
# invariant yields false failures, so each is designed to be exactly true in a controlled
# domain and is proven against the live roster here.
#
# Determinism note: the "random" boards come from a test-side seeded RNG (fixed seeds), so
# the corpus is reproducible in CI — no live randomness. Sandstorm is deliberately out of
# scope (its true damage is uncredited by design); every sim stays inside a pre-storm window
# with both sides at HP high enough that nobody dies (overkill would clamp HP below the
# credited contribution and break conservation — see CLAUDE.md / handoff).


# An opponent that does nothing, so the only thing moving opponent_hp is the player's board.
func _idle_opponent() -> Dictionary:
	return { "grid": [null, null, null, null], "round": 1 }


# A player GameState whose board is filled from `ids`, one element per slot.
func _build(ids: Array) -> Dictionary:
	var s: Dictionary = GameState.create()
	var grid: Array = s["battle_grid"] as Array
	for i: int in mini(ids.size(), grid.size()):
		grid[i] = ElementData.instantiate(ids[i] as String, 1)
	return s


# A full board of `SLOT_COUNT` element ids picked deterministically from the whole roster.
func _random_board(seed_value: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var ids: Array = []
	for def: Variant in ElementData.ELEMENTS:
		ids.append((def as Dictionary)["id"] as String)
	var board: Array = []
	for _i: int in CombatState.SLOT_COUNT:
		board.append(ids[rng.randi() % ids.size()])
	return board


# Faithful fixed-step driver (matches simulate_battle's cadence) so DOT ticks land on
# their real 1 s beat instead of collapsing into one big step.
func _advance(state: Dictionary, seconds: float) -> Dictionary:
	var elapsed: float = 0.0
	while elapsed < seconds and (state["phase"] as String) != "result":
		state = BattleSystem.tick_battle(state, BattleSystem.COMBAT_STEP_SECONDS)
		elapsed += BattleSystem.COMBAT_STEP_SECONDS
	return state


# Total HP-magnitude the player's board is credited with on the opponent: direct hits +
# poison + burn + curse-amplification. summary_rows already folds exactly these four
# buckets into row["damage"] (the Summary-bug fix), so this is the single number the HUD
# would show.
func _player_credited(state: Dictionary) -> int:
	var total: int = 0
	for row: Dictionary in BattleSystem.summary_rows(state, "player"):
		total += row["damage"] as int
	return total


# ── (F) HP conservation ───────────────────────────────────────────────────────
# THE invariant that would have caught the bug that started this batch (a poison element
# that dealt damage but reported 0): over any fight against an idle, never-dying opponent,
# the HP removed from the opponent equals the contribution credited to the player's board.
# If a damage source ever stops being credited, this fails immediately and broadly.
func test_opponent_hp_loss_equals_credited_player_contribution() -> void:
	for case_index: int in 24:
		var ids: Array = _random_board(1000 + case_index)
		var state: Dictionary = PhaseSystem.to_battle(_build(ids), _idle_opponent())
		# Lift the opponent far above any 12 s damage so nobody dies (no overkill clamp) and
		# the Sandstorm (30 s) never starts within the window.
		state["opponent_hp"] = 100000
		state["opponent_starting_hp"] = 100000
		# Baseline captures any combat_start-trigger contribution that fired during to_battle,
		# BEFORE we reset HP — so the delta below counts only what happens during _advance.
		var baseline_credited: int = _player_credited(state)
		var start_hp: int = state["opponent_hp"] as int
		state = _advance(state, 12.0)
		var removed: int = start_hp - (state["opponent_hp"] as int)
		var credited: int = _player_credited(state) - baseline_credited
		assert_eq(removed, credited,
			"board %d: opponent HP removed (%d) must equal credited player contribution (%d)" % [case_index, removed, credited])


# A guard on the harness itself: the corpus must actually exercise damage (otherwise the
# conservation test passes vacuously at 0 == 0 on every board). At least one board must
# move the opponent's HP within the window.
func test_corpus_actually_deals_damage() -> void:
	var any_damage: bool = false
	for case_index: int in 24:
		var state: Dictionary = PhaseSystem.to_battle(_build(_random_board(1000 + case_index)), _idle_opponent())
		state["opponent_hp"] = 100000
		state["opponent_starting_hp"] = 100000
		state = _advance(state, 12.0)
		if (state["opponent_hp"] as int) < 100000:
			any_damage = true
			break
	assert_true(any_damage, "the random corpus should produce at least one damaging fight")
