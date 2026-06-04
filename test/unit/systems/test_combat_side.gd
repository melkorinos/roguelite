extends GutTest


func test_opponent_of_player_is_opponent() -> void:
	assert_eq(CombatSide.opponent_of("player"), "opponent")


func test_opponent_of_opponent_is_player() -> void:
	assert_eq(CombatSide.opponent_of("opponent"), "player")


func test_keys_player_maps_to_player_state() -> void:
	var k: Dictionary = CombatSide.keys("player")
	assert_eq(k["grid"] as String, "battle_grid")
	assert_eq(k["statuses"] as String, "player_statuses")
	assert_eq(k["hp"] as String, "player_hp")
	assert_eq(k["frozen"] as String, "player_frozen_seconds")
	assert_eq(k["ability_timers"] as String, "player_ability_timers")


func test_keys_opponent_maps_to_opponent_state() -> void:
	var k: Dictionary = CombatSide.keys("opponent")
	assert_eq(k["grid"] as String, "opponent_grid")
	assert_eq(k["timers"] as String, "opponent_timers")
	assert_eq(k["last_frozen"] as String, "opponent_last_frozen_slot")


func test_grid_getter_reads_the_side_grid() -> void:
	var state: Dictionary = GameState.create()
	state["battle_grid"][0] = { "element_id": "fire" }
	assert_eq((CombatSide.grid(state, "player")[0] as Dictionary)["element_id"] as String, "fire")


func test_statuses_getter_reads_the_side_statuses() -> void:
	var state: Dictionary = GameState.create()
	assert_eq(((CombatSide.statuses(state, "opponent"))["shock"] as Dictionary)["n"] as int, 0)
