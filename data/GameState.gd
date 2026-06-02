class_name GameState


static func create() -> Dictionary:
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
		"discovered_recipes": [],
		"battle_timer": 0.0,
		"forge_slots": [null, null],
		"battle_stats": {
			"player": [{"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}],
			"opponent": [{"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}, {"fires": 0, "damage": 0}],
		},
	}
