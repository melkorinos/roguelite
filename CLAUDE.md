# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A roguelite game built with Phaser 3, TypeScript, Vite, and pnpm. Design is in early flux — extraction-style runs, synergy-driven builds, emergent "broken tool" interactions.

**Before making structural suggestions, read [docs/soul.md](docs/soul.md) and [docs/memory.md](docs/memory.md).**

## Commands

```bash
pnpm install       # install dependencies
pnpm dev           # start dev server (Vite HMR)
pnpm build         # type-check + production build
pnpm test          # run Vitest in watch mode
pnpm test:run      # run tests once
```

## Architecture

**Hard rule:** Phaser lives only in `src/scenes/`. Nothing in `src/systems/` or `src/data/` may import Phaser.

| Folder | Purpose |
|--------|---------|
| `src/scenes/` | Phaser scene classes — rendering and input only |
| `src/systems/` | Pure logic functions — take `GameState`, return `GameState` |
| `src/data/` | Shared types, `GameState` definition, factory functions |
| `src/config/` | Constants and balance values |

**GameState** is defined in [src/data/types.ts](src/data/types.ts). It is a plain object passed explicitly into every system call. Systems must not mutate it — return a new object.

**Scene chain:** `Boot → MainMenu → [Settings] → Game` with `UIScene` launched as an overlay alongside `GameScene`.

## Design docs

| File | Purpose |
|------|---------|
| [docs/soul.md](docs/soul.md) | Core identity and player fantasy |
| [docs/memory.md](docs/memory.md) | Settled design and architecture decisions |
| [docs/goals.md](docs/goals.md) | Current sprint checklist |
| [docs/log.md](docs/log.md) | Chronological development history |
| [docs/reflections.md](docs/reflections.md) | Post-mortems and iteration notes |

## Assistant behavior

- Coding-first. Slight design awareness.
- When a code decision might lock future design flexibility, say so explicitly.
- When design is undecided, propose options — don't commit.
- Update [docs/memory.md](docs/memory.md) when a decision crystallises. Update [docs/log.md](docs/log.md) when significant work lands.

## Agent skills

### Issue tracker

Issues live in GitHub Issues (`github.com/melkorinos/roguelite`). See `docs/agents/issue-tracker.md`.

### Triage labels

Default mattpocock/skills label vocabulary — no overrides. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context repo: one `CONTEXT.md` at root, one `docs/adr/`. See `docs/agents/domain.md`.

### Environment

Local machine quirks, pnpm 11 config, shell tool to use. See `docs/agents/environment.md`.
