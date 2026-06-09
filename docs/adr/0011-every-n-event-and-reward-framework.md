# Every-N Event node + reward framework

Every `TuningData.EVENT_EVERY_N_ROUNDS` rounds (before the shop) the Run pauses for an
**Event**: a non-combat choice node offering three distinct **Event Rewards**, one of which
the player must take. This is the north-star "meta event every 3" loop piece, scoped as a
pure choice node — **not** a shared-combat PvE Round (that concept stays reserved for later).

## How it works

- **Logic** lives in pure `systems/EventSystem.gd` (mirrors `StartSystem`/`ShopSystem`):
  `is_event_due(state)`, `offer(state, rng)` → three reward dicts, `apply_reward(state, reward)`.
- **Presentation** reuses the Starting Pick pattern: no new `phase`, no new scene. An
  `EventOverlay` (CanvasLayer) is shown blocking in `Shop._ready` when an Event is due. The
  reward lands directly in the shop the player is looking at.
- **Schedule**: due when `round % EVENT_EVERY_N_ROUNDS == 0` (and `round >= 2`). A
  `last_event_round` field marks consumption so re-entering the Shop (e.g. Shop→Compendium→Shop)
  doesn't re-show it — the same role `starting_pick_done` plays for the Starting Pick.
- **Determinism**: the three offers are seeded from `hash("event:%d" % round)`, so Replay and
  async Ghost playback reproduce the exact offer. Mirrors the per-round combat RNG seed.

## Reward model — one-shot vs persistent (the real trade-off)

A reward is a tagged dict `{kind, ...params, label, description}` dispatched by `apply_reward`:

- **One-shot** — `gold` (adds gold once); `grant_element` (an Element straight to the first
  empty inventory slot; capped at `max(unlocked_tiers(run_discoveries))` and drawn from the
  player's Families via `ShopSystem.eligible_for_tier`; inventory full → its gold-equivalent).
- **Persistent Run Modifier** — increments a discrete state field that an existing system
  already reads every round: `bonus_hp` → `hp_bonus` (read in `PhaseSystem._scaled_player_hp`),
  `reroll_discount` → subtracted in `ShopSystem.reroll_cost` (floored at 0).

**We chose discrete fields over a generic "active modifiers" list.** With two modifiers the
list is over-engineering; discrete fields reuse seams that already exist (`hp_bonus` was built
as a reward hook) and keep each consuming system reading one named value. Revisit if the modifier
count grows past a handful.

## Deliberate no-s

- A granted Element does **not** write `run_discoveries` — Forging stays the sole Shop-tier
  unlock, so the Event can't shortcut the forge-as-progression engine.
- No skip/decline — all three offers are positive; the player always takes one.
- `trinket` and a board-wide `damage_bonus` reward are deferred (no Trinket system yet; no
  board-wide damage seam — only per-instance `damage_multiplier`).
