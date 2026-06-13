extends GutTest

# EventSystem (ADR 0011): the every-N non-combat choice node. Pure functions over
# GameState — is_event_due / offer / apply_reward, plus the testable grant builder.

const KNOWN_KINDS: Array = ["gold", "bonus_hp", "reroll_discount", "grant_element"]


func _state() -> Dictionary:
	return GameState.create()


func _seeded_rng(value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = value
	return rng


# ── is_event_due ──────────────────────────────────────────────────────────────

func test_event_due_on_a_multiple_round() -> void:
	var s := _state()
	s["round"] = TuningData.EVENT_EVERY_N_ROUNDS  # first due round (>= 2)
	assert_true(EventSystem.is_event_due(s))


func test_event_not_due_off_cycle() -> void:
	var s := _state()
	s["round"] = TuningData.EVENT_EVERY_N_ROUNDS + 1
	assert_false(EventSystem.is_event_due(s))


func test_event_never_due_on_round_one() -> void:
	var s := _state()
	s["round"] = 1
	assert_false(EventSystem.is_event_due(s))


func test_event_not_due_once_consumed_this_round() -> void:
	var s := _state()
	s["round"] = TuningData.EVENT_EVERY_N_ROUNDS
	s["last_event_round"] = TuningData.EVENT_EVERY_N_ROUNDS
	assert_false(EventSystem.is_event_due(s))


# ── offer ───────────────────────────────────────────────────────────────────

func test_offer_returns_offer_count_rewards() -> void:
	var s := _state()
	s["round"] = TuningData.EVENT_EVERY_N_ROUNDS
	assert_eq(EventSystem.offer(s).size(), TuningData.EVENT_OFFER_COUNT)


func test_offer_kinds_are_distinct_and_known() -> void:
	var s := _state()
	s["round"] = TuningData.EVENT_EVERY_N_ROUNDS
	var seen: Dictionary = {}
	for reward: Variant in EventSystem.offer(s):
		var kind: String = (reward as Dictionary)["kind"] as String
		assert_true(kind in KNOWN_KINDS, "unknown kind: " + kind)
		assert_false(seen.has(kind), "duplicate kind: " + kind)
		seen[kind] = true


func test_offer_each_reward_has_label_and_description() -> void:
	var s := _state()
	s["round"] = TuningData.EVENT_EVERY_N_ROUNDS
	for reward: Variant in EventSystem.offer(s):
		assert_true((reward as Dictionary).has("label"))
		assert_true((reward as Dictionary).has("description"))


func test_offer_is_deterministic_per_round() -> void:
	var s := _state()
	s["round"] = TuningData.EVENT_EVERY_N_ROUNDS
	var first: Array = EventSystem.offer(s)
	var second: Array = EventSystem.offer(s)
	assert_eq(first.size(), second.size())
	for i: int in first.size():
		assert_eq((first[i] as Dictionary)["kind"], (second[i] as Dictionary)["kind"])


func test_offer_does_not_mutate_state() -> void:
	var s := _state()
	s["round"] = TuningData.EVENT_EVERY_N_ROUNDS
	EventSystem.offer(s)
	assert_eq(s["last_event_round"] as int, -1)


# ── build_grant_element_reward (tier cap = highest unlocked tier) ─────────────

func test_grant_element_caps_at_tier_one_with_no_discoveries() -> void:
	var reward := EventSystem.build_grant_element_reward(_state(), _seeded_rng(1))
	assert_eq(reward["tier"] as int, 1)
	assert_eq(ElementData.find(reward["element_id"] as String)["tier"] as int, 1)


func test_grant_element_caps_at_highest_unlocked_tier() -> void:
	var s := _state()
	# Three distinct forged T2s unlock T2 in the shop (TIER_UNLOCK_THRESHOLDS[2] = 3).
	s["run_discoveries"] = ["steam", "lava", "dust"]
	var reward := EventSystem.build_grant_element_reward(s, _seeded_rng(1))
	assert_eq(reward["tier"] as int, 2)
	assert_eq(ElementData.find(reward["element_id"] as String)["tier"] as int, 2)


func test_grant_element_drawn_from_eligible_pool() -> void:
	var s := _state()
	s["run_discoveries"] = ["steam", "lava", "dust"]
	var eligible: Array = ShopSystem.eligible_for_tier(s["run_discoveries"] as Array, 2)
	var eligible_ids: Dictionary = {}
	for elem: Variant in eligible:
		eligible_ids[(elem as Dictionary)["id"] as String] = true
	var reward := EventSystem.build_grant_element_reward(s, _seeded_rng(7))
	assert_true(eligible_ids.has(reward["element_id"] as String))


# ── apply_reward: one-shot ────────────────────────────────────────────────────

func test_apply_gold_reward_adds_gold() -> void:
	var s := _state()
	s["gold"] = 4
	var out := EventSystem.apply_reward(s, {"kind": "gold", "amount": 15})
	assert_eq(out["gold"] as int, 19)


func test_apply_grant_element_places_in_inventory() -> void:
	var out := EventSystem.apply_reward(_state(), {"kind": "grant_element", "element_id": "fire", "tier": 1})
	var inv: Array = out["inventory"] as Array
	assert_eq((inv[0] as Dictionary)["element_id"] as String, "fire")
	assert_eq((inv[0] as Dictionary)["level"] as int, 1)


func test_apply_grant_element_does_not_record_run_discovery() -> void:
	var s := _state()
	s["run_discoveries"] = ["steam", "lava", "dust"]
	var out := EventSystem.apply_reward(s, {"kind": "grant_element", "element_id": "rain", "tier": 2})
	# Granting must NOT unlock a shop tier — forging stays the only thing that does.
	assert_false((out["run_discoveries"] as Array).has("rain"))


func test_apply_grant_element_full_inventory_falls_back_to_gold() -> void:
	var s := _state()
	s["gold"] = 0
	var inv: Array = s["inventory"] as Array
	for i: int in inv.size():
		inv[i] = ElementData.find("water").duplicate()
	var out := EventSystem.apply_reward(s, {"kind": "grant_element", "element_id": "fire", "tier": 1})
	assert_eq(out["gold"] as int, ElementData.find("fire")["price"] as int)


# ── apply_reward: persistent Run Modifiers ────────────────────────────────────

func test_apply_bonus_hp_materializes_via_augment() -> void:
	# Persistent rewards are now Augments (ADR 0016): hp_bonus is the materialized sum of
	# every bonus_hp run_state atom, not a directly-incremented field.
	var out := EventSystem.apply_reward(_state(), {"kind": "bonus_hp", "amount": 30})
	assert_eq(out["hp_bonus"] as int, 30)
	assert_eq((out["augments"] as Array).size(), 1)
	assert_eq((out["augments"] as Array)[0]["source_type"] as String, "event_reward")
	# A second grant accumulates through a new Augment.
	var out2 := EventSystem.apply_reward(out, {"kind": "bonus_hp", "amount": 10})
	assert_eq(out2["hp_bonus"] as int, 40)


func test_apply_reroll_discount_materializes_via_augment() -> void:
	var out := EventSystem.apply_reward(_state(), {"kind": "reroll_discount", "amount": 1})
	assert_eq(out["reroll_discount"] as int, 1)
	var out2 := EventSystem.apply_reward(out, {"kind": "reroll_discount", "amount": 1})
	assert_eq(out2["reroll_discount"] as int, 2)


# ── apply_reward: bookkeeping ─────────────────────────────────────────────────

func test_apply_reward_marks_event_consumed() -> void:
	var s := _state()
	s["round"] = TuningData.EVENT_EVERY_N_ROUNDS
	var out := EventSystem.apply_reward(s, {"kind": "gold", "amount": 15})
	assert_eq(out["last_event_round"] as int, TuningData.EVENT_EVERY_N_ROUNDS)
	assert_false(EventSystem.is_event_due(out))


func test_apply_reward_does_not_mutate_input() -> void:
	var s := _state()
	s["gold"] = 4
	EventSystem.apply_reward(s, {"kind": "gold", "amount": 15})
	assert_eq(s["gold"] as int, 4)
	assert_eq(s["last_event_round"] as int, -1)
