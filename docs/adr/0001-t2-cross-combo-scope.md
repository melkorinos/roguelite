# T2 cross-combo scope: 24 of 39 pairs

The 6 extended T1 elements (Lightning, Nature, Light, Dark, Metal, Fungus) each have self-combos but were added without cross-combos among themselves. When implementing them, we chose to add only cross-combos with the original 4 T1s (Water, Fire, Air, Earth) — 24 pairs — rather than all 39 (which would include the 15 pairs among the 6 extended elements with each other).

Note: this ADR was written when the 6th extended T1 was Sound. Sound was later retired and replaced by Fungus🍄(Poison); all naming and recipe references updated accordingly.

The 15 new-to-new pairs (e.g. Lightning + Fungus, Dark + Metal) were skipped because they lack obvious thematic anchors, would produce 15 more T2 elements with no existing T3 upgrade paths, and would have roughly tripled the new-element count in a single session. The 24 new-to-original combos already triple the T2 cross-combo count.

**Resolution (2026-06-03):** The 15 pairs were subsequently implemented in the full T2 expansion session. Seven received proper names (Murk, Voltspore, Photosynthesis, Ironwood, Beacon, Lucent, Hexcore); eight retain placeholder names (e.g. "Lightning+Nature") pending a naming brainstorm. The original deferral was to scope and naming, not to permanent exclusion.
