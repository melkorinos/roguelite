extends GutTest


# ── all_elements ──────────────────────────────────────────────────────────────

func test_all_elements_all_have_required_keys() -> void:
	for elem: Dictionary in ElementData.all_elements():
		assert_true(elem.has("id"),       elem.get("id", "?") + " missing 'id'")
		assert_true(elem.has("name"),     elem.get("id", "?") + " missing 'name'")
		assert_true(elem.has("tier"),     elem.get("id", "?") + " missing 'tier'")
		assert_true(elem.has("price"),    elem.get("id", "?") + " missing 'price'")
		assert_true(elem.has("cooldown_deciseconds"), elem.get("id", "?") + " missing 'cooldown_deciseconds'")
		assert_true(elem.has("damage"),   elem.get("id", "?") + " missing 'damage'")


func test_all_cooldowns_are_integer_deciseconds() -> void:
	for elem: Dictionary in ElementData.all_elements():
		var value: Variant = elem["cooldown_deciseconds"]
		assert_true(value is int, elem["id"] + " cooldown_deciseconds must be an int (no decimals)")
		assert_true((value as int) >= 10, elem["id"] + " cooldown_deciseconds below the 10-decisecond floor")


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

func test_effective_damage_pure_effect_is_zero() -> void:
	# Water is pure-effect (not in DAMAGE_DEALERS) → no direct hit damage.
	assert_eq(ElementData.effective_damage(ElementData.instantiate("water", 1)), 0)


func test_effective_damage_fire_is_pure_effect() -> void:
	assert_eq(ElementData.effective_damage(ElementData.instantiate("fire", 2)), 0)


func test_effective_damage_dealer_is_base_times_level() -> void:
	# Lava is a damage-dealer (base 3); no tier chip → base × level.
	# base 3 × level × T2 tier multiplier 1.5 (TIER_POTENCY_MULTIPLIER)
	assert_eq(ElementData.effective_damage(ElementData.instantiate("lava", 1)), 5)
	assert_eq(ElementData.effective_damage(ElementData.instantiate("lava", 2)), 9)


# Archetype integrity: every damage-dealer is a real T2+ element with base damage.
# Blood (T1) is an intentional exception — its leech mechanic requires a direct hit.
const _DAMAGE_DEALER_T1_EXCEPTIONS: Dictionary = { "blood": true }
func test_damage_dealers_are_tier2_plus_with_base_damage() -> void:
	for id: Variant in ElementData.DAMAGE_DEALERS:
		var def: Dictionary = ElementData.find(id as String)
		assert_false(def.is_empty(), "unknown damage-dealer id: " + (id as String))
		if not _DAMAGE_DEALER_T1_EXCEPTIONS.has(id as String):
			assert_gte(def["tier"] as int, 2, (id as String) + " should be T2+")
		assert_gt(def["damage"] as int, 0, (id as String) + " needs base damage")


func test_t2_elements_all_have_price_8() -> void:
	for elem: Dictionary in ElementData.all_elements():
		if (elem["tier"] as int) == 2:
			assert_eq(elem["price"], 8, elem["id"] + " should cost 8g")


# ── canonical_family (ADR-0017) ───────────────────────────────────────────────

const _BASE_FAMILIES: Array[String] = [
	"fire", "water", "earth", "air", "lightning", "nature",
	"light", "dark", "metal", "fungus", "blood", "frost",
]


func test_canonical_family_tier1_element_is_its_own_family() -> void:
	# A Tier-1 element's id IS its family — no explicit tag needed.
	assert_eq(ElementData.canonical_family("fire"), "fire")
	assert_eq(ElementData.canonical_family("water"), "water")
	assert_eq(ElementData.canonical_family("fungus"), "fungus")


func test_canonical_family_reads_tagged_field_for_forged_elements() -> void:
	assert_eq(ElementData.canonical_family("lava"), "fire")
	assert_eq(ElementData.canonical_family("steam"), "water")
	assert_eq(ElementData.canonical_family("volcano"), "fire")
	assert_eq(ElementData.canonical_family("supernova"), "light")


func test_canonical_family_unknown_element_is_empty() -> void:
	assert_eq(ElementData.canonical_family("not_an_element"), "")


func test_every_canonical_family_is_a_known_base_family_or_empty() -> void:
	# Untagged T2+ elements return "" until the pass-2 tagging lands; any non-empty
	# value must be one of the 12 base families.
	for elem: Dictionary in ElementData.all_elements():
		var fam: String = ElementData.canonical_family(elem["id"] as String)
		if fam != "":
			assert_true(_BASE_FAMILIES.has(fam), elem["id"] + " has unknown family '" + fam + "'")


# ── stat_pods (Element Card §B pod rule, ADR-0017) ─────────────────────────────

func test_stat_pods_dealer_shows_cooldown_and_damage() -> void:
	# Lava is a damage-dealer → [CD, DMG]. CD = 50ds / 10 = 5.0s; DMG = effective_damage L1 = 5.
	var pods: Array[Dictionary] = ElementData.stat_pods(ElementData.instantiate("lava", 1))
	assert_eq(pods.size(), 2)
	assert_eq(pods[0]["value"], "5.0s")
	assert_eq(pods[0]["label"], "CD")
	assert_eq(pods[1]["value"], "5")
	assert_eq(pods[1]["label"], "DMG")


func test_stat_pods_tier1_applier_shows_status_pod() -> void:
	# Fire (T1, pure-effect) applies its `effect` keyword each activation → [CD, STATUS].
	# Base amount 1 × scaled_potency(1, 1) = 1; the status pod is highlighted.
	var pods: Array[Dictionary] = ElementData.stat_pods(ElementData.instantiate("fire", 1))
	assert_eq(pods.size(), 2)
	assert_eq(pods[0]["label"], "CD")
	assert_eq(pods[1]["value"], "1")
	assert_eq(pods[1]["label"], "burn")
	assert_true(pods[1]["highlight"] as bool)


func test_stat_pods_tier2_on_activate_applier_scales_status_by_potency() -> void:
	# Solar (T2, on_activate) applies 1 [burn] from AbilityData.effects[0]. The card
	# shows the LANDED amount = base 1 × scaled_potency(2, 1) = 2.
	var pods: Array[Dictionary] = ElementData.stat_pods(ElementData.instantiate("solar", 1))
	assert_eq(pods.size(), 2)
	assert_eq(pods[1]["value"], "2")
	assert_eq(pods[1]["label"], "burn")
	assert_true(pods[1]["highlight"] as bool)


func test_stat_pods_reactive_pure_effect_is_cooldown_only() -> void:
	# Steam (T2, on_burn_applied) output is conditional — a static number would lie,
	# so the card shows CD only and the ability text carries the trigger.
	var pods: Array[Dictionary] = ElementData.stat_pods(ElementData.instantiate("steam", 1))
	assert_eq(pods.size(), 1)
	assert_eq(pods[0]["label"], "CD")


func test_stat_pods_combat_start_is_cooldown_only() -> void:
	# Smoke (T2, combat_start) fires once at setup → CD only.
	var pods: Array[Dictionary] = ElementData.stat_pods(ElementData.instantiate("smoke", 1))
	assert_eq(pods.size(), 1)
	assert_eq(pods[0]["label"], "CD")


func test_stat_pods_tier1_dealer_prefers_damage_over_status() -> void:
	# Blood is the lone T1 damage-dealer AND carries effect "leech"; the DMG pod wins.
	var pods: Array[Dictionary] = ElementData.stat_pods(ElementData.instantiate("blood", 1))
	assert_eq(pods.size(), 2)
	assert_eq(pods[1]["label"], "DMG")
