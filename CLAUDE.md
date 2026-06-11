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

**Size limit: keep both files under 100 lines.** When either file exceeds 100 lines, invoke `/dream` (or, if unrecognised, read `.agents/skills/dream/SKILL.md` and follow it directly) — do not attempt inline condensation during a work session. (`log-archive.md` holds entries older than 30 days; never load it at session start.)

## Project

An auto-battler game built with **Godot 4 / GDScript**. Design is in early flux — ability-chain combat, synergy-driven builds, async PvP.

## Running the game

F5 in Godot editor. CLI: `godot --path . scenes/screens/Boot.tscn` (scene) · `godot --headless --quit` (smoke-test).

## Architecture

**Hard rule:** Scene scripts (`.gd` attached to `.tscn`) handle rendering and input only. Nothing in `systems/` or `data/` may reference scene nodes or the SceneTree.

| Folder | Purpose |
|--------|---------|
| `scenes/screens/` | Full-screen scene files: Boot, MainMenu, Settings, Shop, Battle, Compendium |
| `scenes/slots/` | Reusable tile/slot nodes: BattleSlot, ForgeSlot, InventorySlot, ShopItemTile, SellZone |
| `scenes/shared/` | Cross-scene UI: TooltipCard, PauseOverlay, StartingPickOverlay |
| `systems/` | Pure logic — static GDScript classes, take state Dictionary, return new Dictionary |
| `data/` | `GameState.gd` factory; element/recipe/ability data (`ElementData`, `RecipeData`, `AbilityData`); `TuningData.gd` (all balance knobs); `ThemeData.gd` (colors); `UIScale.gd` (font sizes); `FeatureFlags.gd` (playtest toggles) |
| `autoloads/` | `GameManager.gd` — global state holder, registered as Autoload |

**GameState** is a plain `Dictionary` created by `GameState.create()` in [data/GameState.gd](data/GameState.gd). All scenes read and write it via `GameManager.state`. Systems must not mutate state in-place — return a new Dictionary.

**Scene chain:** `Boot → MainMenu → [Settings] → Shop → Battle`

**State pattern:** `GameManager.state = SomeSystem.some_fn(GameManager.state, args)` → `_render()`

## Round lifecycle (key functions)

`Shop.gd`/`ShopSystem` → fight → `PhaseSystem.to_battle` (resets timers/statuses, seeds `combat_rng_state`, builds opponent grid from Ghost snapshot, fires combat_start abilities) → `BattleSystem.tick_battle` per frame (status tick → `_tick_side` per side → `resolve_reactive` → `resolve_periodic` → `_drain_commands`; flips `phase="result"` on KO or Sandstorm) → `PhaseSystem.resolve_round` (canonical win/loss/draw) → `PhaseSystem.advance_round` (+1 round, +5g). Deterministic: same board + seed = same result. Win rule + Sandstorm details in memory.md.

## Code standards

**Strict typing — mandatory on `systems/` and `data/`:** All params, return types, and arithmetic locals explicitly typed. `var hp: int = state["player_hp"]` pattern for Dict values (`as` cast). `Variant` for nullable inventory slots. `Array[Dictionary]` for typed collections. Scene function signatures same rule; local render vars may be untyped.

**Theme overrides:** Font-size deviations via `UIScale.apply(node, UIScale.SOME_CONST)` only — never `add_theme_font_size_override()` directly or dict access. Constants in [data/UIScale.gd](data/UIScale.gd). Colors via `ThemeData.gd` only — never hardcode `Color()` in slot/screen scripts.

## Build validation — run before closing any task

```
godot --headless --import   # compile all scripts
godot --headless --quit     # boot check — exit 0 means scripts load and autoloads init
```

Requires `godot` on PATH. On Windows: add the Godot editor directory to system PATH.
CI runs the same two commands on every push (see [.github/workflows/ci.yml](.github/workflows/ci.yml)).

**Run GUT tests** (19 suites across `test/unit/data/`, `test/unit/systems/`, `test/unit/autoloads/`):
```
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/data/ -gdir=res://test/unit/systems/ -gdir=res://test/unit/autoloads/ -gprefix=test_ -gexit
```
Note: `-gsuffix` is not supported by this GUT version — omit it. `-gdir` must use `res://` prefix. **Do not pass a single parent dir** (`res://test/unit/`) — this GUT version does not recurse and will silently run nothing. Pass all three leaf dirs explicitly with separate `-gdir` flags.

## Assistant behavior

- Coding-first. Slight design awareness.
- When a code decision might lock future design flexibility, say so explicitly.
- When design is undecided, propose options — don't commit.
- **Reporting style: ultra-concise. Sacrifice grammar for brevity. Terse fragments over full sentences.**

## Skill output — mandatory rule

**`/improve-architecture` output always goes in `.claude/ai-helper/reviews/`** — never in the OS temp directory. Filename: `architecture-review-YYYYMMDD.html`, with a letter suffix (`-b`, `-c`, …) for additional reviews the same day so existing ones aren't clobbered. Open with `start .claude/ai-helper/reviews/<filename>` after writing.

## Agent skills

### Issue tracker

Issues live in GitHub Issues at `https://github.com/melkorinos/roguelite`. See `.claude/ai-helper/issue-tracker/issue-tracker.md`.

### Triage labels

Default label vocabulary (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix). See `.claude/ai-helper/issue-tracker/triage-labels.md`.

### Domain docs

Single-context repo — one `CONTEXT.md` at root, `docs/adr/` for ADRs. See `.claude/ai-helper/issue-tracker/domain.md`.
