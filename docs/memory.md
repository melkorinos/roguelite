# Memory — Settled Design Decisions

Decisions recorded here are stable enough to build on but may still change.

## Entity model
Plain data objects + standalone system functions. No class inheritance for game entities.
Systems take `GameState`, return `GameState`. No mutation.

## Game state
Single `GameState` object (`src/data/types.ts`) passed explicitly into every system call.
No global singletons for now — revisit if passing state becomes unwieldy.

## Simulation model
Deferred. Game type (turn-based vs action) not decided.
Using Phaser's `update(delta)` loop as the universal starting point.

## Run structure
Extraction (tentative). Enter → scavenge → escape.

## Rendering boundary
Phaser lives only in `src/scenes/`. Logic in `src/systems/` must never import Phaser.

## Toolchain
Vite + TypeScript + pnpm + Vitest + Phaser 3.
