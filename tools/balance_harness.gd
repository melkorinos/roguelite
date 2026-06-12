extends SceneTree

# Monte Carlo element-strength harness (2026-06-12).
#
#   godot --headless -s tools/balance_harness.gd
#
# Run from POWERSHELL (godot is on the system PATH there, not in bash).
# Takes ~12-18 minutes at the default sample counts — run it in the background.
# Fully deterministic: reruns reproduce the same numbers exactly.
#
# Mirror-pool, tier-pure, Lv1 (design choices 2026-06-12): for every element,
# sample random 2x3 (6-slot) boards of its own tier, fight a random same-tier
# opponent board, then refight the IDENTICAL matchup with the element swapped
# for a random same-tier replacement -- same combat seed, so the delta isolates
# the element. Win value: win 1.0 / draw 0.5 / loss 0.0.
#
#   replacement delta  = mean(win_with - win_replaced)   <- the strength number
#   contrib breakdown  = the element's own HP-impact ledger (explains why)
#
# Also fights a cross-tier board matrix to verify the tier power-step itself.
# Fully deterministic: every board, slot, replacement, and combat seed derives
# from string hashes -- reruns reproduce exactly.
#
# Sides are equalized at MIRROR_HP before combat_start fires (to_battle's
# round-1 HP is asymmetric, 130 vs 100, which would bias every mirror fight),
# so the combat state is built here instead of via PhaseSystem.to_battle.
#
# Output: res://.claude/ai-helper/diagrams/_element_strength.json
# Render:  python .claude/ai-helper/diagrams/_build_element_strength.py

const SAMPLES_PER_ELEMENT: int = 60
const CROSS_TIER_FIGHTS: int = 100
const BOARD_SLOTS: int = 6
const MIRROR_HP: int = 130
const OUT_PATH: String = "res://.claude/ai-helper/diagrams/_element_strength.json"


func _initialize() -> void:
	var started_msec: int = Time.get_ticks_msec()
	var pools: Dictionary = _tier_pools()
	var element_rows: Array = []
	for tier: int in [1, 2, 3, 4]:
		var pool: Array = pools[tier] as Array
		for element_id: String in pool:
			element_rows.append(_evaluate_element(element_id, tier, pool))
			print("measured %s (T%d)" % [element_id, tier])
	var matrix: Dictionary = _cross_tier_matrix(pools)
	var elapsed_seconds: float = float(Time.get_ticks_msec() - started_msec) / 1000.0
	var payload: Dictionary = {
		"samples_per_element": SAMPLES_PER_ELEMENT,
		"cross_tier_fights": CROSS_TIER_FIGHTS,
		"board_slots": BOARD_SLOTS,
		"mirror_hp": MIRROR_HP,
		"elapsed_seconds": elapsed_seconds,
		"elements": element_rows,
		"tier_matrix": matrix,
	}
	var file: FileAccess = FileAccess.open(OUT_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload, "  "))
	file.close()
	print("wrote %s in %.1fs" % [OUT_PATH, elapsed_seconds])
	quit(0)


func _tier_pools() -> Dictionary:
	var pools: Dictionary = { 1: [], 2: [], 3: [], 4: [] }
	for element: Dictionary in ElementData.all_elements():
		(pools[element["tier"] as int] as Array).append(element["id"] as String)
	return pools


# -- per-element measurement ----------------------------------------------------

func _evaluate_element(element_id: String, tier: int, pool: Array) -> Dictionary:
	var delta_sum: float = 0.0
	var win_with_sum: float = 0.0
	var contrib_sum: Dictionary = { "direct": 0, "poison": 0, "burn": 0, "heal": 0, "blocked": 0 }
	var fires_sum: int = 0
	for i: int in SAMPLES_PER_ELEMENT:
		var rng: RandomNumberGenerator = _rng("ctx:%s:%d" % [element_id, i])
		var slot: int = rng.randi_range(0, BOARD_SLOTS - 1)
		var own_board: Array = _random_board(pool, rng)
		own_board[slot] = ElementData.instantiate(element_id, 1)
		var opponent_board: Array = _random_board(pool, rng)
		var replacement_id: String = _pick_other(pool, element_id, rng)
		var replaced_board: Array = own_board.duplicate(true)
		replaced_board[slot] = ElementData.instantiate(replacement_id, 1)
		var combat_seed: int = hash("fight:%s:%d" % [element_id, i])
		var with_result: Dictionary = _fight(own_board, opponent_board, combat_seed)
		var replaced_result: Dictionary = _fight(replaced_board, opponent_board, combat_seed)
		var win_with: float = with_result["win"] as float
		delta_sum += win_with - (replaced_result["win"] as float)
		win_with_sum += win_with
		var row: Dictionary = ((with_result["state"] as Dictionary)["battle_stats"] as Dictionary)["player"][slot] as Dictionary
		var contrib: Dictionary = row["contrib"] as Dictionary
		for key: String in contrib_sum:
			contrib_sum[key] = (contrib_sum[key] as int) + (contrib[key] as int)
		fires_sum += row["fires"] as int
	var n: float = float(SAMPLES_PER_ELEMENT)
	var avg_contrib: Dictionary = {}
	for key: String in contrib_sum:
		avg_contrib[key] = float(contrib_sum[key] as int) / n
	return {
		"id": element_id,
		"tier": tier,
		"delta": delta_sum / n,
		"win_with": win_with_sum / n,
		"contrib": avg_contrib,
		"fires": float(fires_sum) / n,
	}


# -- cross-tier power-step matrix -------------------------------------------------

func _cross_tier_matrix(pools: Dictionary) -> Dictionary:
	var matrix: Dictionary = {}
	for tier_a: int in [1, 2, 3, 4]:
		var row: Dictionary = {}
		for tier_b: int in [1, 2, 3, 4]:
			var win_sum: float = 0.0
			for i: int in CROSS_TIER_FIGHTS:
				var rng: RandomNumberGenerator = _rng("xt:%d:%d:%d" % [tier_a, tier_b, i])
				var board_a: Array = _random_board(pools[tier_a] as Array, rng)
				var board_b: Array = _random_board(pools[tier_b] as Array, rng)
				var result: Dictionary = _fight(board_a, board_b, hash("xtf:%d:%d:%d" % [tier_a, tier_b, i]))
				win_sum += result["win"] as float
			row[str(tier_b)] = win_sum / float(CROSS_TIER_FIGHTS)
		matrix[str(tier_a)] = row
		print("cross-tier row T%d done" % tier_a)
	return matrix


# -- fight plumbing ---------------------------------------------------------------

func _rng(seed_string: String) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(seed_string)
	return rng


func _random_board(pool: Array, rng: RandomNumberGenerator) -> Array:
	var board: Array = []
	for _i: int in BOARD_SLOTS:
		board.append(ElementData.instantiate(pool[rng.randi_range(0, pool.size() - 1)] as String, 1))
	return board


func _pick_other(pool: Array, element_id: String, rng: RandomNumberGenerator) -> String:
	var pick: String = pool[rng.randi_range(0, pool.size() - 1)] as String
	while pick == element_id:
		pick = pool[rng.randi_range(0, pool.size() - 1)] as String
	return pick


# Mirrors PhaseSystem.to_battle but with symmetric HP (set BEFORE combat_start so
# add_max_hp abilities still count) and a caller-supplied combat seed.
func _fight(player_board: Array, opponent_board: Array, combat_seed: int) -> Dictionary:
	var state: Dictionary = GameState.create()
	state["battle_grid"] = player_board.duplicate(true)
	state = CombatState.reset(state, BOARD_SLOTS, BOARD_SLOTS)
	state["phase"] = "battle"
	state["player_hp"] = MIRROR_HP
	state["player_starting_hp"] = MIRROR_HP
	state["opponent_hp"] = MIRROR_HP
	state["opponent_starting_hp"] = MIRROR_HP
	state["opponent_grid"] = opponent_board.duplicate(true)
	var combat_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	combat_rng.seed = combat_seed
	state["combat_rng_state"] = combat_rng.state
	state = AbilitySystem.resolve_combat_start(state)
	state = BattleSystem.simulate_battle(state)
	var outcome: String = BattleSystem.compute_result(state)
	var win: float = 0.0
	if outcome == "player_wins":
		win = 1.0
	elif outcome == "draw":
		win = 0.5
	return { "win": win, "state": state }
