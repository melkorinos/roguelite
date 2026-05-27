# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Session start — mandatory

**At the beginning of every session, read all five files below before doing anything else:**

| File | Purpose |
|------|---------|
| [.claude/ai-helper/soul.md](.claude/ai-helper/soul.md) | Core identity and player fantasy |
| [.claude/ai-helper/memory.md](.claude/ai-helper/memory.md) | Settled design and architecture decisions |
| [.claude/ai-helper/goals.md](.claude/ai-helper/goals.md) | Current sprint checklist |
| [.claude/ai-helper/log.md](.claude/ai-helper/log.md) | Chronological development history |
| [.claude/ai-helper/reflections.md](.claude/ai-helper/reflections.md) | Post-mortems and iteration notes |

Update [.claude/ai-helper/memory.md](.claude/ai-helper/memory.md) when a decision crystallises. Update [.claude/ai-helper/log.md](.claude/ai-helper/log.md) when significant work lands.

## Project

A roguelite game built with Phaser 3, TypeScript, Vite, and pnpm. Design is in early flux — extraction-style runs, synergy-driven builds, emergent "broken tool" interactions.

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

## Assistant behavior

- Coding-first. Slight design awareness.
- When a code decision might lock future design flexibility, say so explicitly.
- When design is undecided, propose options — don't commit.

## Agent configuration

| File | Purpose |
|------|---------|
| [.claude/ai-helper/issue-tracker/issue-tracker.md](.claude/ai-helper/issue-tracker/issue-tracker.md) | GitHub Issues workflow |
| [.claude/ai-helper/issue-tracker/triage-labels.md](.claude/ai-helper/issue-tracker/triage-labels.md) | Label vocabulary |
| [.claude/ai-helper/issue-tracker/domain.md](.claude/ai-helper/issue-tracker/domain.md) | Domain doc conventions |
| [.claude/ai-helper/issue-tracker/environment.md](.claude/ai-helper/issue-tracker/environment.md) | Local machine quirks, pnpm 11, shell |
