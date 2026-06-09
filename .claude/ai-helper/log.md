# Development Log

## 2026-06-09 — In-combat Status Tray (grilled) — playtest legibility
- Per-side **Status Tray** of hoverable emoji **Status Chips** in Battle.gd (between side label + grid), showing every active Status (buffs green / debuffs red, tinted by valence) + a **stack-count badge** beside each emoji (`StatusSystem.chip_badge`; "∞" for permanent curse). Hover → framed **Status Readout** with live magnitudes from the pure `StatusSystem.describe(name, statuses)` (e.g. "Burning: 3 damage/tick · 3 stacks left", "Hasted: fires 0.3s sooner") — numbers match combat. `EffectRegistry` gained `emoji`+`valence`; `StatusSystem` gained `is_active`/`active_statuses`/`describe`/`chip_badge`. New `scenes/shared/StatusChip.gd` (`_make_custom_tooltip` = framed popup, ThemeData-styled); tooltip delay halved to 0.25s (`project.godot`). Chips built once, toggled per render. ThemeData tints/readout colors + `UIScale.STATUS_CHIP`/`STATUS_COUNT`. CONTEXT terms added. **515/515**, boot 0. **F5 eyeball:** tray layout + framed hover readouts + badges.

## 2026-06-09 — Arch review #4 (reviews/…20260609.html) + candidates A & C landed
- Review of the recent work (Event/Sandstorm/Ghost/balance). 4 candidates. **A (Strong):** new `ElementData.instantiate(id, level)` factory — the "duplicate def + set element_id/level" pattern was reimplemented 7× (Event & Ghost work added 2). Routed GhostFixtures/OpponentProvider/ShopSystem/ForgeSystem×2/Shop.gd through it. **C (Worth):** new `ShopSystem.grant_to_inventory(s, instance)→bool` (in-place, first-empty slot) — StartSystem `apply_starting_pick` + EventSystem `_grant_element` + Shop debug-add now share it (callers keep their on-full policy: Start drops, Event → gold). Pure refactor, zero behaviour change. **500/500**, boot 0. **B (route `compute_opponent_hp` through `effective_damage` — fixes the opp-HP plateau) deferred to the G4 balance pass** (shifts HP values). **D (Run Modifier registry) parked — contradicts ADR 0011.**

## 2026-06-09 — G4 ghost generator + HP/cooldown tuning (Batches 1–2 applied, paused for playtest)
- **Round-scaled ghosts:** `OpponentProvider._day_seeded_grid` rewritten — mostly the round's max tier + lower-tier filler, **levelled by round**, family-coherent, still day+round seeded; knobs `GHOST_TOP_TIER_FRACTION`/`GHOST_LEVEL_ROUND_BREAKS`. `GhostFixtures` kept for tests. Was a uniform Lv1 grab-bag (useless for tuning a curve).
- **Empirical tuning** via a throwaway `simulate_battle` sweep (deleted; not committed). Applied **Batch 1** (`BASE_PLAYER_HP`/`OPPONENT_BASE_HP` 200→130, `HP_PER_ROUND` 3→14) → fixed the ~80% late-game loss cliff. **Batch 2** (`HP_PER_ROUND`→11 + new `COMBAT_COOLDOWN_MULTIPLIER`=0.7, a global firing-rate dial in `StatusSystem.effective_cooldown_deciseconds` that speeds fights without inflating opp HP) → early KOs mostly in-window, but late game over-corrected to ~33–46%. **Batch 3 (per_round→13) proposed, NOT applied — user playtests first.**
- **⚠ Found:** opponent HP plateaus ~230 from r7 (`compute_opponent_hp` ignores level) — make it level-aware next. Fixed 2 timing-fragile battle tests (added `_silence_opponent`) + made 6 cooldown-formula tests multiplier-aware. **500/500**, boot 0.

## 2026-06-09 — G4 kickoff: Sandstorm sudden-death (grilled; ADR 0012) + BalanceSystem myth busted
- **Grilled G4 scope.** Method = tune **empirically via `simulate_battle`** (combat is real+deterministic); dedicated sim scripts later. **Discovery:** `BalanceSystem`/Effect-Score table/Compendium dev panel described in docs+memory+ADR 0002 were **never built** (only the inert `FeatureFlags.efficiency_scoring` flag exists) → marked ADR 0002 superseded + CONTEXT "Developer tooling" flagged unbuilt. G4 targets locked: run ~12–18 rounds, fights KO in ~10–20 s, T2~r3–4/T3~r7–9/T4~r12+, keep forge penalty 1, status magnitudes stay ×1 for now (documented), ~60% win-rate vs a broadened ghost pool (precursor task), Lv3 = stat-bump knob (no new mechanic). Done-when defensible-first-values + 1 F5 run, not perfection.
- **Sandstorm (ADR 0012):** `BATTLE_TIME_LIMIT`(30) is now the storm **start**, not a hard end. `BattleSystem._tick_sandstorm` deals escalating **true** damage (`SANDSTORM_BASE+RAMP*k`, both sides, bypasses ALL mitigation — deliberate, knob-flagged) each storm-second until a KO; `compute_result` unchanged (opp eliminated = win; mutual = draw=win). End = elimination OR `SANDSTORM_HARD_CAP_SECONDS`(60) backstop; `simulate_battle` step cap rebased to it. New per-combat `sandstorm_ticks` (create+reset). Symmetric, inert (no events/reactives), deterministic. **No visual feedback yet** (deferred). **496/496**, boot 0. CONTEXT "Sandstorm" term.

## 2026-06-09 — Feature 4: every-N Event node + reward framework (grilled; ADR 0011)
- North-star loop piece. **Event** = non-combat choice node every `EVENT_EVERY_N_ROUNDS`(3) rounds (before the shop): offers `EVENT_OFFER_COUNT`(3) distinct **Event Rewards**, pick one. New pure `systems/EventSystem.gd` (`is_event_due`/`offer`/`apply_reward` + `build_grant_element_reward`); offers seeded `hash("event:%d"%round)` for Replay parity. Reward kinds: `gold`, `bonus_hp`→`hp_bonus`, `reroll_discount`(new field, subtracted in `ShopSystem.reroll_cost` floored 0), `grant_element` (capped at `max(unlocked_tiers)`, family-filtered `eligible_for_tier`, straight to inventory, full→gold; **never** writes `run_discoveries`). Persistent **Run Modifiers** = discrete fields (chose over generic modifier list). UI: `EventOverlay` (scenes/shared, mirrors `StartingPickOverlay`) shown blocking in `Shop._ready`; `last_event_round` guards re-entry; starting-pick has round-1 priority. New GameState `reroll_discount`/`last_event_round`; TuningData EVENT_* knobs; CONTEXT terms Event/Event Reward/Run Modifier. **491/491**, boot 0. Deferred: `trinket` (no system), board-wide `damage_bonus` (no seam). **F5 eyeball:** event overlay layout + reward apply.

## 2026-06-09 — Arch review #3: index data modules (#1) + drop seam (#2)
- Review `reviews/architecture-review-20260607-c.html` (7 candidates, 3 strong). **#1:** `ElementData`/`RecipeData` → `const ELEMENTS`/`const RECIPES` (built once) + lazy static indices behind the **unchanged** interface (was rebuild+scan per call, in render loops); mirrors AbilityData; zero-copy `find()` (audited — mutators already `.duplicate()`). **#2:** `ShopSystem.can_drop`/`drag_to_loc` seam; InventorySlot/BattleSlot `_can_drop_data` → one-liners; `can_transfer` kept public. **469/469**, boot 0. **#3 (extract ForgePanel from 794-line Shop.gd) NOT started** — scene-UI refactor, no unit-test net; pending F5 decision.

## 2026-06-07 — Concern C: eliminate forward dead-end elements (grilled; ADR 0010)
- Was 24 T2 + 11 T3 elements never used as a higher-recipe ingredient (audited via `comm`). Now **invariant: every element < T4 is an ingredient in ≥1 higher recipe** → forge path to a T4 Phenomenon from anything. Added **22 recipes** (`RecipeData` 169→191), **cluster-routed** for theme (frost/nature/storm/earth/blood/fungus/light-dark/metal); mostly alt-paths, two dead-ends paired per recipe. No prunes/new elements — prism routed via `prism+rain→rainbow` (kept, not cut). Locked by `test_no_non_apex_forward_dead_ends` + `test_no_duplicate_recipe_pairs`. Family/economy rebalance → G4. **459/459**, boot 0.

## 2026-06-07 — G2 polish + bug fixes (forge discoverability round 2)
- Fixed `CONFUSABLE_LOCAL_DECLARATION` in `ShopSystem._buy_into` (single `s`). Forge hint reworked: **Made from** (new pair-preserving `RecipeData.recipes_for(id)`) + **Forges with**, each a hoverable **chip** → shared `TooltipCard.show_for` (no card dup); removed scroll/max-height; `Compendium._recipes_for` shares the helper. Item Tooltip gains a MADE FROM line (`_render_made_from`, id-guarded vs battle refresh). **457/457**, boot 0.

## 2026-06-07 — Run-loop G1/G2 + arch reviews #1/#2 (all grilled)
- **G2 Forge discoverability (ADR 0009):** reveal all (`hidden_recipes` inert seam). Bench hint `Shop._update_forge_partner_hint` off new pure `RecipeData.recipes_with(id)` (owned-first, warns < Lv2); "📖 Compendium" button in Shop returning via `GameManager.compendium_return_scene`. **453/453**.
- **G1 Forge leveled inputs (ADR 0008):** both inputs Level ≥ `FORGE_MIN_INPUT_LEVEL`(2); result = `max(1, min(inputs) − FORGE_RESULT_LEVEL_PENALTY(1))` (Lv2+Lv2 → Lv1 next tier; −1 makes the Merge tax recur per tier, knob to 0). Under-level → `level_too_low` (staged); self-combos no exception; `FORGE_GOLD_COST=0` wired. Guards in `_forge_pair`/`_forge_bench`+previews; Shop messages. Merge ungated. Threshold re-tune deferred to G4.
- **Arch review #2 (`reviews/architecture-review-20260607-b.html`): #1** unified Round resolution — who-won was decided 3× with 2 win rules (`compute_result` HP-compare vs `advance_round` opp_hp≤0) → disagreed at 30 s timeout (shown WIN/applied LOSS). New single `PhaseSystem.resolve_round`; canonical rule = **opponent eliminated**; mutual KO = draw = win. **#2** Shop intake: twin `_buy`/`_buy_to_grid` → `_buy_into`; `can_transfer` shop branch → `_shop_target_ok`.
- **Arch review #1:** `ForgeSystem` 9 fns/3 shapes → `attempt(op)`/`preview(op)`, uniform `{state, outcome}`. Win-rule + forge-pacing changes are gameplay-facing (flagged). Boot 0.

## 2026-06-05 — Centralized balance knobs in `data/TuningData.gd`
- New `TuningData.gd` holds all **balance knobs** (economy, progression, run/match, combat, status magnitudes); systems reference it directly (local dup consts removed: REROLL_BASE_COST, TIER_UNLOCK_THRESHOLDS, HASTE_REDUCTION_DECISECONDS, STARTING_*, BATTLE_TIME_LIMIT, opponent curve, sell/gold/HP/Life). Engine/safety (COMBAT_STEP, MAX_STACKS, MAX_REACTIONS) + UI/infra stay local → a future "config constants" file. `CombatState.SLOT_COUNT` re-exports `GRID_SIZE`. Element `price` kept; tier-default table added. Status scalars centralized incl. **×1 placeholders** (no-ops now, tunable later).
- **Behavior changes:** Life loss now proportional `round(clamp(ratio)×MAX_LIFE_LOSS)` (no buckets/floor); player HP scales `BASE+(round-1)×HP_PER_ROUND+hp_bonus` (new reward-hook field) + `player_starting_hp` for the HP-bar max (also fixed pre-existing opp-bar overflow). **427/427 green**, boot 0. CONTEXT Life/Player-HP terms updated.

## 2026-06-05 — Forge-gated, family-filtered shop pool (ADR 0007)
- **`shop_tier` retired.** A tier appears in the shop only after forging N distinct of it this run (`ShopSystem.TIER_UNLOCK_THRESHOLDS` 3/2/1); once unlocked, shows only that tier's elements from the **families** the player forged with (`eligible_for_tier`/`_families_for_tier` + `RecipeData.ingredients_of`). T1 = full pool always + guaranteed ≥1 T1 slot; higher slots spread across families (`_pick_spread`).
- New per-run `run_discoveries` in `GameState` (forge-written; `discovered_recipes` unchanged). Opponent power now scales by **round** (`OpponentProvider._max_tier_for_round`), not shop_tier. Grilled via /grill-with-docs; CONTEXT terms (Run Discovery, Family, Starting Pick) added.
- **430/430 green**, boot exit 0. Next run-loop item: the every-3-match event.

## 2026-06-05 — Run-loop kickoff: escalating reroll + starting pick
- **Escalating reroll**: `ShopSystem.reroll_cost` = `2 + reroll_count`; paid rerolls increment, `advance_round` resets, Shop button shows live cost. Free rerolls exempt.
- **Starting pick**: `systems/StartSystem.gd` (`starting_options`/`apply_starting_pick`) — run-start offers 3 T1s, chosen one buffed ×2 via `damage_multiplier` field read in `effective_damage`; `StartingPickOverlay` shown in `Shop._ready` (round 1, gated by `starting_pick_done`). Overlay needs an F5 eyeball.
- First two items of the consolidated `handoff-run-loop.md`. **422/422 green**, boot exit 0. Next: /grill the forge-gated shop pool.

## 2026-06-05 — Last 10 abilities landed + `on_activate` trigger (ADR 0006)
- New **`on_activate`** trigger (`AbilitySystem.apply_on_activate`, hooked in `_fire_element_once`): compound on-fire payloads the single-string `effect` field can't express. Optional **`every_n`** gates effects to every Nth activation off the existing `fires` tally — deterministic, no new state, no RNG (Shrapnel: `[shock]` every 3rd fire).
- Filled the final 10 stubbed abilities — T2 shrapnel/rootrot/gore/rot/moldsteel (gore = `effect:"leech"` lifesteal + on_activate weaken); T3 rainbow/plant/ash/ancientgrove/voidrift (ash redesigned → `on_burn_applied`). ADR 0006 + CONTEXT "Every Nth Activation" term.
- Designed via /grill-with-docs after the 5 landed arch candidates (CombatState / ElementCard / resolve_drop / CombatSide / one-effect-engine). **407/407 green**, boot exit 0. Deferred (agreed): grid growth, Innate/Replay UI, T4 fill.

## 2026-06-04 — Abilities live: flags default-on + tooltip/Compendium wiring
- `FeatureFlags` all default **true** (early-state: ship everything on; only `status_effects` is code-read). Abilities now apply in combat. 341/341 still green.
- TooltipCard + Compendium card now render `AbilityData.get_ability(id).description`. Handoff doc updated with impl status + remaining work (glossary hover, ~23 skipped abilities, adjacency, T4).

## 2026-06-04 — Battle UX: Charge Bar smoothing + Summary effect breakdown
- Named the slot cooldown bar the **Charge Bar** (`BattleSlot.set_charge`; CONTEXT term). Fixed-timestep made it fill in chunks; `Battle.gd._update_side_charge` now interpolates with `_combat_accumulator` between steps (skipped while frozen) → smooth.
- Battle Summary now shows a per-status breakdown ("2 blind, 2 burn") instead of "N fx": `battle_stats` slot gains `effects_by_status`; `AbilitySystem._apply_atom` returns a {status:count} map, `BattleSystem._tally_effect` records on-fire/on-hit. 386/386 green.

## 2026-06-04 — Battle perf pass (review in `.claude/ai-helper/perf-notes.md`)
- **#1 in-place tick**: `resolve_reactive_inplace`/`resolve_periodic_inplace`/`apply_command` mutate the tick's existing duplicate (removed ~3 deep copies/frame); public duplicating forms kept for tests.
- **#2 fixed timestep**: `BattleSystem.COMBAT_STEP_SECONDS=0.1` + `Battle.gd` accumulator (frame-rate-independent); `simulate_battle()` headless/Replay sim, deterministic + step-capped.
- **#3 infinite-build guards**: `StatusSystem.MAX_STACKS=99`; `AbilitySystem.MAX_REACTIONS_PER_TICK=1024` circuit breaker. (Existing guards: 10-ds cooldown floor = 1 fire/sec/elem, 30s cap.)
- **#5**: float-label cap (40). **Deferred (brainstorming):** per-combat ability caches (#4) + ElementData lazy cache — noted in code + perf-notes.md. **385/385 green.**

## 2026-06-04 — Battle Summary "effects applied" tally
- `battle_stats` slot rows gain `effects`; counted in `_fire_element_once` (T1 effect + on-hit procs) and `AbilitySystem._apply_effects`/`_record_effects` (ability status applications, attributed to source slot). Summary shows "N fx". 380/380 green.

## 2026-06-04 — Doc-consistency pass + round-lifecycle section
- Added "Round lifecycle (shop→battle→result)" to CLAUDE.md for future readers. Fixed discrepancies in memory.md (freeze field names, `cooldown_modifier_deciseconds`, adjacency-in-combat, flag list) + CONTEXT.md (Board adjacency). Rewrote handoff lean (~520→102 lines; dropped implemented proposal tables, kept status/pending/T4/rules). settings.json: allow read-only PowerShell getters + robust `.claude/ai-helper/**` edit perms.

## 2026-06-04 — Tooltip: live battle stats + keyword glossary + shift-to-pin
- Razorwind ability added (on_status_applied weaken → shock); was the element showing "— none yet —".
- TooltipCard `show_for_battle(element, side, slot)` live-updates in combat: effective cooldown (shock/CD-mods) + weaken-adjusted damage, refreshed each frame. Shop keeps base stats.
- `data/StatusGlossary.gd` NEW; ability text now a RichTextLabel with `[url]` keyword links. **Hold Shift** pins the card; hovering a keyword shows a glossary sub-card. RichText text guarded against per-frame resets (no hover flicker).
- **378/378 green.** Boot exit 0. ~10 abilities still skipped (down from 21).

## 2026-06-04 — Combat-event model centralised + CombatSide + Innate/Replay seam
- **Combat events** now built by `AbilitySystem.fire_event/miss_event/trigger_event` (one source of shape). `battle_events` filtered to visual (fire/miss) only — `is_visual_event()`; trigger events (tick/armor/haste) are reactive-only. Battle.gd guarded. Documented in CONTEXT.md + ADR 0004 + memory.md. (Fixes latent crash: typed events lacked `slot` the view read.)
- **C3 CombatSide** NEW: single source for side→state-key mapping (`keys`, `opponent_of`, getters). `_make_side_ctx` + `_side_keys` now delegate; the two hand-rolled key maps deleted.
- **C4 Innate/Replay seam:** `pending_commands` in GameState; `BattleSystem.queue_command` + `_drain_commands` (fire timed commands when the clock reaches them); `AbilitySystem.resolve_command`. Reproducible via the seeded RNG. Backend seam only — UI later.
- **372/372 green.** Boot exit 0.

## 2026-06-04 — Architecture review #2 + deepenings: passive-modifier layer + tick/armor events
- **Review #2** in `.claude/ai-helper/reviews/architecture-review-20260604-b.html`.
- **C1 passive-modifier layer:** new status-dict modifier fields read at calc sites — `haste.reduction_bonus_deciseconds` (gust), `leech.{bonus,double}` (pulse, ichor), `plating.reduces_dot` (steel), `armor.floor` (mountain), `weaken.duration_bonus` (blackice). Set via combat_start `set_status_field`. Also wired magnet (on_status_applied shock→plating), tempest/acid (display).
- **C2 tick/armor/haste events:** `StatusSystem.tick` returns `events` (on_burn_tick/on_poison_tick); `_fire_element_once` emits on_armor_stripped; `_event_triggers` adds on_haste_applied. `resolve_reactive` now handles typed-trigger (slot-less) events + **chance-gated** reactives (seeded RNG). Wired miasma (25% blind on poison tick), rust (on_armor_stripped), aurora (on_haste_applied).
- 12 more abilities live (~11 still skipped: shrapnel, rootrot, gore, razorwind, rot, moldsteel, rainbow, plant, ash, ancientgrove, voidrift). **362/362 green.**

## 2026-06-04 — Architecture review + deepenings 1/2/3 (review in `.claude/ai-helper/reviews/`)
- **C1 condition layer:** effects take an optional `when: [conditions]` guard (`target_has_status at_least`). Conditional clauses restored on surge/blight/sporeflow/cryptbloom/arcbeam/wildrot.
- **C2 typed events + adjacency:** reactive resolution reads the event's source slot; `adjacency_upgrade` abilities (Ember, Photosynthesis) gated by `FeatureFlags.combat_adjacency` (default true) via `GridSystem.neighbors`.
- **C3 seeded CombatRng:** `combat_rng_state` int in GameState, seeded per-round in `to_battle`, threaded through `tick_battle`→`_tick_side`→`_fire_element_once`. Blind + on-hit passives now draw from it → reproducible Replay/Ghost playback. **Wired `passive_on_hit`** (Dust/Static/Pollen/Flint/Sand) which previously did nothing in combat.
- **351/351 passing.** Boot exit 0.

## 2026-06-03 — Ability system: decisecond refactor + AbilitySystem engine + T2/T3 data
- Grilled full ability design (5 rounds); decisions in ADR 0003/0004 + memory.md. Built test-first in 6 slices.
- **Decisecond time model:** `cooldown`→`cooldown_deciseconds` (int ×10) across ElementData/BattleSystem/scenes; `StatusSystem.effective_cooldown_deciseconds` floors at 10 (1 fire/sec) + shock-slow round. Tooltip shows `2.5s`.
- **StatusSystem:** integer blind percent, curse `{ticks_remaining,is_permanent,damage_amplifier}`, burn/poison `tick_damage_bonus`, shock `effective_stack_bonus`, signed side-wide `cooldown_modifier_deciseconds`; plating+haste de-decimalised.
- **GridSystem** NEW (dimensions + orthogonal neighbors, grid-agnostic). **Freeze**: per-side `*_frozen_seconds` + `*_last_frozen_slot`, anti-permalock `select_freeze_target`, paused-CD skip; `_tick_side` loops `grid.size()`.
- **AbilitySystem** NEW: apply_status/deal_damage/modify_cooldown/freeze/set_status_field effects; resolve_combat_start/periodic/reactive(depth-1)/multicast (1 multicast=2 triggers)/on_hit query. Wired into to_battle + tick_battle.
- **AbilityData** NEW: ~87 T2+T3 abilities; T4 stubbed. ~23 needing unbuilt passive-modifier hooks skipped (gust/steel/aurora/miasma/rust/shrapnel/rootrot/pulse/gore/blackice/razorwind/magnet/rot/moldsteel/rainbow/plant/ash/acid/ancientgrove/tempest/mountain/voidrift). Conditional "if X then +Y" clauses reduced to base.
- **341/341 passing** (was 284; +57 new, all existing migrated). Boot exit 0.

## 2026-06-03 — Architecture: AchievementSystem pure + BattleSystem loop collapse
- `AchievementSystem.check()` now pure: takes `profile: Dictionary`, returns `{profile, unlocked}`. Scene layer owns I/O.
- `BattleSystem.tick_battle()` collapsed to single `_tick_side()` helper; `_apply_element_effect` takes explicit key strings.
- **284/284 passing.**

## 2026-06-03 — Settings revamp + Life/lives canon fix (CONTEXT.md is truth)
- `GameState.lives` 10→100; loss amounts –3/–2/–1→–30/–20/–10; UI label "Lives:"→"Life:".
- `Settings.tscn/gd`: deep indigo BG; styled TabContainer (purple selected); sliders: gold/blue/violet fill per channel; back button dark-purple; SFX slider feeds `AudioManager.set_volume_db`.
- **284/284 passing.**

## 2026-06-03 — Procedural chiptune sound effects (AudioManager autoload)
- `autoloads/AudioManager.gd` NEW — generates 7 PCM sounds at startup via `AudioStreamWAV`: click, buy, sell, forge, fire_t1/t2/t3. Mario/chiptune aesthetic (sine for UI, square for actions). 10-player pool.
- Wired to all button handlers in MainMenu, Shop, Battle, Compendium, Settings. Element fire sound tier-matched.
- AudioManager players on "SFX" bus; `_volume_db` seeded from `SettingsManager.get_sfx_volume()` on startup.

## 2026-06-03 — Floating combat labels + shop section color separation
- `BattleSystem` fire events now include `damage`, `effect`, `is_miss`. `Battle.gd` spawns floating labels (Tween 52px up, 0.85s fade) with per-effect colors; miss skips fire animation.
- `ThemeData.gd`: `SHOP_FORSALE_*` / `SHOP_INVENTORY_*` / `SHOP_BATTLEGRID_*` — per-section StyleBoxFlat via Container "panel" override.

## 2026-06-03 — Visual overhaul: elemental area colors + tier borders
- `data/ThemeData.gd` NEW — single color config for all scenes/slots. MainMenu: indigo; Shop: navy; Battle: crimson; Forge panel: purple; Compendium: teal. T1 green / T2 blue / T3 gold item borders.
- All slot scripts (BattleSlot, ForgeSlot, InventorySlot, ShopItemTile, SellZone) reference ThemeData. InventorySlot Button gets full state styling. BattleSlot progress bar styled.

## 2026-06-03 — Element system expansion: T2→T3→T4 (132 elements, 169 recipes)
- T2: Blood+Frost crosses added; Fungus renames (Sonar→Sporeflow etc.); 15 Group-G placeholders. 93 recipes.
- T3: T2+T2 only rule; convergence mechanic (2–3 pairs per T3); 17 new elements incl. Glacier, Blizzard, Inferno. Legacy T1+T2 recipes redesigned.
- T4: T3+T3 only, 16g, "Phenomena" tier; 10 elements (Ice Age, Maelstrom, Supernova…).

## 2026-06-03 → 05-30 — Foundations (collapsed)
- **06-03 Status Effects + 06-02 Foundation:** `StatusSystem.gd` NEW (Sound→Fungus, Blood+Frost, BattleSystem integrated); `OpponentProvider`/`AchievementSystem`/`PlayerProfile`/`GhostFixtures`; `ShopSystem.transfer()`, `ElementData.effective_damage`, `UIScale`; drag-drop/forge/undo/sell/reroll; Life 100 / 10 wins / +5g per round. Tests → `test/unit/{data,systems,autoloads}/`.
- **06-01 Godot migration:** Phaser3/TS → Godot 4.6/GDScript; Boot→MainMenu→Shop→Battle loop; strict typing, GUT, CI. **05-30 Genre pivot:** extraction roguelite → auto-battler.
