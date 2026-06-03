extends GutTest

# PlayerProfile is registered as an autoload, so 'PlayerProfile' in code
# resolves to the singleton. To test an isolated instance we preload the script
# and call .new() on the GDScript object directly. _ready() does not run because
# we never add_child, so the ConfigFile stays empty and all getters return defaults.

const _script := preload("res://autoloads/PlayerProfile.gd")


func _fresh():
	return _script.new()


# ── section: stats defaults ───────────────────────────────────────────────────

func test_fresh_total_damage_is_zero() -> void:
	assert_eq(_fresh().get_total_damage_dealt(), 0)


func test_fresh_matches_played_is_zero() -> void:
	assert_eq(_fresh().get_matches_played(), 0)


func test_fresh_matches_won_is_zero() -> void:
	assert_eq(_fresh().get_matches_won(), 0)


# ── section: progress defaults ────────────────────────────────────────────────

func test_fresh_achievements_is_empty_array() -> void:
	assert_eq(_fresh().get_achievements_unlocked(), [])


# ── section: discovery defaults ───────────────────────────────────────────────

func test_fresh_discovered_recipes_is_empty_array() -> void:
	assert_eq(_fresh().get_discovered_recipes(), [])


# ── to_dict ───────────────────────────────────────────────────────────────────

func test_to_dict_has_total_damage_key() -> void:
	assert_true(_fresh().to_dict().has("total_damage_dealt"))


func test_to_dict_has_matches_played_key() -> void:
	assert_true(_fresh().to_dict().has("matches_played"))


func test_to_dict_has_matches_won_key() -> void:
	assert_true(_fresh().to_dict().has("matches_won"))


func test_to_dict_has_achievements_unlocked_key() -> void:
	assert_true(_fresh().to_dict().has("achievements_unlocked"))


func test_to_dict_has_discovered_recipes_key() -> void:
	assert_true(_fresh().to_dict().has("discovered_recipes"))


# ── from_dict / to_dict round-trip ────────────────────────────────────────────

func test_from_dict_sets_total_damage() -> void:
	var p = _fresh()
	p.from_dict({"total_damage_dealt": 5000, "matches_played": 0, "matches_won": 0,
		"achievements_unlocked": [], "discovered_recipes": []})
	assert_eq(p.get_total_damage_dealt(), 5000)


func test_from_dict_sets_matches_played() -> void:
	var p = _fresh()
	p.from_dict({"total_damage_dealt": 0, "matches_played": 3, "matches_won": 1,
		"achievements_unlocked": [], "discovered_recipes": []})
	assert_eq(p.get_matches_played(), 3)


func test_from_dict_sets_achievements_unlocked() -> void:
	var p = _fresh()
	p.from_dict({"total_damage_dealt": 0, "matches_played": 0, "matches_won": 0,
		"achievements_unlocked": ["ACH_FIRST_WIN"], "discovered_recipes": []})
	assert_eq(p.get_achievements_unlocked(), ["ACH_FIRST_WIN"])


func test_from_dict_sets_discovered_recipes() -> void:
	var p = _fresh()
	p.from_dict({"total_damage_dealt": 0, "matches_played": 0, "matches_won": 0,
		"achievements_unlocked": [], "discovered_recipes": ["steam", "lava"]})
	assert_eq(p.get_discovered_recipes(), ["steam", "lava"])


func test_to_dict_reflects_from_dict_values() -> void:
	var p = _fresh()
	p.from_dict({"total_damage_dealt": 999, "matches_played": 2, "matches_won": 1,
		"achievements_unlocked": ["ACH_CLUTCH"], "discovered_recipes": ["rain"]})
	var d: Dictionary = p.to_dict()
	assert_eq(d["total_damage_dealt"] as int, 999)
	assert_eq(d["matches_played"] as int, 2)
	assert_eq(d["achievements_unlocked"], ["ACH_CLUTCH"])
	assert_eq(d["discovered_recipes"], ["rain"])


# ── merge_discovered_recipes ──────────────────────────────────────────────────

func test_merge_adds_new_recipes() -> void:
	var p = _fresh()
	p.merge_discovered_recipes(["steam", "lava"])
	assert_eq(p.get_discovered_recipes(), ["steam", "lava"])


func test_merge_deduplicates() -> void:
	var p = _fresh()
	p.merge_discovered_recipes(["steam"])
	p.merge_discovered_recipes(["steam", "lava"])
	var recipes: Array = p.get_discovered_recipes()
	var count: int = 0
	for r: Variant in recipes:
		if r == "steam":
			count += 1
	assert_eq(count, 1)


func test_merge_preserves_existing_recipes() -> void:
	var p = _fresh()
	p.from_dict({"total_damage_dealt": 0, "matches_played": 0, "matches_won": 0,
		"achievements_unlocked": [], "discovered_recipes": ["mud"]})
	p.merge_discovered_recipes(["lava"])
	assert_true("mud" in p.get_discovered_recipes())
	assert_true("lava" in p.get_discovered_recipes())


# ── unlock_achievement ────────────────────────────────────────────────────────

func test_unlock_achievement_adds_id() -> void:
	var p = _fresh()
	p.unlock_achievement("ACH_FIRST_WIN")
	assert_true("ACH_FIRST_WIN" in p.get_achievements_unlocked())


func test_unlock_achievement_does_not_duplicate() -> void:
	var p = _fresh()
	p.unlock_achievement("ACH_FIRST_WIN")
	p.unlock_achievement("ACH_FIRST_WIN")
	var count: int = 0
	for a: Variant in p.get_achievements_unlocked():
		if a == "ACH_FIRST_WIN":
			count += 1
	assert_eq(count, 1)
