---
status: partially superseded — family-filter portion removed 2026-06-12 (see ADR 0015)
---

# Forge-gated shop pool (family filter removed)

The shop no longer offers elements by a global `shop_tier` probability. A tier appears in
the shop only after the player has **forged** enough distinct elements of that tier this run
(3 for T2, 2 for T3, 1 for T4); once unlocked it offers the **full pool** for that tier.
T1 is always offered, with at least one guaranteed T1 slot per shop. Slot spread is biased by
ingredient variety (`_pick_spread`) but does not restrict by family. State lives in a per-run
`run_discoveries` array, distinct from the persistent `discovered_recipes` (Compendium).

**Why:** with 132 elements the flat by-tier shop was diluted and made forging pointless —
everything showed up eventually anyway. Forging is the engine of progression: bootstrap each
tier by forging it from below. The family-filter originally narrowed the pool further, but was
removed (ADR 0015, 2026-06-12) once the T2 consolidation reduced the roster to 105 — the pool
is small enough that filtering by family would over-restrict choice.

`shop_tier` is **retired entirely**. Opponent power (which also keyed off it) now scales by
**round number** (`OpponentProvider._max_tier_for_round`), so difficulty is predictable and
independent of how fast the player forges. Tuning values (unlock thresholds, the round→tier
curve, slot weighting, the guaranteed-T1 rule) live in `data/TuningData.gd`.
