class_name EventSystem

# The every-N "Event" — a non-combat choice node between rounds (ADR 0011). Pure
# functions over the GameState dict, mirroring StartSystem / ShopSystem: nothing here
# touches the SceneTree. The Shop shows the offer in a blocking overlay and applies the
# chosen reward back into state.
#
# A reward is a tagged dict {kind, ...params, label, description}. One-shot rewards
# (gold, grant_element) mutate the returned state once; persistent Run Modifiers
# (bonus_hp → hp_bonus, reroll_discount → reroll_discount) increment a discrete field
# that another system already reads each round.
#
# Tuning (interval, offer count, magnitudes) lives in TuningData.EVENT_*.

const KINDS: Array[String] = ["gold", "bonus_hp", "reroll_discount", "grant_element"]


# An Event is due heading into every EVENT_EVERY_N_ROUNDS-th round (round >= 2), until
# its reward is taken (last_event_round marks consumption, surviving Shop re-entry).
static func is_event_due(state: Dictionary) -> bool:
	var n: int = TuningData.EVENT_EVERY_N_ROUNDS
	if n <= 0:
		return false
	var round_num: int = state["round"] as int
	if round_num < 2:
		return false
	if round_num % n != 0:
		return false
	return round_num != (state.get("last_event_round", -1) as int)


# EVENT_OFFER_COUNT distinct reward kinds for this round. Seeded from the round when no
# rng is supplied, so Replay and async Ghost playback reproduce the exact offer. Pure.
static func offer(state: Dictionary, rng: RandomNumberGenerator = null) -> Array[Dictionary]:
	var r: RandomNumberGenerator = rng
	if r == null:
		r = RandomNumberGenerator.new()
		r.seed = hash("event:%d" % (state["round"] as int))
	var kinds: Array[String] = KINDS.duplicate()
	_shuffle(kinds, r)
	var take: int = mini(TuningData.EVENT_OFFER_COUNT, kinds.size())
	var rewards: Array[Dictionary] = []
	for i: int in take:
		rewards.append(_build_reward(state, kinds[i], r))
	return rewards


# A "grant_element" reward, resolved against the player's progression: capped at the
# highest tier they've unlocked (max of ShopSystem.unlocked_tiers) and drawn from that
# tier's family-filtered eligible pool — so it feels like a free pick from their shop.
static func build_grant_element_reward(state: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var run_discoveries: Array = state["run_discoveries"] as Array
	var tiers: Array[int] = ShopSystem.unlocked_tiers(run_discoveries)
	var tier: int = tiers.max() as int
	var pool: Array[Dictionary] = ShopSystem.eligible_for_tier(run_discoveries, tier)
	if pool.is_empty():
		tier = 1
		pool = ShopSystem.eligible_for_tier(run_discoveries, 1)
	var def: Dictionary = pool[rng.randi() % pool.size()] as Dictionary
	return {
		"kind": "grant_element",
		"element_id": def["id"] as String,
		"tier": tier,
		"label": "%s %s" % [def["emoji"] as String, def["name"] as String],
		"description": "Free Tier %d %s straight to your inventory." % [tier, def["name"] as String],
	}


# Applies the chosen reward and marks this round's Event consumed. Pure — returns a new
# state; never mutates the input.
static func apply_reward(state: Dictionary, reward: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	var kind: String = reward["kind"] as String
	match kind:
		"gold":
			s["gold"] = (s["gold"] as int) + (reward["amount"] as int)
		"bonus_hp":
			s["hp_bonus"] = (s.get("hp_bonus", 0) as int) + (reward["amount"] as int)
		"reroll_discount":
			s["reroll_discount"] = (s.get("reroll_discount", 0) as int) + (reward["amount"] as int)
		"grant_element":
			_grant_element(s, reward["element_id"] as String)
	s["last_event_round"] = s["round"] as int
	return s


# ── helpers ───────────────────────────────────────────────────────────────────

# Grants an element to the first empty inventory slot. Full inventory → its gold value
# instead (so the reward is never wasted). Granting never writes run_discoveries: forging
# stays the only thing that unlocks a shop tier (ADR 0007/0011). Mutates `s` (a duplicate).
static func _grant_element(s: Dictionary, element_id: String) -> void:
	var instance: Dictionary = ElementData.instantiate(element_id)
	if instance.is_empty():
		return
	# Full inventory → fall back to the element's gold value so the reward is never wasted.
	if not ShopSystem.grant_to_inventory(s, instance):
		s["gold"] = (s["gold"] as int) + _element_price(instance)


static func _element_price(def: Dictionary) -> int:
	if def.has("price"):
		return def["price"] as int
	var tier: int = def.get("tier", 1) as int
	return TuningData.ELEMENT_PRICE_BY_TIER.get(tier, 5) as int


static func _build_reward(state: Dictionary, kind: String, rng: RandomNumberGenerator) -> Dictionary:
	match kind:
		"gold":
			return {
				"kind": "gold",
				"amount": TuningData.EVENT_GOLD_REWARD,
				"label": "+%d Gold" % TuningData.EVENT_GOLD_REWARD,
				"description": "Spend it in the shop right now.",
			}
		"bonus_hp":
			return {
				"kind": "bonus_hp",
				"amount": TuningData.EVENT_HP_BONUS_REWARD,
				"label": "+%d Max HP" % TuningData.EVENT_HP_BONUS_REWARD,
				"description": "Permanent bonus Player HP, every battle this run.",
			}
		"reroll_discount":
			return {
				"kind": "reroll_discount",
				"amount": TuningData.EVENT_REROLL_DISCOUNT,
				"label": "-%d Reroll Cost" % TuningData.EVENT_REROLL_DISCOUNT,
				"description": "Cheaper shop rerolls for the rest of the run.",
			}
		"grant_element":
			return build_grant_element_reward(state, rng)
	return {}


# In-place Fisher-Yates using the supplied (seeded) rng, so the shuffle is reproducible
# — Array.shuffle() would draw from the unseeded global RNG and break Replay parity.
static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i: int in range(arr.size() - 1, 0, -1):
		var j: int = rng.randi() % (i + 1)
		var tmp: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
