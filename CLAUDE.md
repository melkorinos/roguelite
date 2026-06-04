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

## Round lifecycle (shop → battle → result)

One **Round** = a Shop phase then a Combat phase. End-to-end flow, with the function that owns each step
(read this to understand how a round resolves):

1. **Shop phase** — `scenes/screens/Shop.gd` + `systems/ShopSystem.gd`. The player spends gold to buy
   elements, drags them onto the **Battlegrid** (`battle_grid`, currently 4 slots), **Merges** duplicates,
   and **Forges** recipes (`systems/ForgeSystem.gd`). Every item move goes through `ShopSystem.transfer`.
   All state lives in `GameManager.state` (a plain Dictionary from `GameState.create()`).
2. **Fight clicked** → `PhaseSystem.to_battle(state, opponent_snapshot)`. Resets per-combat state:
   `player_hp`=30, timers / `*_frozen_seconds` / `*_ability_timers` zeroed, fresh
   `StatusSystem.empty_statuses()` per side, seeds `combat_rng_state` (per round → reproducible), clears
   `pending_commands` and `battle_events`, builds the opponent grid from a **Ghost** snapshot
   (`OpponentProvider` / `GhostFixtures`), then runs `AbilitySystem.resolve_combat_start` (combat_start +
   passive abilities for both sides). Sets `phase = "battle"`.
3. **Combat ticks** — `Battle.gd._process(delta)` calls `BattleSystem.tick_battle(state, delta)` every
   frame until `phase == "result"`. Each tick, in order:
   - **Status tick** (per accumulated 1 s): `StatusSystem.tick` applies burn/poison damage per side and
     returns tick events (`on_burn_tick` / `on_poison_tick`).
   - **Element fires** (`_tick_side` per side): each element accrues `delta`; when it reaches its
     `effective_cooldown_deciseconds` (base + `cooldown_modifier_deciseconds` + shock-slow, floored at 10),
     it fires. Frozen slots are skipped. A fire rolls blind (seeded RNG), deals damage via
     `compute_incoming_damage`, applies its T1 effect, may **Multicast** (repeat the fire block), and rolls
     on-hit passives. Each fire / armour-strip pushes a **Combat Event** (see `AbilitySystem` event model).
   - **Reactive abilities** — `AbilitySystem.resolve_reactive` runs depth-1 reactions to this tick's events.
   - **Periodic abilities** — `resolve_periodic` advances per-ability timers and fires due ones.
   - **Timed commands** — `_drain_commands` fires any due Innate-Ability command (the Replay seam).
   - `battle_timer` advances; `phase` flips to `"result"` when either side's HP hits 0 or the 30 s limit
     (`BATTLE_TIME_LIMIT`) is reached.
4. **Result** — `BattleSystem.compute_result` / `PhaseSystem.describe_result` classify win/loss/draw and the
   Life delta; `Battle.gd` shows the outcome + Battle Summary.
5. **Next round** — `PhaseSystem.advance_round`: +1 round, +5 gold, reset `player_hp`, tally wins / Life,
   set `phase` back to `"shop"` (or `"victory"` / `"eliminated"`). Loop to step 1.

Combat is **deterministic**: same board + same `combat_rng_state` seed → identical result. That is the basis
for Replay. Combat-only systems live in `systems/` (`BattleSystem`, `StatusSystem`, `AbilitySystem`,
`GridSystem`, `CombatSide`) and never touch the SceneTree.

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
