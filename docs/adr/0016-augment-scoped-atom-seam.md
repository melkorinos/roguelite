# Augment seam: one scoped-atom vocabulary for Keystones, Events, and Trinkets

The Starting-Pick rework into run-defining **Keystones**, the existing every-N **Event**
rewards, and future in-combat **Trinkets** all grant the player persistent effects. We
unify them behind one mechanism: an **Augment** is an acquired source carrying a list of
effect **atoms**, each tagged with a `scope` (`run_state` | `shop_gen` | `combat` |
`round_result`). A pure `systems/AugmentSystem.gd` dispatches each scope at its own apply
site — there is deliberately **no single `apply()` path**. Combat-scope atoms reuse the
existing ability atom vocabulary (`AbilitySystem.ATOM_SCHEMAS`); the other three scopes
use AugmentSystem's own atom kinds. `state["augments"]` is the durable per-run source of
truth; run_state atoms are materialized into the discrete cache fields (`hp_bonus`,
`hp_bonus_percent`, `reroll_discount`) that hot readers already use.

## Considered Options

- **Shared atom vocabulary + scoped registry (chosen).** Each Augment carries scoped
  atoms; each existing system applies *its* scope at *its* site. The combat half reuses
  ability atoms + status modifier fields, so a Keystone that buffs burn is the same
  `set_status_field` an element ability already uses.
- **One source type + a single `apply()` path (rejected).** The four scopes apply at
  different sites and lifecycles (combat tick vs `to_battle` HP vs shop generation vs
  post-round). A single `apply()` would just branch by scope internally — a leaky
  abstraction we would unwind the moment Trinkets land.
- **Keep distinct + route only additive effects through the Event Run-Modifier fields
  (rejected).** The motivating Trinket examples fan across all four scopes (percent HP,
  shop weighting, post-round gold, combat tick-rate). The additive-only seam expresses
  roughly one of four and would force a rewrite.

## Status (2026-06-13)

**Keystones (Phase B) landed.** `data/KeystoneData.gd` = 10-card v1 roster; `StartSystem`
offers 4 with Family+Status spread; `StartingPickOverlay` shows 4 heterogeneous cards;
Compendium Keystones tab added. Magnitudes in `TuningData.KEYSTONE_*`. `round_result` scope
wired but no consumer yet — Trinkets are the next source type.

## Consequences

- A new shared combat atom kind, `suppress` (`heal`/`cleanse`), backs pact Keystones; its
  side-wide flags live in `EffectRegistry.SIDE_WIDE_FIELDS` and are read in
  `StatusSystem.apply_effect`. It sits in the shared `ATOM_SCHEMAS` so abilities could use
  it too, though none do yet.
- Shop weighting is a **soft bias within the already-eligible pool** — it never unlocks a
  tier or injects an ineligible element, preserving the discovery gating of ADR 0007/0015.
- The `round_result` scope is wired but has **no v1 consumer** (Keystones don't use it);
  it exists so Trinkets slot in without new plumbing.
- The Event's persistent Run Modifiers migrated to `run_state` Augments; the discrete
  fields remain as the materialized cache so `_scaled_player_hp` / `reroll_cost` are
  unchanged.
- Keystone effects are **flat integers, not percentages** — the combat model is integer
  (ADR 0003), so a multiplier would be the first fraction in the pipeline and would lock
  balance/Replay to a specific rounding + placement. Late-game relevance instead comes
  from `scale_by`: a per-unit coefficient multiplied by an integer board count (Family
  piece count / Levels, board size, round), resolved at combat start. If true percentages
  are ever wanted, that is the point to ADR their rounding and pipeline placement.
