extends GutTest


# ── all_elements ──────────────────────────────────────────────────────────────

func test_all_elements_all_have_required_keys() -> void:
	for elem: Dictionary in ElementData.all_elements():
		assert_true(elem.has("id"),       elem.get("id", "?") + " missing 'id'")
		assert_true(elem.has("name"),     elem.get("id", "?") + " missing 'name'")
		assert_true(elem.has("tier"),     elem.get("id", "?") + " missing 'tier'")
		assert_true(elem.has("price"),    elem.get("id", "?") + " missing 'price'")
		assert_true(elem.has("cooldown"), elem.get("id", "?") + " missing 'cooldown'")
		assert_true(elem.has("damage"),   elem.get("id", "?") + " missing 'damage'")


func test_all_elements_tiers_are_in_range_1_to_4() -> void:
	for elem: Dictionary in ElementData.all_elements():
		var t: int = elem["tier"] as int
		assert_true(t >= 1 and t <= 4, elem["id"] + " has tier " + str(t))


func test_all_elements_has_12_tier1_elements() -> void:
	var count: int = 0
	for elem: Dictionary in ElementData.all_elements():
		if (elem["tier"] as int) == 1:
			count += 1
	assert_eq(count, 12)


# ── find ──────────────────────────────────────────────────────────────────────

func test_find_water_returns_correct_element() -> void:
	var elem := ElementData.find("water")
	assert_eq(elem["id"], "water")
	assert_eq(elem["tier"], 1)


func test_find_lava_returns_tier2_element() -> void:
	var elem := ElementData.find("lava")
	assert_eq(elem["id"], "lava")
	assert_eq(elem["tier"], 2)


func test_find_unknown_id_returns_empty_dict() -> void:
	var elem := ElementData.find("nonexistent")
	assert_true(elem.is_empty())


func test_find_does_not_mutate_registry() -> void:
	var a := ElementData.find("fire")
	var b := ElementData.find("fire")
	assert_eq(a["damage"], b["damage"])


func test_find_ids_are_unique() -> void:
	var ids: Array[String] = []
	for elem: Dictionary in ElementData.all_elements():
		var id: String = elem["id"] as String
		assert_false(ids.has(id), "duplicate element id: " + id)
		ids.append(id)


# ── effective_damage ──────────────────────────────────────────────────────────

func test_effective_damage_water_level1() -> void:
	# water: damage=1, tier=1 → 1*1+1 = 2
	var item := ElementData.find("water").duplicate()
	item["level"] = 1
	assert_eq(ElementData.effective_damage(item), 2)


func test_effective_damage_scales_with_level() -> void:
	# water: damage=1, tier=1 → 1*2+1 = 3
	var item := ElementData.find("water").duplicate()
	item["level"] = 2
	assert_eq(ElementData.effective_damage(item), 3)


func test_effective_damage_scales_with_tier() -> void:
	# lava: damage=3, tier=2, level=1 → 3*1+2 = 5
	var item := ElementData.find("lava").duplicate()
	item["level"] = 1
	assert_eq(ElementData.effective_damage(item), 5)


func test_effective_damage_fire_level1() -> void:
	# fire: damage=2, tier=1 → 2*1+1 = 3
	var item := ElementData.find("fire").duplicate()
	item["level"] = 1
	assert_eq(ElementData.effective_damage(item), 3)


func test_t2_elements_all_have_price_8() -> void:
	for elem: Dictionary in ElementData.all_elements():
		if (elem["tier"] as int) == 2:
			assert_eq(elem["price"], 8, elem["id"] + " should cost 8g")
