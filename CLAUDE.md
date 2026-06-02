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

**Scene chain:** `Boot → MainMenu → [Settings] → Shop → Battle`

**State pattern:** `GameManager.state = SomeSystem.some_fn(GameManager.state, args)` → `_render()`

## Code standards

**Strict typing — mandatory on `systems/` and `data/`:**
- All function parameters and return types must be explicitly declared
- All local variables that perform arithmetic must be explicitly typed
- Use `as` casts when reading numeric/bool values from a `Dictionary`: `var hp: int = state["player_hp"]`
- For nullable slots (inventory items), use `Variant` as the local type
- `Array[Dictionary]` for typed collections; plain `Array` when the collection is mixed or nullable
- Scene scripts (`scenes/`) follow the same rule for function signatures; local render variables may be untyped

**Theme overrides — don't use per-node overrides for font size:**
- Set the global default in Project Settings → GUI → Theme → Default Font Size
- Use `add_theme_font_size_override()` only when a specific node must deviate from the global default
- Never set theme properties via dictionary access (`node.theme_override_font_sizes["font_size"]`) in GDScript — use the method form

## Build validation — run before closing any task

```
godot --headless --import   # compile all scripts
godot --headless --quit     # boot check — exit 0 means scripts load and autoloads init
```

Requires `godot` on PATH. On Windows: add the Godot editor directory to system PATH.
CI runs the same two commands on every push (see [.github/workflows/ci.yml](.github/workflows/ci.yml)).

**Run GUT tests** (35 tests across 3 suites as of 2026-06-02):
```
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/ -gprefix=test_ -gexit
```
Note: `-gsuffix` is not supported by this GUT version — omit it. `-gdir` must use `res://` prefix.

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
