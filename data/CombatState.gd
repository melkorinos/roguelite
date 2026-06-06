class_name CombatState

# Single source of truth for the *shape* of combat-phase GameState: the per-slot
# arrays (timers, frozen-seconds, ability-timers) and the per-element Battle
# Summary stat rows. Both GameState.create() and PhaseSystem.to_battle()
# previously hand-rolled these — including the {"fires":0,...} stat row literal
# copied 16 times and 4-slot array literals scattered across the codebase.
#
# Everything is sized from SLOT_COUNT, so growing the Battlegrid is a one-place
# change. Pure data factory — never touches the SceneTree.


# Board slot count. The combat backend is grid-agnostic (it derives the grid
# shape from the slot array via GridSystem), so this is the single place the
# live board size is declared.
const SLOT_COUNT: int = 4


# A fresh array of `count` zero floats — for timers and frozen-seconds.
static func zero_floats(count: int = SLOT_COUNT) -> Array:
	var result: Array = []
	for _i: int in count:
		result.append(0.0)
	return result


# A fresh array of `count` empty (null) board slots.
static func empty_slots(count: int = SLOT_COUNT) -> Array:
	var result: Array = []
	for _i: int in count:
		result.append(null)
	return result


# One per-element Battle Summary stat row.
static func empty_stat_row() -> Dictionary:
	return { "fires": 0, "damage": 0, "effects": 0, "effects_by_status": {} }


# `count` fresh stat rows for one side.
static func empty_stat_rows(count: int = SLOT_COUNT) -> Array:
	var rows: Array = []
	for _i: int in count:
		rows.append(empty_stat_row())
	return rows


# The two-sided battle_stats block.
static func empty_battle_stats(count: int = SLOT_COUNT) -> Dictionary:
	return { "player": empty_stat_rows(count), "opponent": empty_stat_rows(count) }


# Resets every per-combat field on `state` to its fresh combat-start value, sized
# to the board. Owns exactly the fields to_battle()/create() used to hand-roll.
# Mutates and returns `state` (callers pass a duplicate). Does NOT set phase, hp,
# the RNG seed, the opponent grid/hp, or run combat-start abilities — those stay
# with PhaseSystem.to_battle().
static func reset(state: Dictionary, slot_count: int = SLOT_COUNT) -> Dictionary:
	state["battle_timer"] = 0.0
	state["element_timers"] = zero_floats(slot_count)
	state["opponent_timers"] = zero_floats(slot_count)
	state["player_frozen_seconds"] = zero_floats(slot_count)
	state["opponent_frozen_seconds"] = zero_floats(slot_count)
	state["player_last_frozen_slot"] = -1
	state["opponent_last_frozen_slot"] = -1
	state["player_ability_timers"] = zero_floats(slot_count)
	state["opponent_ability_timers"] = zero_floats(slot_count)
	state["pending_commands"] = []
	state["battle_events"] = []
	state["battle_stats"] = empty_battle_stats(slot_count)
	state["player_statuses"] = StatusSystem.empty_statuses()
	state["opponent_statuses"] = StatusSystem.empty_statuses()
	state["status_tick_timer"] = 0.0
	return state
