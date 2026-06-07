# Forge-gated, family-filtered shop pool

The shop no longer offers elements by a global `shop_tier` probability. A tier appears in
the shop only after the player has **forged** enough distinct elements of that tier this run
(3 for T2, 2 for T3, 1 for T4); once unlocked it shows only elements from the **families** the
player forged with — elements sharing an ingredient (one tier down) with their discovered
elements of that tier. T1 is always offered (exploration + forge fuel), with at least one
guaranteed T1 slot per shop. State lives in a new per-run `run_discoveries` array, distinct
from the persistent `discovered_recipes` (Compendium / achievements).

**Why:** with 132 elements the flat by-tier shop was diluted and made forging pointless —
everything showed up eventually anyway. Forging is now the engine of progression: you
bootstrap each tier by forging it from below, and the shop then echoes the archetypes you are
committing to.

`shop_tier` is **retired entirely**. Opponent power (which also keyed off it) now scales by
**round number** (`OpponentProvider._max_tier_for_round`), so difficulty is predictable and
independent of how fast the player forges.

**Considered & rejected:** keeping `shop_tier` and layering a filter on top (two coupled
progression signals); a probabilistic per-discovery "appearance budget" (needs charge UI — the
gate + family filter solve the dilution more simply). Tuning values (unlock thresholds, the
round→tier curve, slot weighting, the guaranteed-T1 rule) will move to a consolidated tuning
file later — see `handoff-run-loop.md`.
