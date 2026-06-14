---
name: design
description: Produce in-browser visual design explorations (HTML mockups) for this game's UI — element cards, screens, components. Enforces the project's design conventions so every session doesn't re-derive them: output location, naming, self-contained tech, real-data grounding, ThemeData colors, and the soul.md aesthetic.
argument-hint: "What component or screen are we designing?"
---

<what-to-do>

Produce HTML mockups the user opens in a browser to react to. This is a brainstorming/iteration loop, not a spec generator — show concrete options, grill on ambiguity, converge.

1. **Read the aesthetic first.** Read `.claude/ai-helper/soul.md` (Aesthetic section) and any relevant `docs/adr/` + `CONTEXT.md` glossary entries for the component. The north star is **clean, minimal, weird, surreal — uncanny item energy, polished. Not cute, not grimdark.** Name it explicitly if a chosen direction drifts from this.

2. **Ground in real data before writing a pixel.** Never invent stats, colors, names, or relationships. Pull from the actual source:
   - Colors → `data/ThemeData.gd` (label every color with its const + hex).
   - Element stats / cooldowns / damage / archetypes → `data/ElementData.gd`, `ElementData.effective_damage`, `DAMAGE_DEALERS`.
   - Abilities / triggers / applied statuses → `data/AbilityData.gd` (`get_ability`, `trigger_label`, `effects[]`).
   - Recipes / lineage / "made from" → `data/RecipeData.gd` (`recipes_for`, `describe_pair`).
   - Which stat pods a card shows → `ElementData.stat_pods(item)` (the tested §B pod rule — don't reinvent it).
   - Element hue → `ThemeData.blended_family_color(ElementData.root_family_weights(id))` (weighted blend of the T1 roots; the old per-element `canonical_family` tag is superseded).
   - Battle-board shape / growth → `GridSystem.dimensions(slot_count)` + ADR-0014 (4 base → 8 max, always 2 rows, 2–4 cols; orthogonal adjacency).
   - Fonts/sizes → `data/UIScale.gd`.
   - Card sizes / screen split / spacing → `data/LayoutData.gd` (per-context card widths `CARD_*`, `CARD_HEIGHT_RATIO`, column split, and the spacing rhythm `COLUMN_GAP`/`PANEL_GAP`/`GRID_CELL_GAP`/`PANEL_INNER_*`). The spatial sibling of ThemeData(color)/UIScale(font)/TuningData(balance).
   Use higher-tier *real* elements (e.g. the fire chain Fire→Lava→Volcano→Supernova) so the user reads the system in context, not toy data.

3. **Output location & naming.** Write to `.claude/ai-helper/design/` only — never the OS temp dir. Name `<component>-<purpose>-YYYYMMDD.html`. **One working file per thread** — overwrite it each iteration and delete superseded copies; do not spawn a new dated file every round (the user will ask "why are there N htmls"). For a structural change, full-rewrite the file; for a small tweak (one color/number/copy), use a surgical Edit.

4. **Self-contained tech.** A single `.html` that opens standalone with no local dependencies (the original `Element Card Exploration.html` broke because it `src`'d a local `design-canvas.jsx`). Inline CSS or Tailwind CDN; Google Fonts via `<link>`. A small inline JS generator (build cards from a data array) is fine and keeps the file DRY — but see validation.

5. **MANDATORY validation before opening.** A JS error blanks the whole page silently. Before every `start`:
   ```bash
   sed -n '/<script>/,/<\/script>/p' FILE.html | sed '1d;$d' > /tmp/check.js && node --check /tmp/check.js
   grep -oE "^const [A-Za-z_]+" FILE.html | sort | uniq -d   # must be empty
   ```
   (The classic blank-page bug was a duplicate `const` — art fn and data object sharing a name. Prefix art fns `ART_*`.) Only open after both pass. **Windows:** `start "" FILE.html` can fail on a relative path — use `Invoke-Item "<absolute-path>.html"` from PowerShell.

6. **Iterate like a designer.** Lead with 3+ distinct proposals when a direction is open; once one is chosen, deepen it (tiers, states, levels, context sizes). **On refinement rounds, drop to 1–3 variants that differ only in the open parameter** (split ratio, sizing, accent) — don't re-explore settled structure. Batch grilling questions (5+ at a time) with a recommendation each. Keep cards true to their real footprint. **Canvas:** the game's native viewport is **1920×1080** (`project.godot` — `canvas_items` / `expand`); design full-screen layouts to that. **1080p is the budget — design to it, not below it.** (`canvas_items`/`expand` scales the whole UI to the window, so a smaller window shrinks everything uniformly; there is no separate sub-1080 layout to budget for.)

7. **Hand off via docs, not the HTML — "show in HTML, specify in Markdown".** The split is deliberate:
   - **HTML** = the *visual* you judge by eye — mockups, rendered components, frame/colour samples. Authoritative for *look*. One working file per thread (point 3).
   - **Markdown** (`spec-<thing>-YYYYMMDD.md` in `.claude/ai-helper/design/`) = the *build contract* — tokens, node/API, file-change lists, rollout checklists. Authoritative for *implementation*; links the HTML for visuals.
   A component may have both (e.g. `element-card-SPEC.html` + a build spec). Also record crystallised decisions where they live: `CONTEXT.md` (glossary), `docs/adr/` (hard-to-reverse visual-architecture calls). A purely-visual component's HTML may double as its spec (embed a build-notes table); cross-cutting systems (tokens/APIs across scenes) belong in Markdown.

</what-to-do>

<supporting-info>

## Established card visual language (as of ADR-0017)
The Element Card communicates on **three independent axes** — keep them non-overlapping in any new component:
- **Hue = Canonical Family** — the weighted blend of the element's Tier-1 root families (`root_family_weights` → `blended_family_color`); 12-color base map. Fire red, fungus purple…
- **Tier = frame material** (bronze → silver → gold → prismatic). Never background fill.
- **Level = glow/ember ramp** (1–3), never a number, never the frame.
- **Text hierarchy: Name (largest) › trigger/condition (only slightly above body) › body.** The trigger prefix keeps its bold/blue style but must NOT read as the heaviest thing on the card.
Forge **Lineage** = the two parents' family hues (underbar marker). Animations and SVG art are deferred features ("card animations", "card art") — default to **static + emoji** unless the task is one of those features.

## Scene panel frame language (the "hardware" frames)
Area panels (shop, inventory, battle board, forge — and every other scene) share one frame: `scenes/shared/ScenePanel.gd` — a thick **raised bevel** (one consistent top-left light source on every panel) + a **stepped-matte** inner accent line, on a near-black interior. Rules:
- Accent lives on the **frame only**; interiors stay near-black (`ThemeData.PANEL_INTERIOR`) so the glow cards are the only saturated thing on screen.
- One accent per area (frame colour): `AREA_SHOP` amber · `AREA_INVENTORY` blue · `AREA_BATTLE` red · `AREA_FORGE` purple. **Shop is amber, not gold** — gold stays the T3/T4 *card* signal.
- **FIGHT (and only FIGHT) uses `FIGHT_*` gold** — the single gold UI object, so the eye always finds the CTA.
- Tokens live in `ThemeData.FRAME_*` (geometry+color) + `LayoutData.PANEL_INNER_*`/gaps (spacing); build + per-scene rollout in `spec-shop-frame-system` and `handoff-apply-theme-all-screens`. `ScenePanel` adopts pre-existing `.tscn` children into its body via `reparent()` (preserves `owner`, so `%Name` survives) — reference wrapped nodes via unique names.
- **Standard palette / one rhythm:** the `AREA_*` accents + the LayoutData spacing ARE the cross-screen standard — a new screen reuses an existing `AREA_*` and the shared gaps, it does NOT author a new `Color()` or magic spacing. (Note: the accent set currently reads over-saturated/"neon" as a group; a global desaturation pass is queued in ThemeData — tone there, not per screen.)

## Full-screen layout mockups
For *scene layouts* (not single components), render at the **true 1920×1080** inside a scaled wrapper so proportions are honest — don't eyeball-fake the scale:
- `.frame` = fixed display box; `.stage { width:1920px; height:1080px; transform:scale(.6); transform-origin:top left }`; pad with `position:absolute; inset:24px`.
- Each proposal is its own full stage. Lead with distinct *structures*; restyle the four area frames to match the card aesthetic.

## Anti-patterns (learned the hard way)
- Don't proliferate dated files — one working file per thread.
- Don't open without `node --check` — silent blank page.
- Don't invent data — every stat/color/recipe must trace to a `data/*.gd` source.
- Don't let gold/colour leak across axes — gold is the T3/T4 frame signal, not a generic accent.
- Don't design tiny battlegrid cards without checking the **1080p** vertical budget (the native canvas; graceful degradation by card width band: hide ability text first, then secondary pods).

</supporting-info>
