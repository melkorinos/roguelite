class_name GameState


static func create() -> Dictionary:
	return {
		"phase": "game",
		"player_position": Vector2(400.0, 300.0),
		"player_speed": 200.0,
		"player_hp": 30,
	}
