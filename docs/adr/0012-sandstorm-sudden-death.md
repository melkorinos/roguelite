# Sandstorm sudden-death replaces the timeout loss

A combat no longer ends in a flat loss at `BATTLE_TIME_LIMIT` (30 s). Instead that mark
is the **Sandstorm** start: from then on, escalating damage hits **both** sides each
storm-second until one is eliminated. So every fight resolves by KO under the canonical
"opponent eliminated" win rule, and the arbitrary-feeling timeout loss is gone.

## Why

The old rule (`timer >= BATTLE_TIME_LIMIT` → `result`, opponent alive → loss scaled by
remaining HP) meant a fight the player was *winning on HP* but hadn't closed out became a
loss at 30 s — correct per the win rule, but unsatisfying and a balance dead-zone (tanky
mirror matches just timed out). A sudden-death storm forces a clean elimination and rewards
whoever built more damage/sustain.

## How

- `BattleSystem._tick_sandstorm(s, timer)`: once `timer >= BATTLE_TIME_LIMIT`, storm-second
  `k` (from 0) deals `SANDSTORM_BASE_DAMAGE + SANDSTORM_RAMP_PER_SECOND * k` to both
  `player_hp` and `opponent_hp`. A per-combat `sandstorm_ticks` counter tracks applied
  storm-seconds so the cadence is independent of the combat step size.
- End condition becomes: a side eliminated, **or** `timer >= SANDSTORM_HARD_CAP_SECONDS`
  (60 s) — a pure determinism backstop the storm normally beats by ~10 s. `compute_result`
  is unchanged (opponent eliminated = win; mutual KO = draw = win).
- `simulate_battle`'s step budget now derives from the hard cap, not `BATTLE_TIME_LIMIT`,
  so headless/Replay sims run the storm to completion.

## Deliberate choices

- **True damage — bypasses ALL mitigation** (armor, plating, absorb). The storm is an
  impartial environmental clock; routing it through defenses would let tanky boards outlast
  it and defeat the purpose. Flagged in `TuningData` as a choice that *may* later route
  through mitigation.
- **Symmetric** (identical to both sides), **inert** (emits no Combat Events, triggers no
  reactives — keeps the depth-1 rule untouched), and **deterministic** (time-driven, no RNG
  → Replay-safe).
- **No visual feedback yet** — logic only; a banner / float labels are deferred.
