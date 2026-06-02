class_name ForgeSystem


# Same element × same level → level + 1. Element identity unchanged.
static func level_up(state: Dictionary, slot_a: int, slot_b: int) -> Dictionary:
	var inv: Array = state["inventory"]
	var ea: Variant = inv[slot_a]
	var eb: Variant = inv[slot_b]
	if ea == null or eb == null:
		return state
	var da: Dictionary = ea as Dictionary
	var db: Dictionary = eb as Dictionary
	if da["element_id"] != db["element_id"]:
		return state
	if (da["level"] as int) != (db["level"] as int):
		return state
	var s: Dictionary = state.duplicate(true)
	var upgraded: Dictionary = (s["inventory"][slot_a] as Dictionary).duplicate()
	upgraded["level"] = (da["level"] as int) + 1
	s["inventory"][slot_a] = upgraded
	s["inventory"][slot_b] = null
	return s


# Combine two inventory slots via a recipe. Result level = min(level_a, level_b).
static func forge(state: Dictionary, slot_a: int, slot_b: int) -> Dictionary:
	var inv: Array = state["inventory"]
	var ea: Variant = inv[slot_a]
	var eb: Variant = inv[slot_b]
	if ea == null or eb == null:
		return state
	var da: Dictionary = ea as Dictionary
	var db: Dictionary = eb as Dictionary
	var result_id: String = RecipeData.find_result(da["element_id"], db["element_id"])
	if result_id.is_empty():
		return state
	var result_def: Dictionary = ElementData.find(result_id)
	if result_def.is_empty():
		return state
	var result_level: int = mini(da["level"] as int, db["level"] as int)
	var s: Dictionary = state.duplicate(true)
	var instance: Dictionary = result_def.duplicate()
	instance["element_id"] = result_id
	instance["level"] = result_level
	s["inventory"][slot_a] = instance
	s["inventory"][slot_b] = null
	var discovered: Array = s["discovered_recipes"]
	if not discovered.has(result_id):
		discovered.append(result_id)
	var result_tier: int = result_def["tier"] as int
	if result_tier > (s["shop_tier"] as int):
		s["shop_tier"] = result_tier
	return s


# Forge using items in forge_slots. Result lands in first free inventory slot.
# Returns a Dictionary with keys "state" (new GameState) and "outcome" (String: "ok"|"no_recipe"|"inv_full").
# Also sets "level_mismatch" bool key when inputs had different levels.
static func forge_from_bench(state: Dictionary) -> Dictionary:
	var slots: Array = state["forge_slots"]
	var ea: Variant = slots[0]
	var eb: Variant = slots[1]
	if ea == null or eb == null:
		return {"state": state, "outcome": "incomplete", "level_mismatch": false}
	var da: Dictionary = ea as Dictionary
	var db: Dictionary = eb as Dictionary
	var result_id: String = RecipeData.find_result(da["element_id"], db["element_id"])
	if result_id.is_empty():
		var s_no: Dictionary = state.duplicate(true)
		s_no["forge_slots"] = [null, null]
		var inv_no: Array = s_no["inventory"]
		for item: Variant in [ea, eb]:
			var empty: int = _first_empty_inv_slot(inv_no)
			if empty >= 0:
				inv_no[empty] = (item as Dictionary).duplicate()
		return {"state": s_no, "outcome": "no_recipe", "level_mismatch": false}
	var result_def: Dictionary = ElementData.find(result_id)
	if result_def.is_empty():
		return {"state": state, "outcome": "no_recipe", "level_mismatch": false}
	var s: Dictionary = state.duplicate(true)
	var free_slot: int = _first_empty_inv_slot(s["inventory"])
	if free_slot < 0:
		return {"state": state, "outcome": "inv_full", "level_mismatch": false}
	var level_a: int = da["level"] as int
	var level_b: int = db["level"] as int
	var result_level: int = mini(level_a, level_b)
	var level_mismatch: bool = level_a != level_b
	var instance: Dictionary = result_def.duplicate()
	instance["element_id"] = result_id
	instance["level"] = result_level
	s["inventory"][free_slot] = instance
	s["forge_slots"] = [null, null]
	var discovered: Array = s["discovered_recipes"]
	if not discovered.has(result_id):
		discovered.append(result_id)
	var result_tier: int = result_def["tier"] as int
	if result_tier > (s["shop_tier"] as int):
		s["shop_tier"] = result_tier
	return {"state": s, "outcome": "ok", "level_mismatch": level_mismatch}


# Preview string for a potential forge or level-up between two inventory slots.
static func preview(state: Dictionary, slot_a: int, slot_b: int) -> String:
	var inv: Array = state["inventory"]
	var ea: Variant = inv[slot_a]
	var eb: Variant = inv[slot_b]
	if ea == null or eb == null:
		return ""
	var da: Dictionary = ea as Dictionary
	var db: Dictionary = eb as Dictionary
	var result_id: String = RecipeData.find_result(da["element_id"], db["element_id"])
	if not result_id.is_empty():
		var r: Dictionary = ElementData.find(result_id)
		return "→ %s %s" % [r["emoji"], r["name"]]
	if da["element_id"] == db["element_id"]:
		if (da["level"] as int) != (db["level"] as int):
			return "Levels must match"
		return "→ %s %s Lv%d" % [da["emoji"], da["name"], (da["level"] as int) + 1]
	return "No recipe"


# Preview string for the two items currently sitting in the forge bench.
static func preview_bench(state: Dictionary) -> String:
	var slots: Array = state["forge_slots"]
	var ea: Variant = slots[0]
	var eb: Variant = slots[1]
	if ea == null or eb == null:
		return ""
	var da: Dictionary = ea as Dictionary
	var db: Dictionary = eb as Dictionary
	var result_id: String = RecipeData.find_result(da["element_id"], db["element_id"])
	if not result_id.is_empty():
		var r: Dictionary = ElementData.find(result_id)
		var level_a: int = da["level"] as int
		var level_b: int = db["level"] as int
		var result_level: int = mini(level_a, level_b)
		var warn: String = "  ⚠ level mismatch" if level_a != level_b else ""
		return "→ %s %s Lv%d%s" % [r["emoji"], r["name"], result_level, warn]
	return "✗ No recipe"


static func _first_empty_inv_slot(inventory: Array) -> int:
	for i: int in inventory.size():
		if inventory[i] == null:
			return i
	return -1
