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

An auto-battler game built with **Godot 4 / GDScript**. Design is in early flux — ability-chain combat, synergy-driven builds, async PvP.

## Running the game

Open the project in the Godot 4 editor and press **F5**. There is no CLI build step.

```
# From command line (if godot is on PATH):
godot --path . scenes/Boot.tscn    # run a specific scene
godot --headless --quit            # headless smoke-test
```

## Architecture

**Hard rule:** Scene scripts (`.gd` attached to `.tscn`) handle rendering and input only. Nothing in `systems/` or `data/` may reference scene nodes or the SceneTree.

| Folder | Purpose |
|--------|---------|
| `scenes/` | Godot scene files + attached scripts — rendering and input only |
| `systems/` | Pure logic — static GDScript classes, take state Dictionary, return new Dictionary |
| `data/` | `GameState.gd` factory, item/piece data definitions |
| `autoloads/` | `GameManager.gd` — global state holder, registered as Autoload |

**GameState** is a plain `Dictionary` created by `GameState.create()` in [data/GameState.gd](data/GameState.gd). All scenes read and write it via `GameManager.state`. Systems must not mutate state in-place — return a new Dictionary.

**Scene chain:** `Boot → MainMenu → [Settings] → Game`

**State pattern:** `GameManager.state = SomeSystem.some_fn(GameManager.state, args)` → `_render()`

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
| [.claude/ai-helper/issue-tracker/environment.md](.claude/ai-helper/issue-tracker/environment.md) | Local machine quirks, shell |
