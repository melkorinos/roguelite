# Development Log

## 2026-06-04 — Abilities live: flags default-on + tooltip/Compendium wiring
- `FeatureFlags` all default **true** (early-state: ship everything on; only `status_effects` is code-read). Abilities now apply in combat. 341/341 still green.
- TooltipCard + Compendium card now render `AbilityData.get_ability(id).description`. Handoff doc updated with impl status + remaining work (glossary hover, ~23 skipped abilities, adjacency, T4).

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
