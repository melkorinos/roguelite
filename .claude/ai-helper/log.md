# Development Log

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

## 2026-06-03 — Status Effects system (12 T1 elements, gated by FeatureFlags.status_effects)
- Sound→Fungus🍄; Blood🩸+Frost🌨️ added. `StatusSystem.gd` NEW: `empty_statuses`, `apply_effect`, `tick`, `compute_incoming_damage`, `slow_pct`.
- BattleSystem integrated: shock CD scaling, blind miss roll, full effect pipeline.
- **279/279 passing (83 new tests).**

## 2026-06-03 — Housekeeping + tooling
- `ideas.md`, `elements-reference.html`, `FeatureFlags.gd` NEW. Tests moved to `test/unit/{data,systems,autoloads}/`.

## 2026-06-02 — Foundation (Steam seams, shop, battle, element system)
- `OpponentProvider`, `AchievementSystem`, `PlayerProfile`, `GhostFixtures` NEW. 5 Steam achievements wired.
- `ShopSystem.transfer()` unified API. `ElementData.effective_damage` single source. `UIScale.gd` named constants.
- Shop: drag-drop, SOLD placeholders, forge bench, undo (Ctrl+Z), sell zone, tier-weighted reroll.
- Battle: cooldown timers, Summary panel (fires+dmg+DPS), pause, 1×/1.5×/2× speed, PauseOverlay.
- ItemData→ElementData (29→105 elements). TooltipCard (CanvasLayer 100). Compendium scene.
- Match: Life 100, 10 wins, +5g/round. PhaseSystem + BattleSystem pure static.

## 2026-06-01 — Godot migration + core loop
- Phaser3/TS → Godot 4.6/GDScript. Boot→MainMenu→Shop→Battle loop. Strict typing, GUT, CI.

## 2026-05-30 — Genre pivot
- Extraction roguelite → auto-battler. Ability Chain combat, 8-player async PvP, Merge+Forge, Steam desktop.
