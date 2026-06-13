# Handoff — Battle-interaction & invariant test coverage

**Status: STARTED (4 starter tests landed). This handoff = build out the full batch.**
The goal is correctness coverage for how combat mechanics **compose** in a real fight — the
layer ordinary unit tests miss.

## Why this exists (the trigger)

After the Augment/Keystone system landed (ADR 0016), many things now modify damage / fire-rate /
stacks: keystone combat atoms (`set_status_field`, `set_side_field`, `suppress`, `scale_by`),
ability modifier fields, etc. Every unit test is green — but each tests a piece **in isolation**.

A real bug slipped through anyway: a pure-effect **poison element fired ~10× but showed 0 Dmg/DPS**
in the Battle Summary (Summary read direct-hit damage only; poison's damage lived in a separate
contrib ledger). Every unit test passed. (Now FIXED by another agent — `summary_rows` folds DOT
contrib; curse attribution wired — see `.claude/ai-helper/log.md`, 2026-06-13 "Reporting bugs
fixed".) The lesson: **composition/integration bugs are invisible to isolated unit tests.** This
batch closes that.

## The strategy — three layers

1. **Unit** (already strong) — per-status / per-atom math in isolation.
2. **Integration A/B** (started) — same board + **same seed**, run a REAL fight
   (`PhaseSystem.to_battle` → `BattleSystem.tick_battle`) **with vs without** a modifier, assert the
   HP/outcome delta moves the right way. Asserts *behaviour*, not internals, so it survives refactors.
3. **Invariant / property sims** (NOT built — highest leverage) — random boards through the
   deterministic `BattleSystem.simulate_battle`, asserting rules that must hold for *every* fight.

## Already done (reference, don't redo)

- `test/unit/systems/test_combat_integration.gd` — 4 starter tests + the helpers (`_idle_opponent`,
  `_with_player_elements`, `_advance` fixed-step driver). The **pattern to copy** for layer 2:
  Ashen Affinity (flat A/B), Emberswarm (scaling A/B), two-source composition, DOT-Summary regression.
- Suite is **667/667** green; import + boot 0.

## Coverage map (what's covered, where the gaps are)

| Interaction | Covered? | Notes |
|---|---|---|
| Single status math (apply/tick/cleanse/potency) | ✅ unit | thorough (`test_status_system`) |
| Trigger firing (combat_start / periodic / every_n / reactive / multicast) | ✅ unit | `test_ability_system` |
| Status × one mitigation (burn×armor, poison×plating) | 🟡 partial | a few pairs only |
| **Full mitigation stack on ONE hit** (weaken→armor→plating→curse→blind *order*) | ❌ gap | highest-risk untested composition |
| **Each modifier × its mechanic, end-to-end** | 🟡 burn only | the other ~10 fields unproven in a fight |
| **Consumption / charge semantics** | 🟡 partial | curse spends a charge only on a *damaging* event — UNVERIFIED |
| **Timing end-to-end** (haste sooner, shock slower, freeze pauses) | ❌ gap | cooldown *math* unit-tested; fight consequence isn't |
| **Side-targeting / leak isolation** | ❌ gap | buff/debuff must not bleed to the wrong side |
| Multi-source stacking on a field | 🟡 burn only | other fields (cooldown, armor.floor, weaken) untested |
| Determinism/Replay, Sandstorm | ✅ | covered |

## The batch to build (organized by gap)

- **A. Mitigation-order tests** — `StatusSystem.compute_incoming_damage` with weaken + armor +
  plating + curse stacked on one hit; assert exact resulting damage AND the order of application.
- **B. Per-modifier A/B table** — one fight-level A/B per modifier field, each proving the field
  changes the fight: `outgoing_damage_flat`, `cooldown_modifier_deciseconds`,
  `shock.effective_stack_bonus`, `weaken.duration_bonus`, `armor.floor`, `plating.reduces_dot`,
  and `suppress_heal` (fight with a Nature healer → it heals 0).
- **C. Consumption-semantics** — curse + freeze ⇒ charge **unchanged** (freeze is non-damaging);
  curse + direct hit ⇒ −1; curse + DOT tick ⇒ −1; cleanse floors at 0; one-shot primers wait /
  are consumed once. (C is the user's explicit worry — prioritize it.)
- **D. Timing A/B** — hasted side fires MORE in a window; shocked side fires FEWER; a frozen slot
  fires 0 while frozen.
- **E. Side-isolation** — a player buff never appears in `opponent_statuses`; a debuff lands only
  on the target side.
- **F. Invariant sims** (build a small `_sim` harness in the test, or reuse `simulate_battle`):
  random boards → assert for every fight —
  - **HP conservation**: opponent HP lost == Σ credited contribution (direct+poison+burn+curse) and
    blocked == Σ defender mitigation. *(This invariant alone would have caught the bug that started
    this.)*
  - `curse_charges_spent ≤ damaging_events` (never on freeze / non-damaging status).
  - a frozen slot fires 0 times while frozen; cleanse never increases a debuff; a `suppress_heal`
    side never gains HP from heal; sandstorm damage is symmetric; same seed → identical event log.
  - **Caveat:** a wrong invariant = false failures; design each carefully and assert it on the
    EXISTING green roster first (it must already hold).

## Simulation: how it fits (and how it differs from the balance harness)

`tools/balance_harness.gd` answers **"is this element over/under-tuned"** (aggregate win-rate /
replacement value). It does NOT catch correctness bugs — a miswired interaction just yields a
plausible number. For correctness, the same deterministic sim is used two new ways: **differential
A/B at scale** (layer 2, generalized) and **invariant/property checks** (layer 3, F above). Enabler:
combat is deterministic with an inspectable event log (`battle_events`) + per-slot contrib ledger.

## Key files & patterns

- `test/unit/systems/test_combat_integration.gd` — copy this pattern for A/B (B, D, E).
- `systems/BattleSystem.gd` — `tick_battle`, `simulate_battle` (deterministic full fight),
  `summary_rows`, `_fire_element_once` (damage pipeline), `COMBAT_STEP_SECONDS`.
- `systems/StatusSystem.gd` — `apply_effect`, `tick` (DOT + attribution), `compute_incoming_damage`
  (mitigation order), curse consumption, `effective_cooldown_deciseconds`.
- `systems/CombatSide.gd` — side→key map (statuses/grid/hp keys for assertions).
- `systems/PhaseSystem.gd` — `to_battle` / `begin_combat` (applies Augments), `advance_round`
  (round_result, for A/B of `round_result` effects).
- `data/CombatState.gd` — `empty_stat_row` (the contrib shape: direct/poison/burn/heal/curse/blocked).
- Contribution attribution + curse wiring landed 2026-06-13 — see `log.md`.

## How to run

GUT (three leaf dirs — do NOT pass a single parent dir; see CLAUDE.md):
```
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/data/ -gdir=res://test/unit/systems/ -gdir=res://test/unit/autoloads/ -gprefix=test_ -gexit
```
Then `godot --headless --import` and `godot --headless --quit` (exit 0).

## House rules (from CLAUDE.md)

- Systems/data are pure static GDScript; **strict typing** mandatory; determinism matters (seed any
  RNG). New tests live in `test/unit/systems/` or `test/unit/data/`, `test_`-prefixed.
- Reporting style: ultra-concise, terse fragments.

## Suggested skills

- **/tdd** — build the batch red→green, one gap-category at a time (A…F).
- **/diagnose** — if an invariant (F) fails on the existing roster, it's likely a real bug; diagnose
  before "fixing" the test.

## Recommended order

Start with the high-value slice for the reviewing agent to evaluate the approach: **F
(HP-conservation invariant)** + **C (curse/freeze consumption)** + **A (mitigation order)**. Then
go wide on **B/D/E**.
