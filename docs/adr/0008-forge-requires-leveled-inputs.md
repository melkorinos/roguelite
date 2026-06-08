# Forge requires leveled-up inputs

## Context

Tier progression is gated by forging (ADR 0007: forge N distinct of a tier to unlock it in the shop). Forge previously accepted any inputs and produced a result at `min(input levels)`, so a player could reach the unlock by buying cheap Level-1 elements and forging them immediately — the Merge axis (Level) and the Forge axis (Tier) were decoupled, and the tier climb was trivial.

## Decision

A Forge now requires **both inputs at Level ≥ `TuningData.FORGE_MIN_INPUT_LEVEL` (2)**, and the result lands **`FORGE_RESULT_LEVEL_PENALTY` (1) levels below its inputs, floored at 1** — two Level-2s yield a Level-1 of the next tier, two Level-3s yield a Level-2. You must **Merge before you Forge**, coupling the two axes and making each tier step a deliberate investment. Merge is unchanged (it is how the leveled ingredients are produced). Under-levelled forges return a `level_too_low` outcome and leave the items staged (the bench keeps them so they can be pulled out and merged). Forge is gold-free today (`FORGE_GOLD_COST = 0`), with the knob reserved for later tuning.

## Consequences

With a non-zero result-level penalty the Merge tax **recurs per tier** (a forged T2 comes out Level 1, so it must be merged to Level 2 before forging into T3), making the climb steep — a deliberate first-pass pacing choice. All three values are `TuningData` knobs, so balance can dial the penalty to 0 (Merge tax paid once at the base) or raise the minimum without code changes. Self-combos (water+water→sea) are no exception — they cost four Level-1 elements (merge 2+2, then forge).
