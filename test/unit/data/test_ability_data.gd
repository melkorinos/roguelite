extends GutTest

const ALLOWED_TRIGGERS: Array = [
	"combat_start", "periodic", "passive", "passive_on_hit",
	"on_burn_applied", "on_heal_applied", "on_leech", "on_damage_dealt", "on_status_applied",
	"on_poison_tick", "on_burn_tick", "on_armor_stripped", "on_haste_applied",
]
const INTEGER_KEYS: Array = ["amount", "deciseconds", "chance", "interval_deciseconds", "multicast", "count"]


func _valid_ids() -> Dictionary:
	var ids: Dictionary = {}
	for elem: Dictionary in ElementData.all_elements():
		ids[elem["id"] as String] = true
	return ids


# ── keys + shape ──────────────────────────────────────────────────────────────

func test_all_ability_keys_are_real_element_ids() -> void:
	var valid: Dictionary = _valid_ids()
	for element_id: String in AbilityData.ABILITIES.keys():
		assert_true(valid.has(element_id), "ability for unknown element id: " + element_id)


func test_every_ability_has_trigger_and_description() -> void:
	for element_id: String in AbilityData.ABILITIES.keys():
		var ability: Dictionary = AbilityData.ABILITIES[element_id] as Dictionary
		assert_true((ability.get("trigger", "") as String) != "", element_id + " missing trigger")
		assert_true((ability.get("description", "") as String) != "", element_id + " missing description")


func test_every_trigger_is_allowed() -> void:
	for element_id: String in AbilityData.ABILITIES.keys():
		var trigger: String = (AbilityData.ABILITIES[element_id] as Dictionary)["trigger"] as String
		assert_true(ALLOWED_TRIGGERS.has(trigger), element_id + " has invalid trigger: " + trigger)


func test_periodic_abilities_declare_an_interval() -> void:
	for element_id: String in AbilityData.ABILITIES.keys():
		var ability: Dictionary = AbilityData.ABILITIES[element_id] as Dictionary
		if (ability["trigger"] as String) == "periodic":
			assert_true((ability.get("interval_deciseconds", 0) as int) > 0, element_id + " periodic without interval")


func test_no_decimal_values_anywhere() -> void:
	for element_id: String in AbilityData.ABILITIES.keys():
		var ability: Dictionary = AbilityData.ABILITIES[element_id] as Dictionary
		for key: String in INTEGER_KEYS:
			if ability.has(key):
				assert_true(ability[key] is int, element_id + "." + key + " must be int")
		for effect: Variant in ability.get("effects", []) as Array:
			var e: Dictionary = effect as Dictionary
			for key: String in INTEGER_KEYS:
				if e.has(key):
					assert_true(e[key] is int, element_id + " effect." + key + " must be int")


func test_all_targets_are_own_or_opponent() -> void:
	for element_id: String in AbilityData.ABILITIES.keys():
		for effect: Variant in (AbilityData.ABILITIES[element_id] as Dictionary).get("effects", []) as Array:
			var e: Dictionary = effect as Dictionary
			if e.has("target"):
				var target: String = e["target"] as String
				assert_true(target == "own" or target == "opponent", element_id + " bad target: " + target)


# ── get_ability ───────────────────────────────────────────────────────────────

func test_get_ability_returns_empty_for_tier1() -> void:
	assert_true(AbilityData.get_ability("fire").is_empty())


func test_get_ability_returns_empty_for_unknown() -> void:
	assert_true(AbilityData.get_ability("nonexistent").is_empty())


func test_get_ability_returns_steam_definition() -> void:
	assert_eq(AbilityData.get_ability("steam")["trigger"] as String, "on_burn_applied")


func test_no_tier4_ability_defined() -> void:
	# T4 is intentionally stubbed this session.
	for elem: Dictionary in ElementData.all_elements():
		if (elem["tier"] as int) == 4:
			assert_true(AbilityData.get_ability(elem["id"] as String).is_empty(), elem["id"] + " T4 should be stubbed")


# ── integration through to_battle ─────────────────────────────────────────────

func _battle_with_player(element_id: String) -> Dictionary:
	var st: Dictionary = GameState.create()
	var elem: Dictionary = ElementData.find(element_id).duplicate()
	elem["element_id"] = element_id
	elem["level"] = 1
	st["battle_grid"][0] = elem
	return PhaseSystem.to_battle(st, GhostFixtures.get_fixture(1))


func test_boulder_grants_armor_at_combat_start() -> void:
	var s: Dictionary = _battle_with_player("boulder")
	assert_eq(((s["player_statuses"] as Dictionary)["armor"] as Dictionary)["value"] as int, 4)


func test_mud_penalizes_opponent_cooldown_at_combat_start() -> void:
	var s: Dictionary = _battle_with_player("mud")
	assert_eq((s["opponent_statuses"] as Dictionary)["cooldown_modifier_deciseconds"] as int, 8)
