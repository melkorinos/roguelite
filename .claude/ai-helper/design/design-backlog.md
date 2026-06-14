# Design / art backlog

The single list of **deferred design + art work**. The big UI systems have landed (Element
Card · `ScenePanel` hardware frames on every screen · `UIStyle` chrome · `CardPreview` +
`GlossaryPopup` · forge two-column redesign · Battle summary pop-up). What remains is below.
When you pick one up, run `/design` (HTML explorations live in this folder, one working file
per thread) and fold the result into the relevant spec.

## Element card / info
- **On-card live stats** — show effective cooldown / damage (after shock, weaken, haste…)
  **live on the card** during battle, so the player never needs to hover for current numbers.
  This is the reason the hover stats tooltip was retired (see spec-element-card "as-built").
- **On-card recipe display** — show "made from / forges into" **on the card itself** (chiefly
  the Compendium card), instead of (or alongside) the forge's forge-paths panel.
- **Element info surface** — a dedicated place where players can read **what each element
  does** (its ability, statuses applied, lineage) in plain terms. The Compendium currently
  shows the cards; this is a clearer, fuller "codex / element detail" view. NEW (2026-06-14).

## Forge
- **Richer single-element forge view** — when one element sits in the bench, show its
  forge-path partners + results as **full ElementCards** (mini), not the current text chip
  list. (Two-element → resulting ElementCard already landed.)

## Frame / panel polish
- **Frame flourishes** — rivets, corner ornaments, title plates. v1 frames are bevel + step only.
- **Global accent desaturation pass** — the `AREA_*` accent set (now incl. the menu accents)
  reads a touch "neon" as a group. Centralised in `ThemeData`, so it is a one-file tone-down.

## Animation
- **Panel / pop-up entrance**, **FIGHT pulse**.
- **Card animations** — embers, L3 halo/sweep, prismatic frame motion, per-fire firing FX.
  (v1 level separation is glow-intensity only — contrast headroom was left for this.)

## Art assets
- **Card art** — hand-built SVG portraits replacing emoji (`assets/elements/{id}.svg`, emoji
  fallback). Portrait box is a fixed slot → non-breaking swap.
