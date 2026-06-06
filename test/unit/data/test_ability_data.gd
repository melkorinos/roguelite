extends GutTest

const ALLOWED_TRIGGERS: Array = [
	"combat_start", "periodic", "passive", "passive_on_hit", "on_activate",
	"on_burn_applied", "on_heal_applied", "on_leech", "on_damage_dealt", "on_status_applied",
	"on_poison_tick", "on_burn_tick", "on_armor_stripped", "on_haste_applied",
]
const INTEGER_KEYS: Array = ["amount", "deciseconds", "chance", "interval_deciseconds", "multicast", "count", "every_n"]


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


func test_every_ability_has_description() -> void:
	# Description-only entries are allowed (T1 elements and not-yet-implemented
	# placeholders carry tooltip text without a trigger). Any entry that declares
	# effects, however, must declare the trigger that fires them.
	for element_id: String in AbilityData.ABILITIES.keys():
		var ability: Dictionary = AbilityData.ABILITIES[element_id] as Dictionary
		assert_true((ability.get("description", "") as String) != "", element_id + " missing description")
		if ability.has("effects"):
			assert_true((ability.get("trigger", "") as String) != "", element_id + " has effects but no trigger")


func test_every_trigger_is_allowed() -> void:
	for element_id: String in AbilityData.ABILITIES.keys():
		var ability: Dictionary = AbilityData.ABILITIES[element_id] as Dictionary
		if not ability.has("trigger"):
			continue
		var trigger: String = ability["trigger"] as String
		assert_true(ALLOWED_TRIGGERS.has(trigger), element_id + " has invalid trigger: " + trigger)


func test_periodic_abilities_declare_an_interval() -> void:
	for element_id: String in AbilityData.ABILITIES.keys():
		var ability: Dictionary = AbilityData.ABILITIES[element_id] as Dictionary
		if (ability.get("trigger", "") as String) == "periodic":
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

func test_get_ability_returns_description_only_for_tier1() -> void:
	# T1 elements carry a description for the Abilities Panel but no trigger/effects —
	# their on-fire Action lives in the element's "effect" field, applied by BattleSystem.
	var fire: Dictionary = AbilityData.get_ability("fire")
	assert_false(fire.is_empty(), "T1 should carry a description entry")
	assert_eq(fire.get("trigger", "") as String, "", "T1 ability should declare no trigger")
	assert_false(fire.has("effects"), "T1 ability should declare no effects")


func test_get_ability_returns_empty_for_unknown() -> void:
	assert_true(AbilityData.get_ability("nonexistent").is_empty())


func test_get_ability_returns_steam_definition() -> void:
	assert_eq(AbilityData.get_ability("steam")["trigger"] as String, "on_burn_applied")


func test_formerly_stubbed_abilities_now_resolve() -> void:
	# These 10 were description-only / absent until 2026-06-05. Each must now carry
	# a trigger + effects so it actually does something in combat.
	for element_id: String in ["shrapnel", "rootrot", "gore", "rot", "moldsteel",
			"rainbow", "plant", "ash", "ancientgrove", "voidrift"]:
		var ability: Dictionary = AbilityData.get_ability(element_id)
		assert_true((ability.get("trigger", "") as String) != "", element_id + " should declare a trigger")
		assert_true((ability.get("effects", []) as Array).size() > 0, element_id + " should declare effects")


func test_shrapnel_gates_shock_every_third_activation() -> void:
	var shrapnel: Dictionary = AbilityData.get_ability("shrapnel")
	assert_eq(shrapnel["trigger"] as String, "on_activate")
	assert_eq(shrapnel["every_n"] as int, 3)


func test_gore_pairs_leech_action_with_weaken_ability() -> void:
	# Gore's true lifesteal rides the legacy on-fire Action (effect:"leech", heal =
	# damage dealt); its [weaken] rides the on_activate ability. Both must be present.
	assert_eq(ElementData.find("gore").get("effect", "") as String, "leech")
	var ability: Dictionary = AbilityData.get_ability("gore")
	assert_eq(ability["trigger"] as String, "on_activate")


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
