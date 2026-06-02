class_name ForgeSystem


# Merge two slots of the same element at the same level → level + 1.
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


# Combine two different elements via a recipe. Reveals the recipe if previously unknown.
static func forge(state: Dictionary, slot_a: int, slot_b: int) -> Dictionary:
	var inv: Array = state["inventory"]
	var ea: Variant = inv[slot_a]
	var eb: Variant = inv[slot_b]
	if ea == null or eb == null:
		return state
	var da: Dictionary = ea as Dictionary
	var db: Dictionary = eb as Dictionary
	if da["element_id"] == db["element_id"]:
		return state
	var result_id: String = RecipeData.find_result(da["element_id"], db["element_id"])
	if result_id.is_empty():
		return state
	var result_def: Dictionary = ElementData.find(result_id)
	if result_def.is_empty():
		return state
	var s: Dictionary = state.duplicate(true)
	var instance: Dictionary = result_def.duplicate()
	instance["element_id"] = result_id
	instance["level"] = 1
	s["inventory"][slot_a] = instance
	s["inventory"][slot_b] = null
	var discovered: Array = s["discovered_recipes"]
	if not discovered.has(result_id):
		discovered.append(result_id)
	var result_tier: int = result_def["tier"] as int
	if result_tier > (s["shop_tier"] as int):
		s["shop_tier"] = result_tier
	return s


# Returns a preview string for what a forge/level-up would produce, without mutating state.
static func preview(state: Dictionary, slot_a: int, slot_b: int) -> String:
	var inv: Array = state["inventory"]
	var ea: Variant = inv[slot_a]
	var eb: Variant = inv[slot_b]
	if ea == null or eb == null:
		return ""
	var da: Dictionary = ea as Dictionary
	var db: Dictionary = eb as Dictionary
	if da["element_id"] == db["element_id"]:
		if (da["level"] as int) != (db["level"] as int):
			return "Levels must match"
		return "→ %s %s Lv%d" % [da["emoji"], da["name"], (da["level"] as int) + 1]
	var result_id: String = RecipeData.find_result(da["element_id"], db["element_id"])
	if result_id.is_empty():
		return "No recipe"
	var discovered: Array = state["discovered_recipes"]
	if discovered.has(result_id):
		var r: Dictionary = ElementData.find(result_id)
		return "→ %s %s" % [r["emoji"], r["name"]]
	return "→ ???"
