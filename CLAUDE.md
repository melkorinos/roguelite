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

**Hard limit: both files must stay under 120 lines.** When adding to either file would exceed 120 lines, first condense or drop the oldest / least useful entries to make room. Log: collapse old entries into one-line bullets and drop routine housekeeping. Memory: merge duplicate sections and cut anything already obvious from the code.

## Project

An auto-battler game built with **Godot 4 / GDScript**. Design is in early flux — ability-chain combat, synergy-driven builds, async PvP.

## Running the game

Open the project in the Godot 4 editor and press **F5**. There is no CLI build step.

```
# From command line (if godot is on PATH):
godot --path . scenes/screens/Boot.tscn    # run a specific scene
godot --headless --quit            # headless smoke-test
```

## Architecture

**Hard rule:** Scene scripts (`.gd` attached to `.tscn`) handle rendering and input only. Nothing in `systems/` or `data/` may reference scene nodes or the SceneTree.

| Folder | Purpose |
|--------|---------|
| `scenes/screens/` | Full-screen scene files: Boot, MainMenu, Settings, Shop, Battle, Compendium |
| `scenes/slots/` | Reusable tile/slot nodes: BattleSlot, ForgeSlot, InventorySlot, ShopItemTile, SellZone |
| `scenes/shared/` | Cross-scene UI: TooltipCard |
| `systems/` | Pure logic — static GDScript classes, take state Dictionary, return new Dictionary |
| `data/` | `GameState.gd` factory, item/piece data definitions, `UIScale.gd` font-size constants, `FeatureFlags.gd` playtest toggles |
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

**Theme overrides — font size deviations must go through `UIScale`:**
- The global default font size lives in Project Settings → GUI → Theme → Default Font Size
- Any node that deviates from the global default must use `UIScale.apply(node, UIScale.SOME_CONST)` — never call `add_theme_font_size_override()` directly in scene scripts
- Named constants live in [data/UIScale.gd](data/UIScale.gd); add a new constant there for each new UI role rather than using a bare integer
- Never set theme properties via dictionary access (`node.theme_override_font_sizes["font_size"]`) in GDScript — use the method form

## Build validation — run before closing any task

```
godot --headless --import   # compile all scripts
godot --headless --quit     # boot check — exit 0 means scripts load and autoloads init
```

Requires `godot` on PATH. On Windows: add the Godot editor directory to system PATH.
CI runs the same two commands on every push (see [.github/workflows/ci.yml](.github/workflows/ci.yml)).

**Run GUT tests** (10 suites across `test/unit/data/`, `test/unit/systems/`, `test/unit/autoloads/`):
```
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/data/ -gdir=res://test/unit/systems/ -gdir=res://test/unit/autoloads/ -gprefix=test_ -gexit
```
Note: `-gsuffix` is not supported by this GUT version — omit it. `-gdir` must use `res://` prefix. **Do not pass a single parent dir** (`res://test/unit/`) — this GUT version does not recurse and will silently run nothing. Pass all three leaf dirs explicitly with separate `-gdir` flags.

## Assistant behavior

- Coding-first. Slight design awareness.
- When a code decision might lock future design flexibility, say so explicitly.
- When design is undecided, propose options — don't commit.

## Skill output — mandatory rule

**`/improve-architecture` output always goes in `.claude/ai-helper/reviews/`** — never in the OS temp directory. Filename: `architecture-review-YYYYMMDD.html`. Open with `start .claude/ai-helper/reviews/<filename>` after writing.

## Agent skills

### Issue tracker

Issues live in GitHub Issues at `https://github.com/melkorinos/roguelite`. See `.claude/ai-helper/issue-tracker/issue-tracker.md`.

### Triage labels

Default label vocabulary (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix). See `.claude/ai-helper/issue-tracker/triage-labels.md`.

### Domain docs

Single-context repo — one `CONTEXT.md` at root, `docs/adr/` for ADRs. See `.claude/ai-helper/issue-tracker/domain.md`.
