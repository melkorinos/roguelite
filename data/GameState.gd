class_name GameState


static func create() -> Dictionary:
	return {
		"phase": "shop",
		"round": 1,
		"player_hp": 30,
		"opponent_hp": 20,
		"gold": 10,
		"inventory": [null, null, null, null, null],
		"shop_items": [],
		"battle_timer": 0.0,
		"sandstorm_fired": false,
	}
