# Memory — Settled Design Decisions

## Core identity
Auto-battler. Build synergies, break the system, lose to your exact counter, master meta over dozens of sessions. Insps: Super Auto Pets, HBG, The Bazaar, Dota Auto Chess. Steam desktop, async PvP, 20–30 min sessions. Visual: clean, minimal, weird, surreal.

## Entity + state model
Plain data dicts + standalone static fns. No inheritance. Systems take `GameState` dict, return new dict — no in-place mutation. `GameManager.state` global; `GameState.create()` in `data/GameState.gd`.

## Feature flags (`data/FeatureFlags.gd`)
Static class, `static var` (flip at runtime). **All default true since 2026-06-04** (early policy: ship on; flags are kill-switches). Only `status_effects` (Status pipeline) + `combat_adjacency` (adjacency_upgrade reactives) are code-read. `hidden_recipes`/`efficiency_scoring`/`ability_chain`/`innate_ability` are inert placeholders.

## Match structure
8 players, last standing. Each round: Shop → combat. Mixed PvP + PvE (fixed schedule).
- **Player HP**: in-battle only; `to_battle()` = `BASE_PLAYER_HP + (round-1)*HP_PER_ROUND + hp_bonus`. Not a match resource.
- **Life**: starts 100; loss = `round(clamp(opp_hp_ratio,0,1) * MAX_LIFE_LOSS)` — proportional, no buckets/floor. 0 = eliminated.
- **Win**: `WIN_THRESHOLD`(10) wins = victory. Draw = player win (opponent async). Both end → MainMenu.
- **Round win rule (canonical, 2026-06-07)**: won iff **opponent eliminated** (`opponent_hp ≤ 0`), NOT HP-compare. Mutual KO = draw = win. Single resolver `PhaseSystem.resolve_round(state)`; `describe_result`/`advance_round`/Battle.gd all read it. `BattleSystem.compute_result` = classification primitive. Flat 30s timeout removed (ADR 0012).
- **Sandstorm (ADR 0012)**: `BATTLE_TIME_LIMIT`(30) = storm **start**. `BattleSystem._tick_sandstorm` deals escalating **true** damage to **both** sides each storm-second until KO. Bypasses ALL mitigation by design (impartial; may route through defenses later, knob-flagged). Symmetric, inert, deterministic (Replay-safe). Ends on elimination OR `SANDSTORM_HARD_CAP_SECONDS`(60). Per-combat `sandstorm_ticks`. No visuals yet.
- **Balance knobs** all in `data/TuningData.gd` (incl. ×1 status-magnitude placeholders). Engine/safety/UI consts stay local; config-constants file planned.
- **Gold**: +5g/round via `advance_round()`. No streak/interest. Rounds unbounded (end at 10 wins OR 0 Life).

## Events (ADR 0011)
Non-combat choice node every `EVENT_EVERY_N_ROUNDS`(3), before shop (≠ future PvE Round). Pure `systems/EventSystem.gd`: `is_event_due` (`round%N==0`, `≥2`, guarded by `last_event_round`), `offer(state,rng)` → `EVENT_OFFER_COUNT`(3) distinct kinds seeded `hash("event:%d"%round)` (Replay-safe), `apply_reward`. Reward = tagged dict. **One-shot**: `gold`; `grant_element` (→ first empty inv; capped `max(ShopSystem.unlocked_tiers)`, family-filtered; full→gold; **never** writes `run_discoveries`). **Persistent Run Modifier** (discrete field, not generic list): `bonus_hp`→`hp_bonus`, `reroll_discount`→subtracted in `reroll_cost` (floor 0). UI `EventOverlay` (scenes/shared) blocking in `Shop._ready`; starting-pick (round 1) priority. Deferred: `trinket`, board-wide `damage_bonus` (no seam).

## Combat model
Real-time deterministic. Elements fire on individual cooldown timers. Discrete ticks; result pre-computed, played back. Ties: top-left first. RNG seeded at combat start → reproducible. Status applied on fire via `_apply_element_effect()`; 1s `status_tick_timer`.

## Innate + Replay
Fire one Innate Ability once/combat at chosen moment. After loss: spend Replay token, retrigger Innate at different moment. Tokens finite per-match. Economy TBD. Seam done (`pending_commands` + `queue_command`/`_drain_commands`/`resolve_command`, seeded `combat_rng_state`); UI pending.

## Element system (132 elements, 191 recipes, 4 tiers)
- **Data indexed (arch #3, 2026-06-09):** `ElementData`/`RecipeData` = `const ELEMENTS`/`const RECIPES` + lazy static indices, O(1). `find()`/`recipes_*` return **SHARED zero-copy** dicts — **`.duplicate()` before mutating** (all callers do). Mirrors `AbilityData.ABILITIES`.
- **Instance factory (arch #4):** build a live instance ONLY via `ElementData.instantiate(id, level)`. Place via `ShopSystem.grant_to_inventory(s, instance)→bool` (first-empty; caller owns on-full policy). Drop validation: `ShopSystem.can_drop`/`drag_to_loc`. Candidate B (route `compute_opponent_hp` through `effective_damage`) deferred to balance; D (Run Modifier registry) parked (contradicts ADR 0011).
- **No forward dead-ends (ADR 0010):** every element <T4 is an ingredient in ≥1 higher recipe (T4 apex exempt). 22 recipes added, cluster-routed; locked by `test_no_non_apex_forward_dead_ends`.
- **T1 (12, 5g):** Water💧Cleanse, Fire🔥Burn, Air🌬️Haste, Earth🌍Armor, Lightning⚡Shock, Nature🌿Heal, Light☀️Blind, Dark🌑Curse, Metal⚙️Plating, Fungus🍄Poison, Blood🩸Leech, Frost🌨️Weaken. *(Sound retired → Fungus)*
- **T2 (78, 8g):** self-combos/originals/extended/Blood/Frost crosses; 15 Group-G placeholder names pending. **T3 (32, 12g):** T2+T2 only, 2–3 convergence. **T4 (10, 16g):** T3+T3 only, "Phenomena"; stubbed abilities.
- **Damage archetypes (ADR 0013):** **pure-effect** (no direct hit — status IS damage; all T1 + most T2+) vs **damage-dealer** (whitelist `ElementData.DAMAGE_DEALERS`, ~20% of T2+, T4-skewed). `effective_damage = base × multiplier × level` (no +tier; multiplier vestigial; pure-effect → 0); `_fire_element_once` skips damage block when raw=0. **Level scales effect quantity** (`apply_effect(…, potency)` = source level → N stacks/points). Starting Pick → +1 level (×damage buff dead). Opponent HP round-scaled `100×(1+15%·(round-1))`, board-independent (placeholder).
- **Forge gating (ADR 0008):** both inputs Level ≥ `FORGE_MIN_INPUT_LEVEL`(2); result level = `max(1, min(inputs) − FORGE_RESULT_LEVEL_PENALTY(1))`. Merge ungated, before Forge. Under-level → `level_too_low` (items stay staged). `FORGE_GOLD_COST=0` reserved.
- **Forge discoverability (ADR 0009):** all recipes revealed (`hidden_recipes` inert). Bench hint (`Shop._update_forge_partner_hint`): **Made from** (`recipes_for(id)`) + **Forges with** (`recipes_with(id)`, owned-first), hoverable chips → shared `TooltipCard.show_for`. Item Tooltip MADE FROM line (id-guarded). "📖 Compendium" button via `GameManager.compendium_return_scene`.
- **Merge:** same element ×2 same level → level+1, drag-drop, no recipe. `discovered_recipes[]` in GameState (all visible; shadow TBD).

## Forge code (post 2026-06-11 arch review)
- `ForgeSystem.result_element(state, op)` = the result instance behind same interface as `preview` (Shop reads it for hover card — no dup level math).
- `AbilityData.trigger_label(ability)` = single source for trigger labels (Battle Summary + Compendium). `RecipeData.describe_pair(pair)` resolves a recipe pair → element defs (Shop/TooltipCard/Compendium).
- `scenes/screens/ForgePanel.gd` = script on RightPanel; owns bench UI + ops + ADR-0009 hint. Shop orchestrates via `state_changed`/`forge_succeeded`/`tooltip_*` signals. (Was arch candidate #3 — now landed.) F5 eyeball pending.

## Shop UX (all item moves via `ShopSystem.transfer`)
- `transfer(state, from_loc, to_loc)` — loc `{"zone":"shop"|"inventory"|"grid","slot":int}`; slot=-1 = first empty.
- Buy (click)→first empty inv. Drag to matching Lv1→ConfirmDialog level-up. Sell→SellZone→half refund. Bench: 2 ForgeSlots, auto-forge on 2nd drop, F quick-forge. Undo 1-action (Ctrl+Z). 5 rotating shop slots, reroll 2g.
- **Forge-gated pool (ADR 0007):** `shop_tier` retired. Tier appears after forging N distinct (`TIER_UNLOCK_THRESHOLDS` 3/2/1 for T2/T3/T4); then only that tier's elements from forged **families** (`eligible_for_tier`/`_families_for_tier`). T1 = full pool always + guaranteed ≥1 slot; higher slots spread (`_pick_spread`). `run_discoveries` (per-run, forge-written). Opponent power round-derived (`OpponentProvider._max_tier_for_round`).

## Level 2 Reward (settled, not built)
Merge to Lv2: flat gold + choice (+1 base dmg OR −0.5s cooldown).

## UI / pause / lifecycle
- **Item Tooltip**: TooltipCard (CanvasLayer 100), 0.3s hover, cursor-follow + edge-flip. `show_for_battle` live-updates eff. cooldown + weaken-adj damage each frame; `StatusGlossary.gd` + RichText `[url]` keywords; Shift pins card.
- **Battle speed/pause**: `_speed_mult` (1/1.5/2×) + `_paused`. **Battle Summary**: fires+dmg+DPS per element. **Status Tray (2026-06-09):** per-side emoji Status Chips (buff/debuff-tinted, stack badge) between label+grid; hover → live readout via pure `StatusSystem.describe(name,statuses)`; `EffectRegistry` carries `emoji`+`valence`. `scenes/shared/StatusChip.gd`.
- **Pause**: ESC in Shop/Battle → PauseOverlay (CanvasLayer 110): Resume/Settings/Forfeit/Quit-menu/Quit-desktop. Sim pauses.
- **Godot lifecycle**: `_ready()` fires on `add_child()`, not `.new()`. Set plain props before add_child; call child methods after.

## Board + Grid Growth (ADR 0014, IMPLEMENTED 2026-06-11)
Battlegrid starts 2×2 (4 slots); **Grid Growth** = +1 slot/run when first owning a tier-T element at level≥L (table `TuningData.GRID_GROWTH_TRIGGERS` = **T2→Lv2 (5th slot), T3→Lv2 (6th slot)**; T1→Lv2 dropped as too cheap; path-agnostic merge/forge; permanent for run; per-run reset). Reachable 6, hard cap **8** (no 9). Shapes 2-rows-tall (5/6→3×2, 7/8→4×2 in `GridSystem.dimensions`). State `battle_slot_count`/`grid_growth_fired`; `battle_grid` grows. **Per-side combat sizing**: `CombatState.reset(state, player_count, opp_count)` + `to_battle` sizes each side from its own grid; `GridSystem.neighbors(.., slot_count)` guards ragged 5/7. Growth helper = **`ForgeSystem.apply_grid_growth`** (idempotent; in ForgeSystem not ShopSystem to avoid class cycle; hooked in `ForgeSystem.attempt` + `ShopSystem.resolve_drop`). **Asymmetric boards embraced**; opponent board now **round-scaled** too (`OpponentProvider._max_slots_for_round`, `OPPONENT_SLOTS_ROUND_BREAKS=[1,3,5,8]` → 2→3→4→5→6, capped `GRID_HARD_MAX`) so a grown player isn't vs a fixed 4-slot ghost. **Reactive adjacency IS in combat** for `adjacency_upgrade` (Ember, Photosynthesis) via `combat_adjacency` + `GridSystem.neighbors`. Faction threshold synergies deferred. **F5 eyeball pending.** See `handoff-run-loop.md`.

## Steam + backend seams
- **OpponentProvider** (`systems/`): `get_opponent(context)` → Ghost `{player_id,player_name,round,grid,acquired_day,source}`. LocalDaySeededAdapter + GhostFixtures fallback.
- **AchievementSystem** (`systems/`): pure `check(state, profile, event)→Dictionary`. 5 achievements (round/match/forge events).
- **PlayerProfile** autoload (`user://profile.cfg`): stats/progress/discovery; master for `discovered_recipes`.
- **GhostFixtures** (`data/`): 3 prebuilt snapshots (tier 1/2/3); test + deterministic fallback.
- **PlatformLayer** (identified, NOT built): SteamAdapter / NoOpAdapter for web.

## Status Effects (2026-06-03, gated by `status_effects`)
**Effect** = passive string on element, fires on cooldown. **Status** = ongoing condition in `player_statuses`/`opponent_statuses` (flat dict/side). Reset in `to_battle()`.
T1: burn (ramp stacks, tick dmg), poison (permanent stacks), armor (absorb), plating (flat reduction, never depletes), blind (miss roll, cap 50%), shock (CD slow 50n/(n+5)), heal, cleanse (remove 1 debuff stack), curse (amplify), leech (heal=dmg), weaken (timed, reduce attacker dmg). API: `empty_statuses`/`apply_effect`/`tick`/`compute_incoming_damage`/`slow_pct`/`is_active`/`active_statuses`/`describe`/`chip_badge`.

## Ability System (2026-06-03; ADR 0003/0004)
- **Time = integer deciseconds** (`cooldown_deciseconds`). Effective CD floored at 10 (1/sec). Blind = int percent (+15/stack, cap 50). Plating int (T2→1,T3→2,T4→3–4). Global `COMBAT_COOLDOWN_MULTIPLIER` dial in `effective_cooldown_deciseconds`.
- **`data/AbilityData.gd`** (pure data by id) + **`systems/AbilitySystem.gd`** (execution). One ability/element v1. Buffs→own side, debuffs→opponent. Schema `{trigger, effects:[{kind,status/amount/seconds,target,when?,chance?}], interval_deciseconds?, adjacency_upgrade?, description}`.
- **Triggers:** combat_start (t=0), periodic (first at +interval), passive (queried at calc site; probabilistic roll per-hit from seeded RNG in slot order), `on_activate` (each fire; optional `every_n` gates off `fires` tally, deterministic — ADR 0006), reactive `on_*`. **Depth-1:** reactive output emits no further reactives, never multicasts. Scan slot 0…N.
- **Combat events (ADR 0004):** built by `AbilitySystem.fire_event/miss_event/trigger_event`. Fire events `{side,slot,damage,effect,is_miss}` = visual+reactive (only ones in `battle_events`); trigger events `{trigger,side,slot}` (on_burn_tick/on_poison_tick/on_armor_stripped/on_haste_applied) reactive-only (`is_visual_event()` filters). A DOT tick on one side = the other side's event.
- **Multicast:** repeats full fire N× (T2/3 cap 2×, T4 3×); each repeat independent reactive trigger. Periodic/combat_start never multicast.
- **Curse v2 (ADR 0013):** `curse.{stacks, damage_amplifier}` — charges consumed per damaging event (hit OR DOT >0), each adds amplifier; 0 = spent. No duration. Level-scales; `void`/`voidrift` apply 10.
- **Modifier fields** (set via combat_start `set_status_field`): `burn.tick_damage_bonus`, `poison.tick_damage_bonus`, `shock.effective_stack_bonus`, `plating.reduces_dot`, `armor.floor`, `weaken.duration_bonus`, `haste.reduction_bonus_deciseconds`, `leech.{bonus,double}`, side-wide signed `cooldown_modifier_deciseconds`.
- **Freeze:** per-side float-seconds arrays + `*_last_frozen_slot`; frozen slot paused (skip fire, CD stalls); `select_freeze_target` anti-permalock. Own logic, not StatusSystem.
- **Grid-agnostic:** size from slot array (`CombatState.SLOT_COUNT`); `GridSystem.dimensions`/`neighbors`; `systems/CombatSide.gd` = single side→state-key map. v1: T2+T3 fully filled, T4 stubbed.

## Balance tooling — NEVER BUILT (corrected 2026-06-09)
**BalanceSystem does not exist.** ADR 0002 (DPS+Effect Score, Compendium dev panel) was an unbuilt plan (superseded); only inert `FeatureFlags.efficiency_scoring` remains. **Tune empirically via `BattleSystem.simulate_battle()`** (deterministic — combat is real, sim is ground truth). G4 targets: run ~12–18 rounds, KO ~10–20s, T2~r3–4/T3~r7–9/T4~r12+, forge penalty 1, status magnitudes ×1, ~60% win vs broadened ghost pool, Lv3 = stat-bump knob.

## Deferred / TBD
Run-loop backlog in `.claude/ai-helper/handoff-run-loop.md`. Key deferred: T2 placeholder names, Level 2 Reward impl, Innate/Replay UI + economy, Faction synergy + grid adjacency, Draft system, Meta-progression shape, PlatformLayer, Battlegrid size + in-game grid growth, T4 ability fill. Renames pending: `"effect"` field → `"action"`, `effect_score` → `action_score`.
