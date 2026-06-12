class_name CombatSide

# The single source of truth for how a combat side ("player" / "opponent") maps to
# its GameState keys. BattleSystem and AbilitySystem both read side state through
# here instead of hand-rolling their own key maps, so growing the grid or adding a
# new per-slot array is a one-place change.


static func opponent_of(side: String) -> String:
	return "opponent" if side == "player" else "player"


# Canonical key map for a side. Every per-side / per-slot GameState field lives here.
static func keys(side: String) -> Dictionary:
	if side == "player":
		return {
			"grid": "battle_grid",
			"timers": "element_timers",
			"statuses": "player_statuses",
			"hp": "player_hp",
			"starting_hp": "player_starting_hp",
			"frozen": "player_frozen_seconds",
			"last_frozen": "player_last_frozen_slot",
			"ability_timers": "player_ability_timers",
			"stats": "player",
		}
	return {
		"grid": "opponent_grid",
		"timers": "opponent_timers",
		"statuses": "opponent_statuses",
		"hp": "opponent_hp",
		"starting_hp": "opponent_starting_hp",
		"frozen": "opponent_frozen_seconds",
		"last_frozen": "opponent_last_frozen_slot",
		"ability_timers": "opponent_ability_timers",
		"stats": "opponent",
	}


# ── convenience read accessors ────────────────────────────────────────────────

static func grid(state: Dictionary, side: String) -> Array:
	return state[keys(side)["grid"]] as Array


static func statuses(state: Dictionary, side: String) -> Dictionary:
	return state[keys(side)["statuses"]] as Dictionary


static func timers(state: Dictionary, side: String) -> Array:
	return state[keys(side)["timers"]] as Array


static func frozen(state: Dictionary, side: String) -> Array:
	return state[keys(side)["frozen"]] as Array
