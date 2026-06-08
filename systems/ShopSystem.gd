class_name ShopSystem

# ── Discovery-gated, family-filtered shop pool (ADR 0007) ────────────────────
# T1 is always offered (the exploration + forge-fuel layer). A higher tier unlocks
# only after the player has FORGED enough distinct elements of that tier this run;
# once unlocked, it shows only elements from the "families" the player forged with
# (the ingredient types one tier down). Tuning values move to a consolidated tuning
# file later (see handoff-run-loop.md).

# Tiers currently purchasable given this run's forge discoveries. T1 is always in.
# Unlock thresholds live in TuningData.TIER_UNLOCK_THRESHOLDS.
static func unlocked_tiers(run_discoveries: Array) -> Array[int]:
	var counts: Dictionary = { 2: 0, 3: 0, 4: 0 }
	for id: Variant in run_discoveries:
		var tier: int = ElementData.find(id as String).get("tier", 0) as int
		if counts.has(tier):
			counts[tier] = (counts[tier] as int) + 1
	var unlocked: Array[int] = [1]
	for tier: int in [2, 3, 4]:
		if (counts[tier] as int) >= (TuningData.TIER_UNLOCK_THRESHOLDS[tier] as int):
			unlocked.append(tier)
	return unlocked


# The "families" the player has engaged at a tier = the union of ingredient ids
# (one tier down) across every element of that tier they've forged this run.
static func _families_for_tier(run_discoveries: Array, tier: int) -> Dictionary:
	var families: Dictionary = {}
	for id: Variant in run_discoveries:
		var elem_id: String = id as String
		if (ElementData.find(elem_id).get("tier", 0) as int) != tier:
			continue
		for ingredient: String in RecipeData.ingredients_of(elem_id):
			families[ingredient] = true
	return families


# Eligible elements of a tier for this run's shop. T1 = the full pool. Higher tiers
# = elements that share at least one ingredient (one tier down) with the player's
# forged elements of that tier — i.e. the families they are building into.
static func eligible_for_tier(run_discoveries: Array, tier: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if tier == 1:
		for elem: Dictionary in ElementData.all_elements():
			if (elem["tier"] as int) == 1:
				result.append(elem)
		return result
	var families: Dictionary = _families_for_tier(run_discoveries, tier)
	for elem: Dictionary in ElementData.all_elements():
		if (elem["tier"] as int) != tier:
			continue
		for ingredient: String in RecipeData.ingredients_of(elem["id"] as String):
			if families.has(ingredient):
				result.append(elem)
				break
	return result


# Picks up to `count` elements from `source`, preferring distinct families (no shared
# ingredient) and avoiding duplicate elements; relaxes both when the pool is small.
static func _pick_spread(source: Array, count: int) -> Array[Dictionary]:
	var picks: Array[Dictionary] = []
	if source.is_empty():
		return picks
	var shuffled: Array = source.duplicate()
	shuffled.shuffle()
	var used_families: Dictionary = {}
	var used_ids: Dictionary = {}
	# Pass 1: distinct families, distinct elements.
	for elem_v: Variant in shuffled:
		if picks.size() >= count:
			break
		var elem: Dictionary = elem_v as Dictionary
		var elem_id: String = elem["id"] as String
		if used_ids.has(elem_id):
			continue
		var overlap: bool = false
		var ingredients: Array[String] = RecipeData.ingredients_of(elem_id)
		for ingredient: String in ingredients:
			if used_families.has(ingredient):
				overlap = true
				break
		if overlap:
			continue
		picks.append(elem)
		used_ids[elem_id] = true
		for ingredient: String in ingredients:
			used_families[ingredient] = true
	# Pass 2: fill remaining with any not-yet-used element (allow family overlap).
	for elem_v: Variant in shuffled:
		if picks.size() >= count:
			break
		var elem2: Dictionary = elem_v as Dictionary
		if not used_ids.has(elem2["id"] as String):
			picks.append(elem2)
			used_ids[elem2["id"] as String] = true
	# Pass 3: pool smaller than count → allow duplicates to fill the shop row.
	while picks.size() < count and not shuffled.is_empty():
		picks.append(shuffled[randi() % shuffled.size()] as Dictionary)
	return picks


# Moves an item from one location to another.
# from_loc / to_loc: {"zone": "shop"|"inventory"|"grid", "slot": int}
# slot = -1 in to_loc means "first empty slot" in that zone.
static func transfer(state: Dictionary, from_loc: Dictionary, to_loc: Dictionary) -> Dictionary:
	var from_zone: String = from_loc["zone"] as String
	var from_slot: int = from_loc["slot"] as int
	var to_zone: String = to_loc["zone"] as String
	var to_slot: int = to_loc["slot"] as int

	if to_slot == -1:
		var target_arr: Array = state["inventory"] if to_zone == "inventory" else state["battle_grid"]
		to_slot = _first_empty_slot(target_arr)
		if to_slot == -1:
			return state

	if from_zone == "shop" and to_zone == "inventory":
		return _buy_into(state, from_slot, "inventory", to_slot)
	if from_zone == "shop" and to_zone == "grid":
		return _buy_into(state, from_slot, "battle_grid", to_slot)
	if from_zone == "inventory" and to_zone == "grid":
		return _swap_arrays(state, "inventory", from_slot, "battle_grid", to_slot)
	if from_zone == "grid" and to_zone == "inventory":
		return _swap_arrays(state, "battle_grid", from_slot, "inventory", to_slot)
	if from_zone == "grid" and to_zone == "grid":
		return _swap_arrays(state, "battle_grid", from_slot, "battle_grid", to_slot)
	return state


# Higher-level shop intake. Resolves a drag-drop between two locations and reports
# WHAT happened, so the scene renders feedback (sound, undo) without re-deriving it
# by diffing gold or counting items. Owns the merge-vs-swap decision that used to
# live in Shop.gd. Mirrors ForgeSystem.attempt's {state, outcome} shape.
#
# outcome ∈ "bought"  — shop element placed into an empty slot (gold spent)
#         | "merged"  — two same-element/level pieces combined to level+1
#                       (includes buying onto a matching level-1 piece)
#         | "swapped" — pieces moved or exchanged, no level change
#         | "rejected"— nothing changed (no gold, full, invalid, not mergeable)
static func resolve_drop(state: Dictionary, from_loc: Dictionary, to_loc: Dictionary) -> Dictionary:
	var from_zone: String = from_loc["zone"] as String
	var to_zone: String = to_loc["zone"] as String
	var from_slot: int = from_loc["slot"] as int
	var to_slot: int = to_loc["slot"] as int

	if to_slot == -1:
		var target_arr: Array = state["inventory"] if to_zone == "inventory" else state["battle_grid"]
		to_slot = _first_empty_slot(target_arr)
		if to_slot == -1:
			return {"state": state, "outcome": "rejected"}
	var resolved_to: Dictionary = {"zone": to_zone, "slot": to_slot}

	# Shop purchase — buy into an empty slot, or buy onto a matching level-1 (merge to 2).
	if from_zone == "shop":
		if not can_transfer(state, from_loc, resolved_to):
			return {"state": state, "outcome": "rejected"}
		var dest_arr: Array = state["inventory"] if to_zone == "inventory" else state["battle_grid"]
		var merging: bool = to_slot >= 0 and to_slot < dest_arr.size() and dest_arr[to_slot] != null
		return {"state": transfer(state, from_loc, resolved_to), "outcome": "merged" if merging else "bought"}

	# Inventory → inventory: merge only (a non-mergeable drop is a no-op).
	if from_zone == "inventory" and to_zone == "inventory":
		if _mergeable(state["inventory"] as Array, from_slot, to_slot):
			var merged: Dictionary = ForgeSystem.attempt(state, {"kind": "merge", "zone": "inventory", "a": from_slot, "b": to_slot})
			return {"state": merged["state"], "outcome": "merged"}
		return {"state": state, "outcome": "rejected"}

	# Grid → grid: merge a matching pair, otherwise swap positions.
	if from_zone == "grid" and to_zone == "grid":
		if _mergeable(state["battle_grid"] as Array, from_slot, to_slot):
			var merged: Dictionary = ForgeSystem.attempt(state, {"kind": "merge", "zone": "grid", "a": from_slot, "b": to_slot})
			return {"state": merged["state"], "outcome": "merged"}
		return {"state": transfer(state, from_loc, resolved_to), "outcome": "swapped"}

	# Inventory ↔ grid: move / swap.
	if (from_zone == "inventory" and to_zone == "grid") or (from_zone == "grid" and to_zone == "inventory"):
		return {"state": transfer(state, from_loc, resolved_to), "outcome": "swapped"}

	return {"state": state, "outcome": "rejected"}


# Two slots in the same array hold the same element at the same level → mergeable.
static func _mergeable(arr: Array, slot_a: int, slot_b: int) -> bool:
	if slot_a < 0 or slot_b < 0 or slot_a >= arr.size() or slot_b >= arr.size() or slot_a == slot_b:
		return false
	var ea: Variant = arr[slot_a]
	var eb: Variant = arr[slot_b]
	if ea == null or eb == null:
		return false
	var da: Dictionary = ea as Dictionary
	var db: Dictionary = eb as Dictionary
	if (da.get("element_id", "") as String) != (db.get("element_id", "") as String):
		return false
	return (da["level"] as int) == (db["level"] as int)


static func can_transfer(state: Dictionary, from_loc: Dictionary, to_loc: Dictionary) -> bool:
	var from_zone: String = from_loc["zone"] as String
	var from_slot: int = from_loc["slot"] as int
	var to_zone: String = to_loc["zone"] as String
	var to_slot: int = to_loc["slot"] as int

	if from_zone == "shop":
		var shop_items: Array = state["shop_items"] as Array
		if from_slot < 0 or from_slot >= shop_items.size():
			return false
		var item: Variant = shop_items[from_slot]
		if item == null:
			return false
		var elem: Dictionary = item as Dictionary
		if (state["gold"] as int) < (elem["price"] as int):
			return false
		var elem_id: String = elem["id"] as String
		if to_zone == "inventory":
			return _shop_target_ok(state["inventory"] as Array, to_slot, elem_id)
		if to_zone == "grid":
			return _shop_target_ok(state["battle_grid"] as Array, to_slot, elem_id)
		return true

	if from_zone == "inventory" and to_zone == "inventory":
		if from_slot == to_slot:
			return false
		var inv: Array = state["inventory"] as Array
		if from_slot < 0 or from_slot >= inv.size() or to_slot < 0 or to_slot >= inv.size():
			return false
		var from_item: Variant = inv[from_slot]
		var to_item: Variant = inv[to_slot]
		if from_item == null or to_item == null:
			return false
		var fa: Dictionary = from_item as Dictionary
		var ta: Dictionary = to_item as Dictionary
		if (fa["element_id"] as String) != (ta["element_id"] as String):
			return false
		return (fa["level"] as int) == (ta["level"] as int)

	if from_zone == "grid" and to_zone == "grid" and from_slot == to_slot:
		return false

	return true


# ── drag-drop intake seam (slots validate through here) ───────────────────────
# Slots put a drag payload — {"type": "inventory"|"grid"|"shop", "slot": int,
# "shop_slot": int (shop only)} — into _get_drag_data. These two functions are the
# single place that payload maps to a transfer loc and gets validated, so the slot
# scripts stop re-deriving the translation. The apply path is resolve_drop.

# Translates a drag payload into a transfer loc ({"zone", "slot"}). {} = unrecognised.
static func drag_to_loc(drag: Dictionary) -> Dictionary:
	match drag.get("type", "") as String:
		"shop":
			return {"zone": "shop", "slot": drag.get("shop_slot", -1) as int}
		"inventory", "grid":
			if not drag.has("slot"):
				return {}
			return {"zone": drag["type"] as String, "slot": drag["slot"] as int}
	return {}


# Whether a raw drag payload may drop onto to_loc. Wraps drag_to_loc + can_transfer.
static func can_drop(state: Dictionary, drag: Variant, to_loc: Dictionary) -> bool:
	if not drag is Dictionary:
		return false
	var from_loc: Dictionary = drag_to_loc(drag as Dictionary)
	if from_loc.is_empty():
		return false
	return can_transfer(state, from_loc, to_loc)


static func sell_item(state: Dictionary, slot_index: int) -> Dictionary:
	var inv: Array = state["inventory"]
	if slot_index < 0 or slot_index >= inv.size():
		return state
	var item: Variant = inv[slot_index]
	if item == null:
		return state
	var s: Dictionary = state.duplicate(true)
	var elem: Dictionary = item as Dictionary
	@warning_ignore("integer_division")
	var refund: int = (elem["price"] as int) / TuningData.SELL_REFUND_DIVISOR
	s["gold"] = (s["gold"] as int) + refund
	s["inventory"][slot_index] = null
	return s


static func sell_grid_item(state: Dictionary, grid_slot: int) -> Dictionary:
	var grid: Array = state["battle_grid"]
	if grid_slot < 0 or grid_slot >= grid.size():
		return state
	var item: Variant = grid[grid_slot]
	if item == null:
		return state
	var s: Dictionary = state.duplicate(true)
	var elem: Dictionary = item as Dictionary
	@warning_ignore("integer_division")
	var refund: int = (elem["price"] as int) / TuningData.SELL_REFUND_DIVISOR
	s["gold"] = (s["gold"] as int) + refund
	s["battle_grid"][grid_slot] = null
	return s


# Reroll cost escalates within a shop phase: base + REROLL_COST_STEP per paid reroll
# already done this phase. reroll_count resets each round (PhaseSystem.advance_round).
static func reroll_cost(state: Dictionary) -> int:
	return TuningData.REROLL_BASE_COST + (state.get("reroll_count", 0) as int) * TuningData.REROLL_COST_STEP


static func reroll_shop(state: Dictionary, is_free: bool = false) -> Dictionary:
	var cost: int = reroll_cost(state)
	if not is_free and (state["gold"] as int) < cost:
		return state
	var s: Dictionary = state.duplicate(true)
	if not is_free:
		s["gold"] = (s["gold"] as int) - cost
		s["reroll_count"] = (s.get("reroll_count", 0) as int) + 1

	var run_discoveries: Array = s["run_discoveries"] as Array
	var unlocked: Array[int] = unlocked_tiers(run_discoveries)
	var tier1_pool: Array[Dictionary] = eligible_for_tier(run_discoveries, 1)

	# Unlocked higher tiers, each filtered to the player's families.
	var higher_pool: Array[Dictionary] = []
	for tier: int in unlocked:
		if tier >= 2:
			higher_pool.append_array(eligible_for_tier(run_discoveries, tier))

	var slot_count: int = TuningData.SHOP_SLOT_COUNT
	# Every slot independently rolls T1 vs a higher (unlocked) tier
	# (SHOP_HIGHER_TIER_SLOT_PERCENT% chance of higher), so the mix varies round to
	# round. Before anything higher is unlocked, higher_pool is empty → all T1; T1
	# is common enough (~70% per slot) that the forge engine is never starved.
	var higher_count: int = 0
	if not higher_pool.is_empty():
		for _i: int in slot_count:
			if randi() % 100 < TuningData.SHOP_HIGHER_TIER_SLOT_PERCENT:
				higher_count += 1
	# Spread + dedupe within each tier, then shuffle so the higher-tier slots aren't
	# always positioned last. T1 backfills any shortfall in the higher pool.
	var picks: Array[Dictionary] = []
	picks.append_array(_pick_spread(higher_pool, higher_count))
	picks.append_array(_pick_spread(tier1_pool, slot_count - picks.size()))
	while picks.size() < slot_count and not tier1_pool.is_empty():
		picks.append(tier1_pool[randi() % tier1_pool.size()] as Dictionary)
	picks.shuffle()
	var slots: Array = CombatState.empty_slots(slot_count)
	for i: int in mini(picks.size(), slot_count):
		slots[i] = (picks[i] as Dictionary).duplicate()
	s["shop_items"] = slots
	return s


# Buys a shop element into one destination array (inventory or battle_grid), keyed
# by dest_key. An empty slot takes a fresh level-1 instance; a matching level-1 slot
# levels up to 2. One body for both destinations — the inventory/grid buy paths used
# to be copied verbatim and differed only by which array they wrote.
static func _buy_into(state: Dictionary, shop_slot: int, dest_key: String, dest_slot: int) -> Dictionary:
	var shop_items: Array = state["shop_items"]
	if shop_slot < 0 or shop_slot >= shop_items.size():
		return state
	var item: Variant = shop_items[shop_slot]
	if item == null:
		return state
	var elem_def: Dictionary = item as Dictionary
	var price: int = elem_def["price"] as int
	var gold: int = state["gold"] as int
	if gold < price:
		return state
	var dest: Array = state[dest_key]
	if dest_slot < 0 or dest_slot >= dest.size():
		return state
	var existing: Variant = dest[dest_slot]
	# An occupied slot only accepts the buy when it holds a matching level-1 piece
	# (the buy then levels it to 2); anything else rejects.
	if existing != null:
		var target: Dictionary = existing as Dictionary
		if (target.get("element_id", "") as String) != (elem_def["id"] as String):
			return state
		if (target["level"] as int) != 1:
			return state
	var s: Dictionary = state.duplicate(true)
	s["gold"] = gold - price
	s["shop_items"][shop_slot] = null
	if existing == null:
		var instance: Dictionary = elem_def.duplicate()
		instance["element_id"] = elem_def["id"] as String
		instance["level"] = 1
		s[dest_key][dest_slot] = instance
	else:
		var upgraded: Dictionary = (s[dest_key][dest_slot] as Dictionary).duplicate()
		upgraded["level"] = 2
		s[dest_key][dest_slot] = upgraded
	return s


static func _swap_arrays(state: Dictionary, from_key: String, from_slot: int, to_key: String, to_slot: int) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	var temp: Variant = s[from_key][from_slot]
	s[from_key][from_slot] = s[to_key][to_slot]
	s[to_key][to_slot] = temp
	return s


# A shop buy into `dest_slot` is allowed when the slot is empty/out-of-range, or holds
# a matching element still at level 1 (a buy-and-level-up). Shared by the inventory
# and grid shop branches of can_transfer.
static func _shop_target_ok(dest: Array, to_slot: int, elem_id: String) -> bool:
	if to_slot < 0 or to_slot >= dest.size():
		return true
	var existing: Variant = dest[to_slot]
	if existing == null:
		return true
	var target: Dictionary = existing as Dictionary
	if (target.get("element_id", "") as String) != elem_id:
		return false
	return (target["level"] as int) == 1


static func _first_empty_slot(arr: Array) -> int:
	for i: int in arr.size():
		if arr[i] == null:
			return i
	return -1
