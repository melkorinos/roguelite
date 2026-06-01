# Development Log

## 2026-05-25
- Initialized project scaffold via architecture grilling session
- Confirmed toolchain: Vite + TypeScript + pnpm + Vitest + Phaser 3
- Confirmed entity model: plain data objects + standalone systems, no ECS framework
- Confirmed GameState: single object, passed explicitly, immutable updates
- Confirmed scene chain: Boot → MainMenu (Start/Settings/Quit) → Game + UIScene overlay
- Deferred: simulation model (turn-based vs action), run pressure mechanics
- Tentative: extraction run structure, puzzle-satisfaction-with-chaos-payoff player feel

## 2026-06-01
- Decision: migrate from Phaser 3 / TypeScript / Vite / pnpm to Godot 4 / GDScript
- Existing `src/` kept as reference, to be deleted once Godot port is verified
- Godot project will live in `godot/` subdirectory of the same repo
- State pattern: Autoload singleton (`GameManager.gd`) + pure static system functions
- Shop feel settled: creative expression with soft pressure
- Win/loss feel settled: all three simultaneously — engineered, spectacular, clinical
- Meta-progression and primary play object (A vs B): deferred, not yet settled
- Phase 1 handoff written: working Godot project, Main Menu + 1 controllable entity
- Phase 2 will add Shop → Battle → Result loop (see handoff.md for spec)

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
