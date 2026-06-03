# Two-axis Efficiency Score (DPS + Effect Score)

The balance tool scores each Element on two axes — DPS Score (`effective_damage / cooldown`) and Effect Score (hardcoded utility value per effect string) — rather than a single composite number or three separate axes (DPS / offensive utility / defensive utility).

A single number hides whether an outlier is broken on DPS or on its Effect, making it less actionable for a balancer. Three axes were considered (splitting Effect into offensive debuffs vs. defensive self-buffs) but dropped: the split is not yet meaningful because T2/T3 Elements have no effects assigned, and the extra column adds parsing overhead for marginal gain at this stage. The two-axis schema keeps scores readable at a glance while leaving the door open to splitting Effect Score into two columns later once T2/T3 effects are fully designed.

Composition-level scores sum the four slot scores (sum rewards filling all 4 slots; partial boards score lower). No Synergy multiplier until the Synergy system is implemented.
