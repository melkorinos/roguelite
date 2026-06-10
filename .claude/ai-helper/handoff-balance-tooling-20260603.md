# Handoff — Game Balance Tooling
**Date:** 2026-06-03  
**Next session focus:** Implement `BalanceSystem.gd` + Compendium dev column + Balance Sandbox

---

## What was decided this session

All design decisions are locked. Full rationale lives in:
- `memory.md` → section **"Balance tooling (settled 2026-06-03)"**
- `docs/adr/0002-two-axis-efficiency-scoring.md`
- `CONTEXT.md` → section **"Developer tooling"** (new terms: Efficiency Score, DPS Score, Effect Score, Balance Sandbox)

**Do not re-litigate these decisions. They are settled.**

### Decision summary (tl;dr)

| Question | Decision |
|---|---|
| Score axes | Two: **DPS Score** + **Effect Score** |
| DPS formula | `effective_damage(elem, level) / cooldown` (uses existing `ElementData.effective_damage`) |
| Effect score source | Hardcoded lookup table in `BalanceSystem` — all values marked `# estimated` |
| Levels scored | Level 1 and Level 2 only |
| T2/T3 effects | Score 0 for now (no effect field assigned yet) |
| Forge cost weighting | None |
| Composition score | Sum of 4 slot scores (nulls = 0) |
| Synergy multiplier | Deferred |
| Output surface | Compendium dev column (gated by `FeatureFlags.efficiency_scoring`) |
| Sandbox depth | Score display only — no battle simulation |
| Score bands / flagging | Deferred (derive from data distribution once tool exists) |
| Full board sweep simulation | Deferred |

---

## What to build

Three deliverables, in dependency order:

### 1. `systems/BalanceSystem.gd`

Pure static class. No SceneTree references. No side effects.

```gdscript
class_name BalanceSystem

# Hardcoded effect utility values. All marked # estimated.
# Replace with simulation-derived values in a future session.
static func _effect_value(effect: String) -> float:
    match effect:
        "poison":  return 4.5  # estimated
        "shock":   return 4.0  # estimated
        "burn":    return 3.5  # estimated
        "curse":   return 3.5  # estimated
        "blind":   return 3.0  # estimated
        "weaken":  return 2.5  # estimated
        "plating": return 3.5  # estimated
        "haste":   return 3.0  # estimated
        "armor":   return 2.5  # estimated
        "cleanse": return 2.5  # estimated
        "leech":   return 2.0  # estimated
        "heal":    return 2.0  # estimated
    return 0.0  # T2/T3 elements with no effect assigned yet


# Returns {dps: float, effect_score: float} for one element at a given level.
static func score_element(elem: Dictionary, level: int) -> Dictionary:
    ...


# Returns {dps: float, effect_score: float} — sum across all 4 slots at a given level.
# Null slots contribute 0. Gated by caller (check FeatureFlags.efficiency_scoring before calling).
static func score_board(grid: Array, level: int) -> Dictionary:
    ...
```

**Notes:**
- `score_element` must call `ElementData.effective_damage(item)`. To score at a specific level,
  pass a duplicate of `elem` with `"level"` overridden: `var tmp = elem.duplicate(); tmp["level"] = level`.
- `score_board` iterates `grid[0..3]`, skips nulls, sums `score_element` results.
- No output/print inside `BalanceSystem` — the scene layer calls it and decides what to display.

**Tests to write** (`test/unit/systems/test_balance_system.gd`):
- `score_element` returns correct DPS for a known element at Lv1 and Lv2
- `score_element` returns correct effect_score for a T1 element with a known effect
- `score_element` returns effect_score = 0 for a T2 element without an effect field
- `score_board` sums correctly across a 4-slot grid
- `score_board` handles null slots (partial board)
- `score_board` returns `{dps: 0.0, effect_score: 0.0}` for an empty grid

---

### 2. Compendium dev column

**File:** `scenes/screens/Compendium.gd`

**Gate:** entire feature behind `if FeatureFlags.efficiency_scoring` at the top of `_make_card()`.

**What to add to each card:**

Inside `_make_card(elem)`, after the existing recipe rows, when the flag is true:

```
─────────── (HSeparator) ───────────
DEV SCORES
Lv1  DPS: X.XX  FX: X.X
Lv2  DPS: X.XX  FX: X.X
```

- Label style: small, muted color (e.g. `Color(0.5, 0.5, 0.7)`) to visually separate from player-facing content.
- Use `UIScale.COMP_STATS` size (already used in the file).
- Call `BalanceSystem.score_element(elem, 1)` and `BalanceSystem.score_element(elem, 2)`.
- "FX" = Effect Score shorthand for the compact column. Full term "Effect Score" used in sandbox.

**Important:** the existing naive DPS on each card (`dps = elem["damage"] / elem["cooldown"]` at line 80)
uses the raw damage, not `effective_damage`. Do NOT change the existing DPS label — it's player-facing
and represents raw damage. The new dev rows show the correct scored DPS and are visually distinct.

**Card width:** may need to increase `CARD_WIDTH` from `160.0` to `190.0` to fit the two dev rows.
Only increase if text clips — test in editor first.

---

### 3. Balance Sandbox

A new section appended below the existing tier grid, visible only when `FeatureFlags.efficiency_scoring` is true.

**Layout (inside `_build_content()`, after the existing element loop):**

```
═══ BALANCE SANDBOX ══════════════════════════════
[ Slot 1 ] [ Slot 2 ] [ Slot 3 ] [ Slot 4 ]
           Board Score — DPS: X.XX  FX: X.X
```

**Behaviour:**
- Each slot is a `Panel` or `Button` (160px wide, same card height as Compendium cards) that accepts a drop.
- Dragging from a Compendium card populates the slot with that element (use `elem` dict stored as metadata on the card node).
- On drop: call `BalanceSystem.score_element(elem, 1)` (always Level 1 in sandbox for now), update the slot label.
- Board Score label below the 4 slots: calls `BalanceSystem.score_board(sandbox_grid, 1)` where `sandbox_grid` is the local Array[4] of the current sandbox contents.
- Clearing a slot: right-click or a small ✕ button on the filled slot.
- Sandbox state is ephemeral (not persisted to GameState).

**Drag-drop approach:**
- On each Compendium card `PanelContainer`, store the elem dict: `card.set_meta("elem", elem)`.
- Override `_get_drag_data()` on each card to return the elem dict.
- Override `_can_drop_data()` on sandbox slots to accept Dictionaries with an `"id"` key.
- Override `_drop_data()` on sandbox slots to set the slot content and refresh scores.

**UIScale constant needed:** add `SANDBOX_HEADER` to `data/UIScale.gd` if the sandbox section header needs a distinct size. Otherwise reuse `COMP_HEADER`.

---

## Files to touch

| File | Change |
|---|---|
| `systems/BalanceSystem.gd` | **CREATE** |
| `test/unit/systems/test_balance_system.gd` | **CREATE** |
| `scenes/screens/Compendium.gd` | Add dev column + sandbox section |
| `data/UIScale.gd` | Add `SANDBOX_HEADER` if needed |
| `data/FeatureFlags.gd` | `efficiency_scoring` already exists — just flip to `true` to test |

**Do not touch:** `ElementData.gd`, `RecipeData.gd`, `BattleSystem.gd`, `GameState.gd`, `memory.md` (already updated).

---

## Files to read first

| File | Why |
|---|---|
| `memory.md` → "Balance tooling" section | Full decision record + effect value table |
| `docs/adr/0002-two-axis-efficiency-scoring.md` | Rationale for 2-axis over 3-axis |
| `data/ElementData.gd` | `effective_damage()` signature + element dict shape |
| `data/FeatureFlags.gd` | Confirm `efficiency_scoring` flag name |
| `scenes/screens/Compendium.gd` | Current card structure to understand where to inject |

---

## What is explicitly deferred (do not implement)

- Score bands / outlier flagging thresholds
- Full board sweep simulation (`sweep_tier()`)
- Synergy multiplier in `score_board`
- Simulation-derived effect values (replace hardcoded table later)
- T2/T3 effect assignments (separate design session)
- Lite simulation ("Run vs. Ghost" button) in sandbox
- Level 3+ scoring

---

## Suggested skills for next session

- **`/tdd`** — use to drive `BalanceSystem.gd` implementation with tests first. The function contracts above are precise enough to write tests before writing the implementation.
- **`/verify`** — after implementing the Compendium dev column, use to visually confirm the scores render correctly in-editor and the sandbox drag-drop works.
- **`/prototype`** — if the sandbox drag-drop UX needs iteration, use to explore layout options quickly.

---

## Known gotcha

`Compendium.gd` line 80 already computes a naive `dps = elem["damage"] / elem["cooldown"]` for the existing
player-facing DPS label. This is intentionally kept as-is. The new dev rows call `BalanceSystem.score_element`
which uses `ElementData.effective_damage` (the correct formula: `damage × level + tier`). The two numbers
will differ — that's expected and correct.
