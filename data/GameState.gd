class_name GameState


static func create(seed_recipes: Array[String] = []) -> Dictionary:
	var state: Dictionary = {
		"phase": "shop",
		"round": 1,
		"player_hp": TuningData.BASE_PLAYER_HP,
		"opponent_hp": TuningData.INITIAL_OPPONENT_HP,
		"gold": TuningData.STARTING_GOLD,
		"inventory": CombatState.empty_slots(TuningData.INVENTORY_SIZE),
		"battle_grid": CombatState.empty_slots(TuningData.GRID_BASE_SLOTS),
		# Grid Growth (ADR 0014): the player's board size this run. Grows via
		# ForgeSystem.apply_grid_growth; persists across rounds, resets per run.
		# grid_growth_fired holds the GRID_GROWTH_TRIGGERS indices already awarded.
		"battle_slot_count": TuningData.GRID_BASE_SLOTS,
		"grid_growth_fired": [],
		"opponent_grid": CombatState.empty_slots(),
		"combat_rng_state": 0,
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
		"forge_slots": [null, null],
		"lives": TuningData.STARTING_LIFE,
		"wins": 0,
		"player_starting_hp": TuningData.BASE_PLAYER_HP,  # for the HP bar max; set per combat in to_battle
		# Persistent run modifiers (materialized cache, ADR 0016): the run_state-scope
		# output of the player's Augments, recomputed by AugmentSystem.materialize_run_state
		# whenever the augments list changes. The hot readers (_scaled_player_hp, reroll_cost)
		# read these fields directly instead of walking the augment list every round.
		# bonus HP (flat) added on top of the round-scaled base; bonus HP (percent) scales it.
		"hp_bonus": 0,
		"hp_bonus_percent": 0,
		# Augments (ADR 0016): the durable per-run list of acquired effect sources — a
		# Keystone (Starting Pick), an Event Reward, or a (future) Trinket. Each carries
		# scope-tagged effect atoms applied at their own sites. Survives Shop re-entry,
		# resets per run. AugmentSystem owns the vocabulary + the four scope apply fns.
		"augments": [],
		"opponent_starting_hp": 0,
		"opponent_snapshot": {},
	}
	# CombatState.reset owns the per-combat shape — every per-slot array (timers,
	# frozen-seconds, ability timers), the status pools, battle_stats, and the
	# event/command queues — so create() doesn't re-hand-roll those literals.
	# Single source of truth for the combat fields; sized to the base board.
	return CombatState.reset(state, TuningData.GRID_BASE_SLOTS)
