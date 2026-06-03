extends GutTest


func _empty_profile() -> Dictionary:
	return {
		"total_damage_dealt": 0,
		"matches_played": 0,
		"matches_won": 0,
		"achievements_unlocked": [],
		"discovered_recipes": [],
	}


func _state_with_hp(player_hp: int) -> Dictionary:
	var s := GameState.create()
	s["player_hp"] = player_hp
	return s


func _state_with_wins(wins: int) -> Dictionary:
	var s := GameState.create()
	s["wins"] = wins
	return s


func _state_with_battle_damage(dmg: int) -> Dictionary:
	var s := GameState.create()
	var pstats: Array = (s["battle_stats"] as Dictionary)["player"] as Array
	(pstats[0] as Dictionary)["damage"] = dmg
	return s


# ── does not mutate input profile ─────────────────────────────────────────────

func test_check_does_not_mutate_input_profile() -> void:
	var p := _empty_profile()
	AchievementSystem.evaluate(GameState.create(), p, "round_win")
	assert_eq(p["achievements_unlocked"], [])


# ── ACH_FIRST_WIN ─────────────────────────────────────────────────────────────

func test_ach_first_win_unlocked_on_round_win() -> void:
	var out := AchievementSystem.evaluate(GameState.create(), _empty_profile(), "round_win")
	assert_true("ACH_FIRST_WIN" in (out["achievements_unlocked"] as Array))


func test_ach_first_win_not_duplicated_on_second_win() -> void:
	var p := _empty_profile()
	p["achievements_unlocked"] = ["ACH_FIRST_WIN"]
	var out := AchievementSystem.evaluate(GameState.create(), p, "round_win")
	var count: int = 0
	for ach: Variant in out["achievements_unlocked"] as Array:
		if ach == "ACH_FIRST_WIN":
			count += 1
	assert_eq(count, 1)


func test_ach_first_win_not_unlocked_on_round_loss() -> void:
	var out := AchievementSystem.evaluate(GameState.create(), _empty_profile(), "round_loss")
	assert_false("ACH_FIRST_WIN" in (out["achievements_unlocked"] as Array))


# ── ACH_FIRST_FORGE ───────────────────────────────────────────────────────────

func test_ach_first_forge_unlocked_on_forge_discovered() -> void:
	var out := AchievementSystem.evaluate(GameState.create(), _empty_profile(), "forge_discovered")
	assert_true("ACH_FIRST_FORGE" in (out["achievements_unlocked"] as Array))


func test_ach_first_forge_not_unlocked_on_other_events() -> void:
	var out := AchievementSystem.evaluate(GameState.create(), _empty_profile(), "round_win")
	assert_false("ACH_FIRST_FORGE" in (out["achievements_unlocked"] as Array))


# ── ACH_CLUTCH ────────────────────────────────────────────────────────────────

func test_ach_clutch_unlocked_when_winning_at_5_hp() -> void:
	var out := AchievementSystem.evaluate(_state_with_hp(5), _empty_profile(), "round_win")
	assert_true("ACH_CLUTCH" in (out["achievements_unlocked"] as Array))


func test_ach_clutch_unlocked_when_winning_at_1_hp() -> void:
	var out := AchievementSystem.evaluate(_state_with_hp(1), _empty_profile(), "round_win")
	assert_true("ACH_CLUTCH" in (out["achievements_unlocked"] as Array))


func test_ach_clutch_not_unlocked_when_winning_at_6_hp() -> void:
	var out := AchievementSystem.evaluate(_state_with_hp(6), _empty_profile(), "round_win")
	assert_false("ACH_CLUTCH" in (out["achievements_unlocked"] as Array))


func test_ach_clutch_not_unlocked_on_loss_even_at_low_hp() -> void:
	var out := AchievementSystem.evaluate(_state_with_hp(1), _empty_profile(), "round_loss")
	assert_false("ACH_CLUTCH" in (out["achievements_unlocked"] as Array))


# ── ACH_SURVIVOR ──────────────────────────────────────────────────────────────

func test_ach_survivor_unlocked_on_elimination_with_3_wins() -> void:
	var out := AchievementSystem.evaluate(_state_with_wins(3), _empty_profile(), "match_eliminated")
	assert_true("ACH_SURVIVOR" in (out["achievements_unlocked"] as Array))


func test_ach_survivor_unlocked_with_more_than_3_wins() -> void:
	var out := AchievementSystem.evaluate(_state_with_wins(7), _empty_profile(), "match_eliminated")
	assert_true("ACH_SURVIVOR" in (out["achievements_unlocked"] as Array))


func test_ach_survivor_not_unlocked_with_only_2_wins() -> void:
	var out := AchievementSystem.evaluate(_state_with_wins(2), _empty_profile(), "match_eliminated")
	assert_false("ACH_SURVIVOR" in (out["achievements_unlocked"] as Array))


func test_ach_survivor_not_unlocked_on_match_win_event() -> void:
	var out := AchievementSystem.evaluate(_state_with_wins(5), _empty_profile(), "match_win")
	assert_false("ACH_SURVIVOR" in (out["achievements_unlocked"] as Array))


# ── ACH_DAMAGE_20K ────────────────────────────────────────────────────────────

func test_ach_damage_20k_unlocked_when_total_reaches_20000() -> void:
	var p := _empty_profile()
	p["total_damage_dealt"] = 19990
	var s := _state_with_battle_damage(10)
	var out := AchievementSystem.evaluate(s, p, "round_win")
	assert_true("ACH_DAMAGE_20K" in (out["achievements_unlocked"] as Array))


func test_ach_damage_20k_not_unlocked_before_reaching_20000() -> void:
	var p := _empty_profile()
	p["total_damage_dealt"] = 100
	var s := _state_with_battle_damage(50)
	var out := AchievementSystem.evaluate(s, p, "round_win")
	assert_false("ACH_DAMAGE_20K" in (out["achievements_unlocked"] as Array))


# ── damage accumulation ───────────────────────────────────────────────────────

func test_damage_accumulates_on_round_win() -> void:
	var s := _state_with_battle_damage(100)
	var out := AchievementSystem.evaluate(s, _empty_profile(), "round_win")
	assert_eq(out["total_damage_dealt"] as int, 100)


func test_damage_accumulates_on_round_loss() -> void:
	var s := _state_with_battle_damage(75)
	var out := AchievementSystem.evaluate(s, _empty_profile(), "round_loss")
	assert_eq(out["total_damage_dealt"] as int, 75)


func test_damage_does_not_accumulate_on_forge_discovered() -> void:
	var s := _state_with_battle_damage(999)
	var out := AchievementSystem.evaluate(s, _empty_profile(), "forge_discovered")
	assert_eq(out["total_damage_dealt"] as int, 0)


func test_damage_adds_to_existing_total() -> void:
	var p := _empty_profile()
	p["total_damage_dealt"] = 500
	var s := _state_with_battle_damage(200)
	var out := AchievementSystem.evaluate(s, p, "round_win")
	assert_eq(out["total_damage_dealt"] as int, 700)


# ── discovered_recipes merge ──────────────────────────────────────────────────

func test_recipes_merged_from_state_into_profile() -> void:
	var s := GameState.create()
	s["discovered_recipes"] = ["steam", "lava"]
	var out := AchievementSystem.evaluate(s, _empty_profile(), "round_win")
	assert_true("steam" in (out["discovered_recipes"] as Array))
	assert_true("lava" in (out["discovered_recipes"] as Array))


func test_recipes_merge_deduplicates() -> void:
	var s := GameState.create()
	s["discovered_recipes"] = ["steam"]
	var p := _empty_profile()
	p["discovered_recipes"] = ["steam"]
	var out := AchievementSystem.evaluate(s, p, "round_win")
	var count: int = 0
	for r: Variant in out["discovered_recipes"] as Array:
		if r == "steam":
			count += 1
	assert_eq(count, 1)


func test_recipes_from_profile_preserved_when_state_has_none() -> void:
	var p := _empty_profile()
	p["discovered_recipes"] = ["lava"]
	var out := AchievementSystem.evaluate(GameState.create(), p, "round_win")
	assert_true("lava" in (out["discovered_recipes"] as Array))
