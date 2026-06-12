# T2 consolidation: overlapping T1 recipes (78 → 51) and the un-filtered shop pool

The original rule — every T1+T1 combination yields a UNIQUE Tier-2 element — produced 78 T2s,
enough to skew the shop once T2 unlocks and to force the family-filter workaround (ADR 0007).
We dropped uniqueness instead of dropping combinations: all 66 cross-pairs + 12 self-combos still
forge, but multiple pairs may now share a result (e.g. blood+water/air/lightning/nature → Pulse),
with every merged pair required to read thematically true. 27 T2s were deleted (curated: the
mechanically redundant and sim-weak died; standout abilities migrated — Lucent inherited Beacon's
haste). Roster 132 → 105, recipes → 197; out-degree floor ≥2 and the T3 in-degree band 2–4 were
re-established after the surgery.

Consequence: with the pool this small, the family-filtered shop eligibility (ADR 0007) was
removed in the same pass — an unlocked tier now offers its full pool. Tier-unlock thresholds
(forge N distinct) remain. ADR 0007's discovery gating stands; only its family restriction is
superseded.
