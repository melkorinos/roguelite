# Development Log

## 2026-06-02 — Steam + async PvP infrastructure (OpponentProvider, AchievementSystem, PlayerProfile)

### Files created
- `data/GhostFixtures.gd` — 3 static Ghost snapshots (tier 1/2/3); used as test fixtures and OpponentProvider fallback
- `systems/OpponentProvider.gd` — `get_opponent(context)`: LocalDaySeededAdapter (Fisher-Yates shuffle seeded by `hash(day+round)`), fixture fallback on empty pool
- `systems/AchievementSystem.gd` — `check(state, profile, event) -> Dictionary`: 5 achievements (ACH_FIRST_WIN, ACH_FIRST_FORGE, ACH_CLUTCH, ACH_SURVIVOR, ACH_DAMAGE_20K), recipe merge, damage accumulation
- `autoloads/PlayerProfile.gd` — ConfigFile autoload (`user://profile.cfg`), 3 sections (stats/progress/discovery), `to_dict()`/`from_dict()` for AchievementSystem integration
- `test/unit/test_opponent_provider.gd` — 10 tests
- `test/unit/test_achievement_system.gd` — 23 tests
- `test/unit/test_player_profile.gd` — 20 tests (uses `preload().new()` to bypass singleton)

### Files modified
- `data/GameState.gd` — added `opponent_snapshot: {}` field; `create()` accepts optional `seed_recipes` param
- `systems/PhaseSystem.gd` — `to_battle(state, opponent_snapshot)`: stores snapshot, reads grid from it
- `test/unit/test_phase_system.gd` — updated all `to_battle` calls to pass `GhostFixtures.get_fixture(1)`; added 2 new tests for snapshot storage
- `test/unit/test_battle_system.gd` — updated all `to_battle` calls to pass fixture
- `scenes/screens/Shop.gd` — `_on_fight_pressed` calls OpponentProvider; `_execute_forge` fires forge_discovered achievement if new recipe found
- `scenes/screens/Battle.gd` — `_on_next_round_pressed` calls AchievementSystem.check() + saves profile; immediate save on new achievement, batch save at match end
- `autoloads/GameManager.gd` — `create()` seeded with `PlayerProfile.get_discovered_recipes()`
- `project.godot` — registered `PlayerProfile` autoload (before GameManager)

### Test result
196/196 passing (56 new tests added).

## 2026-06-02 — T1 expansion, tier weights, HP fix, ESC menu, tooltip polish

### Design decisions settled (grill-with-docs session — 6 questions)
- **T1 items expanded** to 10: original 4 + Lightning ⚡, Nature 🌿, Light ☀️, Dark 🌑, Metal ⚙️, Sound 🔊
- **T1 self-combos**: all 10 T1 elements now have a self-combo → Plasma, Forest, Radiance, Void, Steel, Echo
- **Shop tier weights**: shifted toward T3/T4 — T2=65/35, T3=45/35/20, T4=25/30/30/15
- **Level 2 Reward** design: gold + flat stat boost choice; deferred implementation
- **ESC Pause Menu**: Resume, Settings, Forfeit Run, Quit to Main Menu, Quit to Desktop

### Files changed
- `data/ElementData.gd` — 6 new T1 + 6 new T2 self-combo results (20 T2 elements total)
- `data/RecipeData.gd` — 6 new self-combo recipes (10 total)
- `data/UIScale.gd` — TOOLTIP_ constants +5% (17/14/12/13)
- `systems/PhaseSystem.gd` — `advance_round()` resets `player_hp = 30`
- `systems/ShopSystem.gd` — `_tier_thresholds()` + `_pick_tier()` + weighted `reroll_shop()`
- `scenes/shared/TooltipCard.gd` — emoji stat keys (▲⬆⏱⚔💥💰); panel 230px wide
- `scenes/shared/PauseOverlay.gd` — NEW CanvasLayer pause menu (layer 110)
- `scenes/screens/Shop.gd` — PauseOverlay + ESC handler + pause signal handlers
- `scenes/screens/Battle.gd` — PauseOverlay + ESC handler; simulation pauses with overlay
- `test/unit/test_phase_system.gd` — HP test renamed to assert reset
- `test/unit/test_shop_system.gd` — 3 new tier-weight tests

## 2026-06-02 — Architecture refactors (improve-architecture)
- **Candidate 1**: ElementData.effective_damage now used by BattleSystem + TooltipCard. Was inconsistent: tooltip showed dmg×lv+tier, battle dealt dmg×lv. Fixed. Formula lives in one place.
- **Candidate 2**: ShopSystem 6 buy/swap fns → 1 `transfer(state, from_loc, to_loc)`. from/to: `{"zone":"shop"|"inventory"|"grid","slot":int}`; slot=-1=first empty. Shop.gd updated. test_shop_system.gd rewritten. 138/138 passing.

## 2026-06-02 — Match persistence: Lives + win goal + gold income
- Player HP in-battle only (resets to 30 in to_battle). Lives starts 10; hard loss→–3, medium→–2, close→–1; 0=eliminated. 10 wins=victory. +5g/round in advance_round.
- GameState: +lives, +wins, +opponent_starting_hp. PhaseSystem + Battle + Shop updated. 140/140 passing.

## 2026-06-02 — UIScale + system-layer mutations + shop overhaul + battle summary
- UIScale.gd: named constants + apply(node, size). All bare font overrides gone.
- ShopSystem: swap_inv_to_grid/swap_grid_to_inv/swap_within_grid (later collapsed to transfer). ForgeSystem: move_to_forge_slot, forge_quick_slot, remove_from_forge_slot.
- Shop full rewrite: drag-drop dispatch, SOLD placeholders, forge bench, undo (Ctrl+Z), sell zone, buy+upgrade ConfirmDialog, drag hints.
- BattleSystem: battle_stats accumulated per slot (fires+dmg). Battle: Summary toggle (fires+dmg+DPS). Pause + 1×/1.5×/2× speed controls.

## 2026-06-02 — Item Tooltip + scene folder restructure
- TooltipCard.gd: CanvasLayer layer=100, 0.3s hover timer per slot, cursor-follow + edge-flip. All slot types emit tooltip_requested/hide_requested.
- Folders split: scenes/screens/, scenes/slots/, scenes/shared/. All res:// paths updated.

## 2026-06-02 — Element system + forge + self-combos + scope cut
- Scenario C confirmed: elements are fighters. ItemData→ElementData (29 elements, 25 recipes, 3 tiers). RecipeData: order-independent lookup. ForgeSystem: level_up, forge, preview.
- Self-combos added (W+W→Ice, F+F→Blaze, A+A→Gale, E+E→Boulder). Tiers 4+5 removed.
- GameManager: undo_state, save_undo, apply_undo. Compendium scene added (programmatic card grid).

## 2026-06-01 — Godot migration + Phase 2 loop + maintainability baseline
- Migrated Phaser3/TS → Godot 4.6/GDScript. Phase 1: Boot→MainMenu→Settings. Phase 2: Shop→Battle→Result loop.
- Pure static systems: ShopSystem (buy/sell/reroll), BattleSystem (tick/compute_result), PhaseSystem.
- Strict typing on systems/+data/. UIScale baseline. GUT installed. CI (import+quit+tests).

## 2026-05-30 — Genre pivot + design foundations
- Pivot: extraction roguelite → auto-battler. Confirmed: Ability Chain combat, Innate Ability + Replay, 8-player async PvP, Merge+Forge, dual economy (Gold+Draft), ~30 pieces, Steam desktop.
