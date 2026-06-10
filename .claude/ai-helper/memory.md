# Memory — Settled Design Decisions

## Core identity
Auto-battler. Build synergies, break the system, lose to your exact counter, master meta over dozens of sessions. Insps: Super Auto Pets, HBG, The Bazaar, Dota Auto Chess. Steam desktop, async PvP, 20–30 min sessions. Visual: clean, minimal, weird, surreal.

## Entity + state model
Plain data objects + standalone static fns. No class inheritance. Systems take `GameState` dict, return new dict — no mutation. `GameManager.state` global. `GameState.create()` in `data/GameState.gd`.

## Feature flags (`data/FeatureFlags.gd`)
Static class, `static var` (not `const`) so flags flip at runtime. **All default true since 2026-06-04** (early-state policy: ship everything on; flags are kill-switches, not gates). Read by code: `status_effects` (gates the Status pipeline Abilities apply through) and `combat_adjacency` (adjacency_upgrade reactives). `hidden_recipes`/`efficiency_scoring`/`ability_chain`/`innate_ability` are inert placeholders.
- `status_effects`, `hidden_recipes`, `efficiency_scoring`, `ability_chain`, `innate_ability`, `combat_adjacency`

## Match structure
8 players, last standing wins. Each round: Shop phase → combat phase. Mixed PvP + PvE (fixed schedule).
- **Player HP**: in-battle only. Recomputed in `to_battle()` = `BASE_PLAYER_HP + (round-1)*HP_PER_ROUND + hp_bonus` (scales with round + reward bonus). Not a match resource.
- **Life**: starts 100; loss = `round(clamp(opp_hp_ratio,0,1) * MAX_LIFE_LOSS)` — proportional to margin, no buckets, no floor. 0=eliminated.
- **Win condition**: `WIN_THRESHOLD` (10) wins = victory. Draw = player win (opponent async). Both end match → MainMenu.
- **Round win rule (canonical, settled 2026-06-07)**: a Round is won iff the **opponent is eliminated** (`opponent_hp ≤ 0`) — NOT an HP comparison. Mutual KO = draw = win. The single resolver is `PhaseSystem.resolve_round(state)` → `{outcome,is_win,wins_after,lives_*,is_victory,is_eliminated,next_phase,event}`; `describe_result`/`advance_round`/Battle.gd all read it (no second win rule anywhere). `BattleSystem.compute_result` is the classification primitive. **Flat 30 s timeout removed (ADR 0012):** the **Sandstorm** now forces a KO so timeouts effectively never happen.
- **Sandstorm (ADR 0012, 2026-06-09)**: `BATTLE_TIME_LIMIT`(30) is the storm **start**, not a hard end. `BattleSystem._tick_sandstorm` deals escalating **true** damage (`SANDSTORM_BASE_DAMAGE+SANDSTORM_RAMP_PER_SECOND*k`) to **both** sides each storm-second until a KO. **Bypasses ALL mitigation by design** (impartial clock; may route through defenses later — knob-flagged in TuningData). Symmetric, inert (no Combat Events / reactives), deterministic (no RNG → Replay-safe). Ends on elimination OR `SANDSTORM_HARD_CAP_SECONDS`(60) backstop; `simulate_battle` step cap rebased to it. Per-combat `sandstorm_ticks` counter (create+reset). No visual feedback yet (deferred).
- **Balance knobs** live in `data/TuningData.gd` (economy, progression, run/match, combat, status magnitudes incl. ×1 placeholders for burn/poison/armor/plating). Engine/safety/UI constants stay local; a separate config-constants file is planned.
- **Gold income**: +5g per round via `advance_round()`. No streak/interest yet.
- **Rounds unbounded**: match ends at 10 wins OR 0 Life.

## Events (ADR 0011, 2026-06-09)
**Event** = non-combat choice node every `EVENT_EVERY_N_ROUNDS`(3) rounds, before the shop (NOT the future shared-combat "PvE Round"). Pure `systems/EventSystem.gd`: `is_event_due` (`round%N==0`, `round≥2`, guarded by `last_event_round`), `offer(state,rng)` → `EVENT_OFFER_COUNT`(3) distinct reward kinds seeded `hash("event:%d"%round)` (Replay-safe), `apply_reward`. Reward = tagged dict `{kind,...,label,description}`. **One-shot**: `gold`; `grant_element` (→ first empty inventory; capped at `max(ShopSystem.unlocked_tiers)`, drawn from family-filtered `eligible_for_tier`; full→gold; **never** writes `run_discoveries` — forging stays the only tier-unlock). **Persistent Run Modifier** = discrete state field read each round (chose over generic list): `bonus_hp`→`hp_bonus`, `reroll_discount`→subtracted in `ShopSystem.reroll_cost` (floored 0). UI: `EventOverlay` (scenes/shared) blocking in `Shop._ready`, mirrors StartingPickOverlay; starting-pick (round 1) has priority. Deferred: `trinket` (no system), board-wide `damage_bonus` (no seam).

## Combat model
Real-time deterministic. Elements fire on individual cooldown timers. Discrete ticks; result pre-computed, played back visually. Ties: top-left first. RNG seeded at combat start → reproducible.
Status effects on fire via `_apply_element_effect()`; real-time tick via 1s `status_tick_timer`.

## Innate + Replay
Player fires one Innate Ability once per combat at a chosen moment. After loss: spend Replay token, retrigger with Innate at different moment. Tokens: finite per-match. Economy TBD.

## Element system (132 elements, 191 recipes, 4 tiers)
- **Data is indexed (arch #3, 2026-06-09):** `ElementData`/`RecipeData` hold `const ELEMENTS`/`const RECIPES` + lazy static indices; lookups are O(1). `ElementData.find()` and `recipes_*` return **SHARED, zero-copy** dicts/arrays — **`.duplicate()` before mutating** (every current caller does). Mirrors `AbilityData.ABILITIES`. Interface unchanged. Drop validation: slots → `ShopSystem.can_drop(state, drag, to_loc)`/`drag_to_loc`.
- **Instance factory + grant seam (arch #4, 2026-06-09):** build a live instance ONLY via `ElementData.instantiate(id, level)` (duplicates the const def, sets `element_id`+`level`; 7 sites routed through it). Place into inventory via `ShopSystem.grant_to_inventory(s, instance)→bool` (in-place, first-empty; callers own the on-full policy). Candidate **B (route `compute_opponent_hp` through `effective_damage` to fix the opp-HP plateau) deferred to the balance pass**; **D (Run Modifier registry) parked — contradicts ADR 0011**.
- **No forward dead-ends (ADR 0010, 2026-06-07):** every element below T4 is an ingredient in ≥1 higher recipe (T4 apex exempt) → a forge path to T4 from anything. 22 recipes added, cluster-routed; locked by `test_no_non_apex_forward_dead_ends`. Family/economy rebalance deferred to G4.
- **T1 (12, 5g):** Water💧Cleanse, Fire🔥Burn, Air🌬️Haste, Earth🌍Armor, Lightning⚡Shock, Nature🌿Heal, Light☀️Blind, Dark🌑Curse, Metal⚙️Plating, Fungus🍄Poison, Blood🩸Leech, Frost🌨️Weaken. *(Sound retired → Fungus)*
- **T2 (78, 8g):** self-combos (12), originals cross (6), extended cross (24), Blood cross (11), Frost cross (10), extended-to-extended (15). 15 Group-G combos use placeholder names pending brainstorm.
- **T3 (32, 12g):** **T2+T2 only** — no T1+T2 paths. 2–3 convergence paths per element.
- **T4 (10, 16g):** **T3+T3 only**. 3 convergence paths. Compendium label: "Tier 4 — Phenomena".
- **Damage archetypes (ADR 0013):** **pure-effect** (no direct hit — status IS the damage; all T1 + most T2+) vs **damage-dealer** (direct hit; rare ~20% of T2+, impact theme, T4-skewed). Set = whitelist `ElementData.DAMAGE_DEALERS` (gates `effective_damage`, zero data churn). `effective_damage = base × multiplier × level` (**no +tier**; multiplier vestigial; pure-effect → 0). `_fire_element_once` skips the damage block when raw=0. **Level scales effect quantity** (`apply_effect(…, potency)` = source level → N stacks/points). **Starting Pick → +1 level** (×damage buff dead). Opponent HP now round-scaled `100×(1+15%·(round-1))`, board-independent (placeholder).
- **Forge gating (ADR 0008, 2026-06-07):** both inputs must be Level ≥ `FORGE_MIN_INPUT_LEVEL` (2); result level = `max(1, min(inputs) − FORGE_RESULT_LEVEL_PENALTY(1))` (two Lv2 → Lv1 next tier). Merge before Forge; Merge ungated. Under-level → `level_too_low` (items stay staged). `FORGE_GOLD_COST=0` reserved. Knobs in `TuningData`.
- **Forge discoverability (ADR 0009, 2026-06-07):** all recipes revealed (no gating; `hidden_recipes` inert seam). Bench hint (`Shop._update_forge_partner_hint`) shows **Made from** (`RecipeData.recipes_for(id)`, pair-preserving) + **Forges with** (`recipes_with(id)`, owned-first), each a hoverable chip → shared `TooltipCard.show_for` (no card dup). Item Tooltip also shows a MADE FROM line (`_render_made_from`, id-guarded). "📖 Compendium" button returns via `GameManager.compendium_return_scene`. **Open: forward dead-ends** (e.g. Tempered) — handoff concern C, eliminate.
- **Merge**: same element ×2 same level → level+1. Drag-drop. No recipe needed.
- `discovered_recipes[]` in GameState. All visible now; shadow TBD.

## Shop UX (all item moves via ShopSystem.transfer)
- `ShopSystem.transfer(state, from_loc, to_loc)` — `{"zone":"shop"|"inventory"|"grid","slot":int}`; slot=-1=first empty.
- Buy (click)→first empty inv. Drag to matching Lv1→ConfirmDialog level-up. Sell→SellZone→half-price refund.
- Forge bench: 2 ForgeSlots; auto-forge on 2nd drop; F-key quick-forge; slot 2 replaced if both full.
- Undo: 1-action, Ctrl+Z + button. Shop: 5 rotating slots, SOLD placeholder, reroll costs 2g.

## Shop tier distribution (settled 2026-06-02)
`ShopSystem._tier_thresholds(shop_tier)` (cumulative) + `_pick_tier()`. Max element tier is T4.
- T1: 100% T1  |  T2: 65/35  |  T3: 45/35/20  |  T4: 25/30/30/15

## Level 2 Reward (design settled, not yet implemented)
Merging to level 2: flat gold payout + player choice (+1 base damage OR −0.5 s cooldown).

## Scene structure
- `scenes/screens/`: Boot, MainMenu, Settings, Shop, Battle, Compendium
- `scenes/slots/`: BattleSlot, ForgeSlot, InventorySlot, ShopItemTile, SellZone
- `scenes/shared/`: TooltipCard, PauseOverlay

## Rendering boundary
Scene scripts: rendering + input only. Nothing in `systems/` or `data/` may reference SceneTree.
All state mutations: `GameManager.state = SomeSystem.fn(GameManager.state, args)` → `_render()`.

## UI conventions
- **UIScale**: font-size deviations via `UIScale.apply(node, UIScale.CONST)`. No bare integers or direct `add_theme_font_size_override()`.
- **ThemeData.gd**: single-source color config. Never hardcode `Color()` in slot/screen scripts.
- **Item Tooltip**: TooltipCard (CanvasLayer 100), 0.3s hover, cursor-follow + edge-flip. Stats: Tier, Level, Cooldown, Base Dmg, Eff. Dmg, Price.
- **Battle speed/pause**: `_speed_mult` (1×/1.5×/2×) + `_paused`. Controls disabled on result.
- **Battle Summary**: fires+dmg+DPS per element both sides. Toggle below result buttons.

## Pause Menu (settled 2026-06-02)
ESC in Shop or Battle → PauseOverlay (CanvasLayer 110). Resume, Settings, Forfeit Run (→eliminated→MainMenu), Quit to Main Menu, Quit to Desktop. Battle simulation pauses.

## Godot lifecycle rule
`_ready()` fires on `add_child()`, not `.new()`. Set plain properties before `add_child`; call child-node methods only after.

## Board + synergies (partially TBD)
Battlegrid size TBD (backend grid-agnostic, live grid 4 slots). **Reactive adjacency IS in combat** for `adjacency_upgrade` abilities (Ember, Photosynthesis) via `FeatureFlags.combat_adjacency` + `GridSystem.neighbors` — supersedes the old "adjacency at setup only" note. Faction threshold synergies still deferred (see Deferred/TBD below + the handoff).

## Steam + backend seams
- **OpponentProvider** (`systems/`): `get_opponent(context)` → Ghost snapshot `{player_id, player_name, round, grid, acquired_day, source}`. LocalDaySeededAdapter + GhostFixtures fallback.
- **AchievementSystem** (`systems/`): `check(state, profile, event) → Dictionary`. Events: round_win/loss, match_win/eliminated, forge_discovered. 5 achievements.
- **PlayerProfile** autoload (`user://profile.cfg`): sections stats/progress/discovery. Master for `discovered_recipes`.
- **GhostFixtures** (`data/`): 3 prebuilt Ghost snapshots (tier 1/2/3). Test fixtures + deterministic fallback.
- **PlatformLayer** (identified, not built): SteamAdapter / NoOpAdapter for web.

## Status Effects (implemented 2026-06-03, gated by FeatureFlags.status_effects)
**Effect** = passive string on element dict; fires on cooldown expiry. **Status** = ongoing condition in `player_statuses`/`opponent_statuses` (flat dict, shared per side). Reset in `to_battle()`.
T1 mechanics: burn (ramp stacks, tick dmg), poison (permanent stacks), armor (absorb), plating (flat reduction, never depletes), blind (miss roll, cap 50%), shock (CD slow 50n/(n+5)), heal (instant HP), cleanse (remove 1 debuff stack), curse (amplify tick dmg), leech (heal = dmg dealt), weaken (timed stacks, reduce attacker dmg).
**StatusSystem API**: `empty_statuses`, `apply_effect`, `tick`, `compute_incoming_damage`, `slow_pct`. **Readout (2026-06-09):** `is_active`/`active_statuses`/`describe(name,statuses)` (pure, magnitude-filled) drive the in-combat **Status Tray** in Battle.gd (per-side emoji **Status Chips**, buff/debuff-tinted, hover→live readout via native tooltip). `EffectRegistry` entries carry `emoji`+`valence`.

## Balance tooling — NEVER BUILT (corrected 2026-06-09)
**BalanceSystem does not exist.** ADR 0002 (two-axis DPS+Effect Score, Compendium dev panel) was a plan that was never implemented — only the inert `FeatureFlags.efficiency_scoring` flag remains (ADR 0002 marked superseded). **Balance is tuned empirically via `BattleSystem.simulate_battle()`** (deterministic headless sim) — combat is real, so simulation is ground truth. G4 targets: run ~12–18 rounds, fights KO ~10–20 s, T2~r3–4/T3~r7–9/T4~r12+, forge penalty stays 1, status magnitudes stay ×1 for now, ~60% win-rate vs a broadened ghost pool (precursor), Lv3 = stat-bump knob.

## Ability System (settled 2026-06-03, grilling) — see ADR 0003/0004
- **Time = integer deciseconds.** No decimals in combat design values. Field is `cooldown_deciseconds` (was `cooldown`): 2.5s→25; haste −0.3s→−3; penalties +0.8s→+8. Float `delta` converted at one chokepoint. Effective CD floored at 10 (1 fire/sec). Shock-slow result rounded to nearest decisecond. Blind = integer percent (+15/stack, cap 50). Plating = integer everywhere (T2→1, T3→2, T4→3–4). Rebalance cooldowns up so effective firing ≈ 2–5s.
- **`data/AbilityData.gd`** (pure data, keyed by id) + **`systems/AbilitySystem.gd`** (execution). One ability/element for v1. Schema: `{trigger, effects:[{kind,status/amount/seconds,target}], interval_deciseconds?, adjacency_upgrade?, description}`. Compound = array of atomic effects. Buffs→own side, debuffs→opponent (violating spec rows auto-corrected).
- **Triggers:** combat_start (t=0 in `to_battle`), periodic (first fire at +interval), passive (queried at calc site, probabilistic ones roll per-hit from combat-seeded RNG in slot order), `on_activate` (each fire — compound on-fire payload; optional `every_n` gates to every Nth activation off the `fires` tally, deterministic; ADR 0006), reactive `on_*`. **Depth-1 rule:** reactive output emits no further reactives and never multicasts. Scan order slot 0…N.
- **Combat events (ADR 0004):** reactive resolution runs off events built by `AbilitySystem.fire_event/miss_event/trigger_event`. Fire events `{side,slot,damage,effect,is_miss}` are visual+reactive (the only ones in `battle_events`); trigger events `{trigger,side,slot}` (on_burn_tick/on_poison_tick from `StatusSystem.tick`, on_armor_stripped, on_haste_applied) are reactive-only, filtered out of `battle_events` via `is_visual_event()`. Reactives may carry `chance` (seeded roll) + `when` conditions. A DOT ticking on one side is the other side's event.
- **Multicast:** repeats full cooldown fire N× (T2/3 cap 2×, T4 3×). Each repeat is an independent reactive trigger (1 multicast = 2 synergy triggers). Periodic/combat_start never multicast. Echo cut from v1; conditional refire supported.
- **Curse v2 (ADR 0013):** `curse.{stacks, damage_amplifier}` — **charges consumed per damaging event** (incoming hit OR DOT tick that deals >0), each adds `damage_amplifier`; 0 stacks = spent. No duration/`is_permanent`. Level-scales; `void`/`voidrift` apply 10 charges.
- **StatusSystem modifier fields** (set via combat_start `set_status_field`, read at calc sites): `burn.tick_damage_bonus`, `poison.tick_damage_bonus`, `shock.effective_stack_bonus`, `plating.reduces_dot`, `armor.floor`, `weaken.duration_bonus`, `haste.reduction_bonus_deciseconds`, `leech.{bonus,double}`, and side-wide signed `cooldown_modifier_deciseconds` (penalties +, reductions −). Dead `slow` status kept reserved.
- **Freeze:** per-side float-seconds arrays `player_frozen_seconds`/`opponent_frozen_seconds` (parallel to timers, grid-agnostic) + `*_last_frozen_slot`. Frozen slot is paused (skips fire, CD doesn't advance). `BattleSystem.select_freeze_target` anti-permalock. Own logic, not StatusSystem.
- **Grid-agnostic backend:** size derived from slot array (single knob `CombatState.SLOT_COUNT`); `GridSystem.dimensions`/orthogonal `neighbors`. `systems/CombatSide.gd` is the single side→state-key map. v1: T2+T3 **fully filled** (last 10 landed 2026-06-05), T4 stubbed. Armor-strip: no strip-effect, but `on_armor_stripped` event fires when a hit depletes armour to 0 (Rust reacts).
- **Innate/Replay seam:** `pending_commands` in GameState + `BattleSystem.queue_command`/`_drain_commands` + `AbilitySystem.resolve_command`. Reproducible via seeded `combat_rng_state`. UI pending.
- **Tooltip:** `show_for_battle` live-updates effective cooldown + weaken-adjusted damage each frame; `data/StatusGlossary.gd` + RichText `[url]` keyword links; hold Shift pins the card for keyword inspection.

## Deferred / TBD
Run-loop backlog lives in `.claude/ai-helper/handoff-run-loop.md` (`ideas.md` retired). Key deferred: T2 placeholder names (Group-G combos), T2/T3 action design, Level 2 Reward impl, every-3 event (feature 4), Innate Ability economy + Replay UI, Faction synergy + grid adjacency, Draft system, Meta-progression shape, PlatformLayer, Battlegrid size, T4 ability fill. Code renames pending: `"effect"` field → `"action"`, `effect_score` → `action_score`.
