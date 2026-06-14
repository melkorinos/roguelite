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
   - Fonts/sizes → `data/UIScale.gd`.
   Use higher-tier *real* elements (e.g. the fire chain Fire→Lava→Volcano→Supernova) so the user reads the system in context, not toy data.

3. **Output location & naming.** Write to `.claude/ai-helper/design/` only — never the OS temp dir. Name `<component>-<purpose>-YYYYMMDD.html`. **One working file per thread** — overwrite it each iteration and delete superseded copies; do not spawn a new dated file every round (the user will ask "why are there N htmls"). For a structural change, full-rewrite the file; for a small tweak (one color/number/copy), use a surgical Edit.

4. **Self-contained tech.** A single `.html` that opens standalone with no local dependencies (the original `Element Card Exploration.html` broke because it `src`'d a local `design-canvas.jsx`). Inline CSS or Tailwind CDN; Google Fonts via `<link>`. A small inline JS generator (build cards from a data array) is fine and keeps the file DRY — but see validation.

5. **MANDATORY validation before opening.** A JS error blanks the whole page silently. Before every `start`:
   ```bash
   sed -n '/<script>/,/<\/script>/p' FILE.html | sed '1d;$d' > /tmp/check.js && node --check /tmp/check.js
   grep -oE "^const [A-Za-z_]+" FILE.html | sort | uniq -d   # must be empty
   ```
   (The classic blank-page bug was a duplicate `const` — art fn and data object sharing a name. Prefix art fns `ART_*`.) Only open after both pass. **Windows:** `start "" FILE.html` can fail on a relative path — use `Invoke-Item "<absolute-path>.html"` from PowerShell.

6. **Iterate like a designer.** Lead with 3+ distinct proposals when a direction is open; once one is chosen, deepen it (tiers, states, levels, context sizes). Batch grilling questions (5+ at a time) with a recommendation each. Keep cards true to their real footprint. **Canvas:** the game's native viewport is **1920×1080** (`project.godot` — `canvas_items` / `expand`); design full-screen layouts to that, and treat **1280×720** as the graceful-degradation *floor*, not the target.

7. **Hand off via docs, not the HTML — "show in HTML, specify in Markdown".** The split is deliberate:
   - **HTML** = the *visual* you judge by eye — mockups, rendered components, frame/colour samples. Authoritative for *look*. One working file per thread (point 3).
   - **Markdown** (`spec-<thing>-YYYYMMDD.md` in `.claude/ai-helper/design/`) = the *build contract* — tokens, node/API, file-change lists, rollout checklists. Authoritative for *implementation*; links the HTML for visuals.
   A component may have both (e.g. `element-card-SPEC.html` + a build spec). Also record crystallised decisions where they live: `CONTEXT.md` (glossary), `docs/adr/` (hard-to-reverse visual-architecture calls). A purely-visual component's HTML may double as its spec (embed a build-notes table); cross-cutting systems (tokens/APIs across scenes) belong in Markdown.

</what-to-do>

<supporting-info>

## Established card visual language (as of ADR-0017)
The Element Card communicates on **three independent axes** — keep them non-overlapping in any new component:
- **Hue = Canonical Family** (element identity: fire red, fungus purple…). 12-color family map.
- **Tier = frame material** (bronze → silver → gold → prismatic). Never background fill.
- **Level = glow/ember ramp** (1–3), never a number, never the frame.
Forge **Lineage** = the two parents' family hues (underbar marker). Animations and SVG art are deferred features ("card animations", "card art") — default to **static + emoji** unless the task is one of those features.

## Anti-patterns (learned the hard way)
- Don't proliferate dated files — one working file per thread.
- Don't open without `node --check` — silent blank page.
- Don't invent data — every stat/color/recipe must trace to a `data/*.gd` source.
- Don't let gold/colour leak across axes — gold is the T3/T4 frame signal, not a generic accent.
- Don't design tiny battlegrid cards without checking the 720p vertical budget (graceful degradation: hide ability text first, then secondary pods).

</supporting-info>
