# Element Card: three independent visual axes (hue / tier / level)

The Element Card redesign decouples the three things a card communicates onto three
non-overlapping visual channels, reversing the previous "tier = colour" rule.

- **Hue = Canonical Family.** Each element draws its colour from a single dominant
  **Family** (Fire = red, Fungus = purple, …), authored per element by *result vibe*
  among its multi-valued family memberships (Steam → Water, Obsidian → Earth). This
  adds a `family`/canonical-family source for ~105 elements and a 12-entry
  family → `Color` map in `ThemeData`. Rejected alternatives: per-element bespoke
  hues (105 colours, drifts incoherent) and auto-blending recipe parents (desaturates
  to mud, and multi-recipe elements like Surge resolve to two different colours).

- **Tier = frame material.** Tier reads only from the frame — bronze (T1) → silver
  (T2) → gold (T3) → prismatic/rainbow (T4) — not from background or border colour.
  This frees colour for Family and retires the old `TIER_*_BG/BORDER` fill semantics.

- **Level = animated glow/ember ramp.** Merge level (1–3) is shown by an escalating
  portrait glow + embers with a distinct L3 flourish — never a numeric label and
  never the frame (which Tier owns).

Why it's recorded: it inverts an established convention (the prior handoff and
`ThemeData` made tier the only colour and explicitly forbade per-element accent), it
introduces a new per-element data axis (Canonical Family) that is costly to re-tag
later, and each axis was a deliberate pick over real alternatives.
