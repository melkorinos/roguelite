# Symbol Index — Key Entry Points

Not loaded at session start. Reference when you need a function location without grepping.
Last updated: 2026-06-14

---

## BattleSystem (systems/BattleSystem.gd)
- `tick_battle(state, delta)` :34 — per-frame combat step (status tick → sides → reactives → periodics → drain commands)
- `simulate_battle(state)` :13 — pre-compute full fight result (used by balance harness)
- `summary_rows(state, side)` :303 — derived per-element Summary rows (fires/damage/DPS/effects)
- `compute_result(state)` :376 — raw classification primitive; canonical logic lives in PhaseSystem.resolve_round

## PhaseSystem (systems/PhaseSystem.gd)
- `begin_combat(state, opponent_grid, config)` :31 — shared reset→HP→seed→combat_start path
- `to_battle(state, opponent_snapshot)` :52 — round entry point; calls begin_combat with round-scaled HP + Ghost
- `resolve_round(state)` :81 — canonical win/loss/draw (opponent_hp ≤ 0 = win; mutual KO = draw = win)
- `advance_round(state)` :116 — +1 round, +gold, round_result augments

## ShopSystem (systems/ShopSystem.gd)
- `transfer(state, from_loc, to_loc)` :103 — all item moves: buy/sell/drag; loc = {zone, slot}
- `grant_to_inventory(s, instance)` :311 — place instance in first empty inv slot; returns bool (full = false)
- `can_drop(state, drag, to_loc)` :267 — drop validation before commit
- `reroll_shop(state, is_free)` :331 — reroll with cost deducted

## ForgeSystem (systems/ForgeSystem.gd)
- `attempt(state, op)` :28 — execute forge or merge op; triggers apply_grid_growth
- `result_element(state, op)` :105 — preview result instance (same interface as attempt output)
- `apply_grid_growth(state)` :53 — idempotent; appends slot, bumps battle_slot_count, records fired tiers

## AbilitySystem (systems/AbilitySystem.gd)
- `resolve_combat_start(state)` :440 — fire all combat_start abilities at t=0
- `resolve_reactive(state, events, rng)` :493 — process event list → reactive abilities
- `resolve_periodic(state, delta)` :458 — tick periodic abilities (lava/volcano/rainbow only)
- `apply_external_effects(state, effects, side)` :282 — Augment combat-scope atom injection seam
- `validate_atom(effect)` :134 — checks atom against ATOM_SCHEMAS; returns error strings

## StatusSystem (systems/StatusSystem.gd)
- `apply_effect(statuses, effect, potency, source_slot)` :147 — land a status; records by_source ledger
- `compute_incoming_damage(raw, attacker_statuses, defender_statuses)` :387 — mitigation + curse amplification
- `tick(statuses)` :243 — advance DOT/burn stacks one second; returns attribution dict
- `effective_cooldown_deciseconds(base, own_statuses)` :131 — haste/shock-adjusted cooldown

## AugmentSystem (systems/AugmentSystem.gd)
- `add_augment(state, augment)` :111 — append augment to state["augments"]; triggers materialize
- `materialize_run_state(state)` :126 — derive hp_bonus / reroll_discount cache from run_state atoms
- `apply_combat_start(state)` :177 — inject combat-scope augment atoms via apply_external_effects
- `shop_weights(state)` :156 — shop-gen scope: soft element bias within eligible pool

## EventSystem (systems/EventSystem.gd)
- `is_event_due(state)` :20 — round % EVENT_EVERY_N_ROUNDS == 0 and round ≥ 2 check
- `offer(state, rng)` :34 — build EVENT_OFFER_COUNT distinct reward choices (seeded, Replay-safe)
- `apply_reward(state, reward)` :71 — grant chosen reward (gold / grant_element / run_modifier augment)

## ElementData (data/ElementData.gd)
- `find(element_id)` :142 — O(1) lookup; returns SHARED dict — `.duplicate()` before mutating
- `instantiate(element_id, level)` :153 — build a live element instance; only valid way to create one
- `scaled_potency(tier, level)` :186 — tier × TIER_POTENCY_MULTIPLIER × level
- `effective_damage(item)` :206 — base × mult × level × tier-mult; pure-effect elements return 0

## RecipeData (data/RecipeData.gd)
- `find_result(id_a, id_b)` :299 — O(1) forge result lookup; "" = no recipe (steam+mud sentinel)
- `recipes_with(ingredient_id)` :308 — all recipes an element appears in as ingredient
- `recipes_for(result_id)` :316 — all recipes that produce a given element
- `describe_pair(pair)` :324 — resolve pair dict → both element defs (Shop/Tooltip/Compendium)

## AbilityData (data/AbilityData.gd)
- `get_ability(element_id)` :18 — ability dict for an element
- `trigger_label(ability)` :45 — single source for trigger display text (Battle Summary + Compendium)

## GameState / CombatState (data/)
- `GameState.create()` GameState.gd:4 — new run state dict (calls CombatState.reset internally)
- `CombatState.reset(state, player_count, opp_count)` CombatState.gd:69 — per-combat field init; sizes per-side arrays
- `CombatState.empty_stat_row()` CombatState.gd:40 — blank contribution row {direct, poison, burn, curse, heal, blocked}
