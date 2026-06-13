---
status: archived — never implemented; superseded by Monte Carlo balance harness
superseded-by: tools/balance_harness.gd (built 2026-06-12)
archived: 2026-06-13
---

> **Why archived:** The BalanceSystem and Effect/Action Score table described here were
> never built. Only the inert `FeatureFlags.efficiency_scoring` flag remains. Balance is
> done empirically via the Monte Carlo replacement-value harness (`tools/balance_harness.gd`,
> built 2026-06-12) — simulation is ground truth. The two-axis schema is preserved here
> as a reference starting point if an analytical scorer is ever wanted.

# Two-axis Efficiency Score (DPS + Effect Score)

The balance tool scores each Element on two axes — DPS Score (`effective_damage / cooldown`) and Effect Score (hardcoded utility value per effect string) — rather than a single composite number or three separate axes (DPS / offensive utility / defensive utility).

A single number hides whether an outlier is broken on DPS or on its Effect, making it less actionable for a balancer. Three axes were considered (splitting Effect into offensive debuffs vs. defensive self-buffs) but dropped: the split is not yet meaningful because T2/T3 Elements have no effects assigned, and the extra column adds parsing overhead for marginal gain at this stage. The two-axis schema keeps scores readable at a glance while leaving the door open to splitting Effect Score into two columns later once T2/T3 effects are fully designed.

Composition-level scores sum the four slot scores (sum rewards filling all 4 slots; partial boards score lower). No Synergy multiplier until the Synergy system is implemented.
