class_name GameState


static func create(seed_recipes: Array[String] = []) -> Dictionary:
	return {
		"phase": "shop",
		"round": 1,
		"player_hp": 30,
		"opponent_hp": 20,
		"gold": 10,
		"inventory": [null, null, null, null, null, null],
		"battle_grid": [null, null, null, null],
		"element_timers": [0.0, 0.0, 0.0, 0.0],
		"opponent_grid": [null, null, null, null],
		"opponent_timers": [0.0, 0.0, 0.0, 0.0],
		"battle_events": [],
		"shop_items": [null, null, null, null, null],
		"shop_tier": 1,
		"discovered_recipes": seed_recipes.duplicate(),
		"battle_timer": 0.0,
		"forge_slots": [null, null],
		"battle_stats": {
			"player": [{"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}],
			"opponent": [{"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}],
		},
		"lives": 10,
		"wins": 0,
		"opponent_starting_hp": 0,
		"opponent_snapshot": {},
		"player_statuses": StatusSystem.empty_statuses(),
		"opponent_statuses": StatusSystem.empty_statuses(),
		"status_tick_timer": 0.0,
	}
