# Grid Growth — Battlegrid expands by Merging up

The player's **Battlegrid** starts at 2×2 (4 **Battle Slots**) and grows **+1 slot** per run when the
player first reaches a level milestone with an element of a given tier — the first **Tier-2 element to
reach Level 2** (5th slot) and the first **Tier-3 element to reach Level 2** (6th slot). A Tier-1 Lv2 was
considered but cut: it is too cheap a milestone for a board slot. Growth is per-run only and resets
between runs. It exists to reward Merging/Forging *up* (vertical investment) rather than buying *wide*,
reinforcing the core "engineer a synergy" fantasy.

## How it works

- **Trigger** is a tunable table in `TuningData` (`GRID_GROWTH_TRIGGERS = [{tier,level}, …]`). After any
  merge/forge resolves, a pure helper scans **owned** elements (inventory + grid); for each un-fired
  trigger in order, if an owned element of that tier is at level ≥ the trigger level, it awards one slot.
  **Path-agnostic** — reaching the level via Merge or via a Forge result both count.
- **State** — `battle_slot_count: int` (player board size this run, default `GRID_BASE_SLOTS`) and
  `grid_growth_fired: Array[int]` (awarded trigger indices). Both reset per run. The `battle_grid` array
  physically grows (append `null`) so the UI and `ShopSystem.transfer` can target the new slot. The slot
  appears **immediately** on the triggering action and is **permanent for the run** even if the qualifying
  item is later sold.
- **Caps** — reachable now is **6 (2×3)** (two triggers → +2). Hard backend max is **8** (4×2); 9 is not
  supported. Board shapes stay 2 rows tall: 4→2×2, 5/6→3×2, 7/8→4×2 (`GridSystem.dimensions`).
- **Pure logic** — the growth helper lives in `systems/` and returns new state; the scene layer only
  re-renders. Consistent with the "systems never touch the SceneTree" rule.

## Per-side combat sizing (the structural consequence)

Combat per-slot arrays (`*_timers`, `*_frozen_seconds`, `*_ability_timers`, `battle_stats` rows) were
sized from a single global `CombatState.SLOT_COUNT`. Grid Growth makes board size **per-side**: each side
sizes its arrays from its own grid length, and `GridSystem.neighbors` gains a `slot_count` guard so ragged
boards (5, 7) never emit out-of-range adjacency. This is the real cost of the feature and is hard to
reverse once combat code assumes per-side counts.

## The trade-offs

- **Trigger source: Merge milestone, not an Event reward.** Grid Growth was first scoped as an ADR-0011
  `expand_grid` Event reward. We chose to tie it to leveling instead, so the board-size lever directly
  *teaches* the Merge/Forge economy (the thing we most want players to engage). The Event framework stays
  available for other rewards.
- **Asymmetric boards are embraced, not normalized.** Because opponents are Ghost snapshots captured at
  their own board size, a grown player can field more slots than an opponent. We accept this as an earned
  edge — async PvP makes normalization dishonest. The synthetic opponent board is **also round-scaled**
  (`OpponentProvider._max_slots_for_round`, breaks `[1,3,5,8]` → 2/3/4/5/6 capped at the hard max) so a
  grown player isn't permanently fighting a 4-slot ghost; per-side combat sizing handles whatever
  asymmetry remains within a round. Break rounds are first-pass, retunable in G4.
- **Per-run, not meta.** A permanent account-level grid unlock would break the roguelite "every run starts
  equal" contract and trivialize early rounds forever, so growth resets each run.

## Deliberate no-s

- No static baseline bump — the board starts 2×2; growth is the *only* size change.
- No 9-slot support — 8 is the hard cap (BE logic must reject above it).
- Milestones are first-pass; G4 may retune (e.g. move to "first Tier-1 → Level 3"). That is a TuningData
  edit, not a code change.

Supersedes the never-built `BalanceSystem`/Compendium-dev-column plan (ADR 0002) as the active balance
direction for board size; live tracker is `.claude/ai-helper/handoff-run-loop.md`.
