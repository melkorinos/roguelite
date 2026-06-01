# Development Log

## 2026-05-25
- Initialized project scaffold via architecture grilling session
- Confirmed toolchain: Vite + TypeScript + pnpm + Vitest + Phaser 3
- Confirmed entity model: plain data objects + standalone systems, no ECS framework
- Confirmed GameState: single object, passed explicitly, immutable updates
- Confirmed scene chain: Boot → MainMenu (Start/Settings/Quit) → Game + UIScene overlay
- Deferred: simulation model (turn-based vs action), run pressure mechanics
- Tentative: extraction run structure, puzzle-satisfaction-with-chaos-payoff player feel

## 2026-06-01 (maintainability)
- Strict typing enforced on `systems/` and `data/` — all function signatures typed, arithmetic vars typed, `as` casts for Dictionary access
- Global font size set in project.godot (GUI → theme/default_font_size = 20); all per-node `add_theme_font_size_override()` calls removed from scene scripts
- `.github/workflows/ci.yml` added — `godot --headless --import` + `--quit` on every push; GUT test job scaffolded but commented until tests exist
- CLAUDE.md updated with strict typing rule, theme override rule, and build validation step
- Grilling session established: no Python dependency (gdtoolkit skipped), all 3 validation tiers agreed (parse/boot/tests), GUT chosen when tests begin

## 2026-06-01 (Phase 2)
- Phase 2 complete: Shop → Battle → Result loop fully implemented
- `data/GameState.gd` replaced with auto-battler state (phase/round/gold/inventory/HP/sandstorm)
- `data/ItemData.gd` added — 5 placeholder items (Iron Sword, Wooden Shield, Rusty Axe, Leather Armour, Lucky Charm)
- `systems/ShopSystem.gd` added — buy_item, sell_item, reroll_shop (pure static, no scene refs)
- `systems/BattleSystem.gd` added — get_player_stats, tick_battle, compute_result (pure static, no scene refs)
- `scenes/Shop.tscn` + `Shop.gd` added — FOR SALE list, inventory, Reroll, FIGHT button; full-redraw _render() pattern
- `scenes/Battle.tscn` + `Battle.gd` added — HP display, sandstorm at 10s, result + Next Round / Menu buttons
- `MainMenu.gd` Start → Shop (was Game)
- `scenes/Game.tscn` + `scenes/Game.gd` deleted (walking demo replaced)
- One remaining item: full loop test in Godot editor

## 2026-06-01
- Full migration from Phaser 3 / TypeScript to Godot 4.6 / GDScript — complete
- Deleted all Node/npm/Phaser/TypeScript files; repo is now a pure Godot project
- Phase 1 delivered: Boot → MainMenu → Settings → Game (arrow-key player entity)
- State pattern confirmed: `GameManager` Autoload + pure static system functions
- Shop feel settled: creative expression with soft pressure
- Win/loss feel settled: all three simultaneously — engineered, spectacular, clinical
- Primary play object (A vs B) and meta-progression: deferred
- Two handoff docs merged into one `handoff.md`; all internal docs updated for Godot
- Phase 2 next: Shop → Battle → Result loop

## 2026-05-30
- Major genre pivot: extraction roguelite → auto-battler (ability-chain combat)
- Confirmed inspirations: Super Auto Pets, HBG, The Bazaar, Dota Auto Chess
- Confirmed combat model: Ability Chain (The Bazaar-style) — pieces trigger abilities in sequence, no positional targeting, single Player HP bar per side
- Confirmed: player has one Innate Ability per combat; Replay mechanic lets them retrigger the fight with Innate fired at a different moment
- Confirmed: 8 players per match, async PvP + shared PvE rounds
- Confirmed: Merge (3x same → upgrade, primary) + Forge (A+B→C, costs 2g, secondary)
- Confirmed: Gold shop (pieces) + Draft (items/trinkets) dual economy
- Confirmed: ~30 pieces at launch, rarity tiers (Common/Rare/Epic), 20–30 min sessions
- Confirmed: Steam desktop, async, F2P → paid once
- Confirmed: Light meta-progression (Faction/Synergy unlocks)
- Confirmed: Clean/minimal/weird/surreal aesthetic
- Confirmed prototype shape: Shop → Buy/Organise/Reroll → Click Fight → watch Ability Chain → Result
- Tentative: PvE Bosses as damage/defence check milestones (strong option, not committed)
- Open: primary play object (Scenario A / B / C — units vs single character vs items-as-fighters)
- CONTEXT.md overhauled: extraction roguelite terms retired, auto-battler vocabulary added
- soul.md rewritten, memory.md replaced, goals.md Sprint 1 drafted
