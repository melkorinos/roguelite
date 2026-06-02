class_name BattleSystem

const OPPONENT_ATTACK: int = 2
const OPPONENT_DEFENCE: int = 1
const OPPONENT_HP: int = 20


static func get_player_stats(inventory: Array) -> Dictionary:
	var dmg: int = 0
	for item: Variant in inventory:
		if item != null:
			dmg += (item as Dictionary).get("damage", 0)
	return { "damage": dmg }


static func tick_battle(state: Dictionary, delta: float) -> Dictionary:
	if state["phase"] == "result":
		return state
	var s: Dictionary = state.duplicate(true)
	var timer: float = (s["battle_timer"] as float) + delta
	s["battle_timer"] = timer
	var sandstorm: bool = s["sandstorm_fired"]

	if timer >= 10.0 and not sandstorm:
		s["sandstorm_fired"] = true
		s["player_hp"] = max(0, (s["player_hp"] as int) - 10)
		s["opponent_hp"] = max(0, (s["opponent_hp"] as int) - 10)

	if timer >= 11.0 and (s["sandstorm_fired"] as bool):
		s["phase"] = "result"

	return s


static func compute_result(state: Dictionary) -> String:
	var player_hp: int = state["player_hp"]
	var opp_hp: int = state["opponent_hp"]
	if player_hp > opp_hp:
		return "player_wins"
	elif opp_hp > player_hp:
		return "opponent_wins"
	return "draw"
