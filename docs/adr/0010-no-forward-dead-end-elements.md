# No forward dead-end elements

## Context

A quarter of the roster — 24 Tier-2 and 11 Tier-3 elements (e.g. Tempered = frost+metal) — were never an ingredient in any higher recipe, so they "forged no further." That made the Forge bench's "Forges with" hint legitimately empty (reads as broken), trapped players on elements that can't progress, and broke the intended fantasy that every element scales up toward a Tier-4 Phenomenon.

## Decision

**Invariant: every element below Tier 4 appears as an ingredient in ≥1 recipe** (Tier 4 is the apex and is exempt). Per-tier this guarantees a transitive forge path to Tier 4 from anything. Achieved by adding 22 recipes (RecipeData grew 169 → 191) that route each former dead-end up through its **thematic cluster** (the Frost/Nature/Storm/Earth/Blood/Fungus/Light-Dark/Metal clusters already structuring the T3/T4 recipe sections) — mostly alternate paths onto existing higher elements, pairing two dead-ends per recipe where thematic. No elements were pruned and no new elements were added (prism, the lone orphan, was routed via the natural `prism + rain → rainbow` rather than cut). The invariant is locked by `test_no_non_apex_forward_dead_ends`.

## Consequences

Cluster-first routing keeps the new recipes thematically earned (no "sea → building"); the audit test prevents regressions as the roster evolves. The 22 recipes widen the shop's family graph (ADR 0007 `ingredients_of`) and shift the forge economy (ADR 0008) — that rebalance is deferred to the G4 balance pass, not this content fix. Strict tier+1 forging (T2=T1+T1, T3=T2+T2, T4=T3+T3) is unchanged.
