# Goals

## Current focus (2026-06-09) — live tracker is the handoff
Phases 1–3 below are the historical foundation. **Active work is the run loop** — see
`.claude/ai-helper/handoff-run-loop.md` for live status, priorities, and backlog. Since
Phase 3: ability system + status effects (combat is real, not placeholder), forge-gated
shop (ADR 0007), forge leveled inputs (0008), discoverability (0009), dead-end elimination
(0010), Round-resolution unification, and an architecture pass (data indexing + drop seam).
**Next:** G4 balance pass · every-3 event (feature 4) · ForgePanel extraction (needs F5).

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

## Deferred / open (status as of 2026-06-09)
- Ability system + status effects — **DONE** (live combat). The sequenced *Ability Chain* model is still planned (CONTEXT: "Ability Chain").
- Innate Ability + Replay — backend seam **DONE** (`pending_commands` + `queue_command`/`resolve_command`); in-combat UI + token economy pending.
- Meta-progression layer — partly underway via the every-3 event (feature 4, handoff) + AchievementSystem/PlayerProfile; full shape TBD.
- Draft system (Items / Trinkets) — not started.
- Faction synergy system — not started (grid adjacency reactives exist; threshold synergies deferred).
- PvE Bosses (optional) — not started.

## Steam + Backend — architecture settled 2026-06-02
Five seams to build (all can be done without a backend):
- [x] OpponentProvider seam + LocalDaySeededAdapter — DONE 2026-06-02
- [x] PlayerProfile autoload (user://profile.cfg) — DONE 2026-06-02
- [x] AchievementSystem.check(state, profile) — DONE 2026-06-02 (called from Battle.gd + Shop.gd)
- [ ] PlatformLayer autoload (SteamAdapter + NoOpAdapter for web)
- [x] opponent_snapshot shape in GameState — DONE 2026-06-02

Needs backend / custom engine build (future):
- BackendHTTPAdapter for OpponentProvider
- GodotSteam custom build + real SDK calls
- Steam Cloud Save sync
- Player accounts + match IDs
- Opponent board submission endpoint

## Internal Milestones (future dedicated session)
In-game achievements that unlock meta-progression content (Factions, Synergies, modifiers). Share AchievementSystem + PlayerProfile infrastructure with Steam achievements. Do not design reward specifics until dedicated session.
