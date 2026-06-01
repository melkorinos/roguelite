# Goals

## Phase 1 — Godot setup (COMPLETE — 2026-06-01)
- [x] Migrate from Phaser 3 / TypeScript to Godot 4 / GDScript
- [x] Project at repo root: `project.godot`, 1280×720, canvas_items stretch
- [x] `GameManager` Autoload, `GameState.create()` factory
- [x] Scene chain: Boot → MainMenu → Settings
- [x] Game scene: player entity moves with arrow keys

## Phase 2 — Core loop: Shop → Battle → Result (first playable) — COMPLETE 2026-06-01

Goal: player lands in a shop, buys items, clicks Fight, sandstorm resolves, sees result, loops back.

- [x] Replace `GameState` with auto-battler state (phase, round, gold, inventory, HP)
- [x] `ItemData.gd`: 5 placeholder items with attack/defence stats
- [x] `ShopSystem.gd`: buy_item, sell_item, reroll_shop — pure static functions
- [x] `BattleSystem.gd`: tick_battle, compute_result, get_player_stats — pure static functions
- [x] Shop scene: FOR SALE list, inventory slots, Reroll button, FIGHT button
- [x] Battle scene: HP display, 10s sandstorm timer, result text, Next Round / Menu buttons
- [x] Update MainMenu Start → Shop
- [x] Delete Game.tscn walking demo
- [x] Full loop test: MainMenu → Shop → Battle → Result → Shop  ← verified in editor

## Phase 2 — complete. ✓

## Phase 3 — Maintainability baseline (COMPLETE — 2026-06-01)
- [x] Strict typing enforced on systems/ and data/
- [x] Global font size in project.godot — no per-node overrides
- [x] GUT installed and configured (.gutconfig.json, res://test/unit/)
- [x] First test suite: test_game_state.gd — 5 tests, 11 assertions, all passing
- [x] GitHub Actions CI: validate job (import + boot check) + test job (GUT headless)
- [x] CLAUDE.md updated with typing rules, theme rules, build check step

## Deferred / open
- Primary play object decision (Scenario A / B — units vs single character)
- Draft system (Items / Trinkets)
- Merge mechanic (3× same → upgrade)
- Forge mechanic (A + B → C)
- Ability Chain combat (real combat, not sandstorm placeholder)
- Innate Ability + Replay mechanic
- Faction synergy system
- Meta-progression layer
- Backend (async PvP)
- Steam packaging (Godot export)

## Deferred / open
- Primary play object decision (Scenario A / B / C) — resolve before Sprint 1 coding begins
- Draft system (Items/Trinkets)
- Forge system
- Innate Ability + Replay mechanic
- Faction synergy system
- Meta-progression layer
- Backend (async PvP)
- Electron (Steam packaging)
- PvE Bosses (optional)
