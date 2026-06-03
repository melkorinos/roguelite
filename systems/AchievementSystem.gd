class_name AchievementSystem

const ACH_FIRST_WIN   := "ACH_FIRST_WIN"
const ACH_FIRST_FORGE := "ACH_FIRST_FORGE"
const ACH_CLUTCH      := "ACH_CLUTCH"
const ACH_SURVIVOR    := "ACH_SURVIVOR"
const ACH_DAMAGE_20K  := "ACH_DAMAGE_20K"


# Pure entry point — takes a profile snapshot, returns {profile, unlocked}.
# No I/O; callers (Battle.gd, Shop.gd) own the PlayerProfile read/write/save.
static func check(state: Dictionary, profile: Dictionary, event: String) -> Dictionary:
	var updated: Dictionary = evaluate(state, profile, event)
	var prev_achs: Array = profile.get("achievements_unlocked", []) as Array
	var new_achs: Array = updated.get("achievements_unlocked", []) as Array
	var unlocked: Array[String] = []
	for ach: Variant in new_achs:
		if not ach in prev_achs:
			unlocked.append(ach as String)
	return {"profile": updated, "unlocked": unlocked}


# Pure function — takes a profile dict, returns an updated profile dict. No I/O.
static func evaluate(state: Dictionary, profile: Dictionary, event: String) -> Dictionary:
	var p: Dictionary = profile.duplicate(true)

	_merge_recipes(state, p)

	if event == "round_win" or event == "round_loss":
		var dmg: int = _sum_player_damage(state)
		p["total_damage_dealt"] = (p.get("total_damage_dealt", 0) as int) + dmg

	var achs: Array = p.get("achievements_unlocked", []) as Array

	if event == "round_win":
		if not ACH_FIRST_WIN in achs:
			achs.append(ACH_FIRST_WIN)
		if (state.get("player_hp", 30) as int) <= 5 and not ACH_CLUTCH in achs:
			achs.append(ACH_CLUTCH)

	if event == "forge_discovered":
		if not ACH_FIRST_FORGE in achs:
			achs.append(ACH_FIRST_FORGE)

	if event == "match_eliminated":
		if (state.get("wins", 0) as int) >= 3 and not ACH_SURVIVOR in achs:
			achs.append(ACH_SURVIVOR)

	var total: int = p.get("total_damage_dealt", 0) as int
	if total >= 20000 and not ACH_DAMAGE_20K in achs:
		achs.append(ACH_DAMAGE_20K)

	p["achievements_unlocked"] = achs
	return p


static func _merge_recipes(state: Dictionary, p: Dictionary) -> void:
	var state_recipes: Array = state.get("discovered_recipes", []) as Array
	var prof_recipes: Array = p.get("discovered_recipes", []) as Array
	for r: Variant in state_recipes:
		if not r in prof_recipes:
			prof_recipes.append(r)
	p["discovered_recipes"] = prof_recipes


static func _sum_player_damage(state: Dictionary) -> int:
	var bstats: Variant = state.get("battle_stats", null)
	if bstats == null:
		return 0
	var pstats: Array = (bstats as Dictionary).get("player", []) as Array
	var total: int = 0
	for slot: Variant in pstats:
		if slot != null:
			total += (slot as Dictionary).get("damage", 0) as int
	return total
