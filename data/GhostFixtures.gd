class_name GhostFixtures


static func get_fixture(shop_tier: int) -> Dictionary:
	match shop_tier:
		1:
			return _tier1()
		2:
			return _tier2()
		_:
			return _tier3()


static func _make_elem(id: String, level: int) -> Dictionary:
	return ElementData.instantiate(id, level)


static func _tier1() -> Dictionary:
	return {
		"player_id": "fixture_t1",
		"player_name": "Ghost [T1]",
		"round": 1,
		"grid": [
			_make_elem("water", 1),
			_make_elem("fire", 1),
			null,
			null,
		],
		"acquired_day": 0,
		"source": "fixture",
	}


static func _tier2() -> Dictionary:
	return {
		"player_id": "fixture_t2",
		"player_name": "Ghost [T2]",
		"round": 3,
		"grid": [
			_make_elem("steam", 1),
			_make_elem("lava", 1),
			_make_elem("rain", 1),
			null,
		],
		"acquired_day": 0,
		"source": "fixture",
	}


static func _tier3() -> Dictionary:
	return {
		"player_id": "fixture_t3",
		"player_name": "Ghost [T3]",
		"round": 5,
		"grid": [
			_make_elem("storm", 1),
			_make_elem("volcano", 1),
			_make_elem("obsidian", 1),
			_make_elem("geyser", 1),
		],
		"acquired_day": 0,
		"source": "fixture",
	}
