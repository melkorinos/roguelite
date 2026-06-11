class_name GameState


static func create(seed_recipes: Array[String] = []) -> Dictionary:
	return {
		"phase": "shop",
		"round": 1,
		"player_hp": TuningData.BASE_PLAYER_HP,
		"opponent_hp": TuningData.INITIAL_OPPONENT_HP,
		"gold": TuningData.STARTING_GOLD,
		"inventory": CombatState.empty_slots(TuningData.INVENTORY_SIZE),
		"battle_grid": CombatState.empty_slots(TuningData.GRID_BASE_SLOTS),
		# Grid Growth (ADR 0014): the player's board size this run. Grows via
		# ShopSystem.apply_grid_growth; persists across rounds, resets per run.
		# grid_growth_fired holds the GRID_GROWTH_TRIGGERS indices already awarded.
		"battle_slot_count": TuningData.GRID_BASE_SLOTS,
		"grid_growth_fired": [],
		"element_timers": CombatState.zero_floats(),
		"opponent_grid": CombatState.empty_slots(),
		"opponent_timers": CombatState.zero_floats(),
		"player_frozen_seconds": CombatState.zero_floats(),
		"opponent_frozen_seconds": CombatState.zero_floats(),
		"player_last_frozen_slot": -1,
		"opponent_last_frozen_slot": -1,
		"player_ability_timers": CombatState.zero_floats(),
		"opponent_ability_timers": CombatState.zero_floats(),
		"combat_rng_state": 0,
		"pending_commands": [],
		"battle_events": [],
		"shop_items": CombatState.empty_slots(TuningData.SHOP_SLOT_COUNT),
		"reroll_count": 0,
		# Persistent Run Modifier (ADR 0011): subtracted from the reroll cost, floored at
		# 0. Granted by Events; accumulates across the run (NOT reset per round).
		"reroll_discount": 0,
		# The round whose Event has been consumed (ADR 0011) — guards re-showing the
		# Event overlay when the Shop is re-entered. -1 = none taken yet.
		"last_event_round": -1,
		"starting_pick_done": false,
		# Per-run record of element ids the player has FORGED this run. Drives the
		# discovery-gated shop pool (ShopSystem). Distinct from discovered_recipes,
		# which is the persistent cross-run record (Compendium / achievements).
		"run_discoveries": [],
		"discovered_recipes": seed_recipes.duplicate(),
		"battle_timer": 0.0,
		# Sandstorm storm-seconds already applied this combat (ADR 0012). Reset per combat.
		"sandstorm_ticks": 0,
		"forge_slots": [null, null],
		"battle_stats": CombatState.empty_battle_stats(),
		"lives": TuningData.STARTING_LIFE,
		"wins": 0,
		"player_starting_hp": TuningData.BASE_PLAYER_HP,  # for the HP bar max; set per combat in to_battle
		# Persistent run modifier: bonus HP granted by rewards (e.g. the every-3 event),
		# added on top of the round-scaled base in PhaseSystem.to_battle.
		"hp_bonus": 0,
		"opponent_starting_hp": 0,
		"opponent_snapshot": {},
		"player_statuses": StatusSystem.empty_statuses(),
		"opponent_statuses": StatusSystem.empty_statuses(),
		"status_tick_timer": 0.0,
	}
