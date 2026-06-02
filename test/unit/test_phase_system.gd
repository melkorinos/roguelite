extends GutTest


func _make_state() -> Dictionary:
	return GameState.create()


func test_to_battle_sets_phase() -> void:
	var s := PhaseSystem.to_battle(_make_state())
	assert_eq(s["phase"], "battle")


func test_to_battle_resets_timer() -> void:
	var state := _make_state()
	state["battle_timer"] = 7.5
	var s := PhaseSystem.to_battle(state)
	assert_eq(s["battle_timer"], 0.0)


func test_to_battle_preserves_gold() -> void:
	var state := _make_state()
	state["gold"] = 7
	var s := PhaseSystem.to_battle(state)
	assert_eq(s["gold"], 7)


func test_to_battle_does_not_mutate_original() -> void:
	var state := _make_state()
	PhaseSystem.to_battle(state)
	assert_eq(state["phase"], "shop")


func test_advance_round_increments_round() -> void:
	var state := _make_state()
	state["round"] = 3
	var s := PhaseSystem.advance_round(state)
	assert_eq(s["round"], 4)


func test_advance_round_resets_player_hp() -> void:
	var state := _make_state()
	state["player_hp"] = 12
	var s := PhaseSystem.advance_round(state)
	assert_eq(s["player_hp"], 30)


func test_advance_round_sets_phase_to_shop() -> void:
	var state := _make_state()
	state["phase"] = "result"
	var s := PhaseSystem.advance_round(state)
	assert_eq(s["phase"], "shop")


func test_advance_round_does_not_mutate_original() -> void:
	var state := _make_state()
	state["round"] = 2
	PhaseSystem.advance_round(state)
	assert_eq(state["round"], 2)
