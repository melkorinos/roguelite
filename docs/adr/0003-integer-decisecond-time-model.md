# Integer decisecond time model

All designer-facing time values in combat are stored as **integer deciseconds** (tenths of a second): a 2.5 s cooldown is `cooldown_deciseconds: 25`, a haste reduction of 0.3 s is `3`, a cooldown penalty of 0.8 s is `8`. No design value in `ElementData`, `AbilityData`, or `StatusSystem` is a decimal. The combat loop accumulates the engine's float `delta` and converts to elapsed deciseconds at a single chokepoint; the float `delta` is the only time-related float and it is an engine input, not stored state.

## Why

The owner does not want decimals in design values, and a large number of abilities adjust cooldowns by sub-second amounts (−0.2 s, −0.5 s, +0.8 s, stronger haste). Rounding those to whole seconds would collapse the granularity (a one-second cooldown swing is enormous), so the unit was scaled ×10 instead of dropped.

## Consequences

- Effective cooldown is clamped to a **minimum of 10 deciseconds (1.0 s)** after haste, cooldown-reduction abilities, and shock-slow are applied — nothing fires faster than once per second.
- Shock-slow multiplies cooldown by a fractional factor, so the slowed effective cooldown is **rounded to the nearest integer decisecond** at the comparison site.
- Base cooldowns are being nudged up so typical effective firing lands in the 2–5 s band. The game is explicitly unbalanced; convenient integer values are used and tuned later.
- Blind is stored as an integer percent (`+15` per stack, cap `50`) rather than a float fraction, for the same no-decimals reason.
- Existing cooldown floats in `ElementData` and a chunk of the 284 tests were migrated.
