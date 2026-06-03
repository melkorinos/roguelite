extends Node

const CONFIG_PATH := "user://profile.cfg"

var _config := ConfigFile.new()


func _ready() -> void:
	_config.load(CONFIG_PATH)


# ── stats ─────────────────────────────────────────────────────────────────────

func get_total_damage_dealt() -> int:
	return _config.get_value("stats", "total_damage_dealt", 0)


func get_matches_played() -> int:
	return _config.get_value("stats", "matches_played", 0)


func get_matches_won() -> int:
	return _config.get_value("stats", "matches_won", 0)


# ── progress ──────────────────────────────────────────────────────────────────

func get_achievements_unlocked() -> Array[String]:
	var raw: String = _config.get_value("progress", "achievements_unlocked", "")
	return _split_csv(raw)


func unlock_achievement(ach_id: String) -> void:
	var current := get_achievements_unlocked()
	if ach_id in current:
		return
	current.append(ach_id)
	_config.set_value("progress", "achievements_unlocked", ",".join(current))
	_config.save(CONFIG_PATH)


# ── discovery ─────────────────────────────────────────────────────────────────

func get_discovered_recipes() -> Array[String]:
	var raw: String = _config.get_value("discovery", "discovered_recipes", "")
	return _split_csv(raw)


func merge_discovered_recipes(ids: Array[String]) -> void:
	var current := get_discovered_recipes()
	var changed := false
	for id: String in ids:
		if not id in current:
			current.append(id)
			changed = true
	if changed:
		_config.set_value("discovery", "discovered_recipes", ",".join(current))


# ── snapshot for AchievementSystem ───────────────────────────────────────────

func to_dict() -> Dictionary:
	return {
		"total_damage_dealt": get_total_damage_dealt(),
		"matches_played": get_matches_played(),
		"matches_won": get_matches_won(),
		"achievements_unlocked": get_achievements_unlocked(),
		"discovered_recipes": get_discovered_recipes(),
	}


func from_dict(d: Dictionary) -> void:
	_config.set_value("stats", "total_damage_dealt", d.get("total_damage_dealt", 0))
	_config.set_value("stats", "matches_played", d.get("matches_played", 0))
	_config.set_value("stats", "matches_won", d.get("matches_won", 0))
	var achs: Array = d.get("achievements_unlocked", [])
	_config.set_value("progress", "achievements_unlocked", ",".join(achs))
	var recipes: Array = d.get("discovered_recipes", [])
	_config.set_value("discovery", "discovered_recipes", ",".join(recipes))


# ── batch save (call at match end) ────────────────────────────────────────────

func save_profile() -> void:
	_config.save(CONFIG_PATH)


# ── helpers ───────────────────────────────────────────────────────────────────

func _split_csv(raw: String) -> Array[String]:
	if raw.is_empty():
		return []
	var result: Array[String] = []
	for part: String in raw.split(","):
		var trimmed := part.strip_edges()
		if not trimmed.is_empty():
			result.append(trimmed)
	return result
