# Development Log

## 2026-05-25
- Initialized project scaffold via architecture grilling session
- Confirmed toolchain: Vite + TypeScript + pnpm + Vitest + Phaser 3
- Confirmed entity model: plain data objects + standalone systems, no ECS framework
- Confirmed GameState: single object, passed explicitly, immutable updates
- Confirmed scene chain: Boot → MainMenu (Start/Settings/Quit) → Game + UIScene overlay
- Deferred: simulation model (turn-based vs action), run pressure mechanics
- Tentative: extraction run structure, puzzle-satisfaction-with-chaos-payoff player feel
