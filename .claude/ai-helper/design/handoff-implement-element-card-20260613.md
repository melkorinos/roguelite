# Handoff — Implement the Element Card (build phase)

**2026-06-13 · Supersedes the old design handoff.** Design is finalised; this is the build brief.

## What this is
Rebuild the always-visible **Element Card** to the finalised design. It renders one element identically in shop (for-sale), inventory, board (shop screen), and battle — only price badge / charge bar differ per context. This is a **view rebuild**: every value is already derivable from existing data — **only the Family→hue mapping is new**. No `systems/` changes.

## Source of truth (read these, don't re-derive)
- **Visual spec (open in browser):** [element-card-SPEC-20260613.html](element-card-SPEC-20260613.html) — canonical cards, pod rule, tier frames, static level ramp, context-size degradation, and the full Godot node/token/data map.
- **Decision record:** `docs/adr/0017-element-card-hue-tier-level-axes.md` — the 3-axes call.
- **Glossary:** `CONTEXT.md` → *Family*, *Canonical Family*, *Element Card*.
- **Aesthetic:** `.claude/ai-helper/soul.md` (clean, minimal, weird, surreal; not cute/grimdark).

## Locked decisions
- **3 independent axes:** hue = **Canonical Family** · tier = **frame material** (T1 bronze → T2 silver → T3 gold → T4 prismatic) · level = **glow ramp** (static in v1).
- **Hue source:** per-family (12 colors) + a designer-authored **canonical family** per element, by *result vibe* (Steam→water, Obsidian→earth, Supernova→light). Option B + Rule 1.
- **Lineage:** underbar (split bar of the two parents' family hues) on T2+; split-ring kept as a fallback only.
- **Stat pods:** Dealer → CD + **DMG** (`effective_damage`). On-activate **applier** → CD + **STATUS** (keyword + base × `scaled_potency`; from `ElementData.effect` for T1, `AbilityData.effects[0]` for T2+). **Reactive/passive/combat-start → CD-only** (conditional output; ability text carries it — e.g. Steam = `on_burn_applied` → deal 1).
- **Sizing:** one scalable component (height = width × 1.45) with graceful degradation; **HD 1280×720 floor** (board band hides ability text first). See SPEC §D.
- **v1 scope:** static, **emoji** art.

## Build order — strict sequence

Do these **in order**. Step 0 is done; **START AT STEP 1.** (Step 4, pass-2 tagging, is the one exception — it is non-blocking and may be done anytime, even last.)

- [x] **0 · Data layer — pass 1** ✅ (2026-06-13)
  - `ThemeData.FAMILY_COLOR` (12) + `family_color(family)` (neutral fallback).
  - `ElementData.canonical_family(id)` (T1 = self · forged = `"family"` tag · untagged → `""`) + demo chain tagged (steam→water, lava→fire, volcano→fire, supernova→light).
  - Tests: `test/unit/data/test_theme_data.gd` (new) + `canonical_family` cases in `test_element_data.gd`. **Written but not executed** (no Godot on the authoring box) — first action below is to run them.

- [ ] **1 · Confirm pass 1 is green.** `godot --headless --import` then the GUT data suite (see CLAUDE.md). Fix any red before continuing.

- [ ] **2 · Finish the data-layer tokens** (blocks the card — must precede step 3):
  - `ThemeData.gd` — add `FRAME_METAL_T1/T2/T3`, `FRAME_PRISMATIC_STOPS`, `LEVEL_GLOW_PX`/`LEVEL_BRIGHT`; retire `TIER_*_BG/BORDER` as card fills (grep usages: ElementCard, InventorySlot, TooltipCard).
  - `UIScale.gd` — pod value/label, name, ability font consts.
  - Values to use: SPEC §E "New tokens" table.

- [ ] **3 · Rebuild `scenes/shared/ElementCard.gd`** `render()` to the SPEC node tree: portrait radial glow via `GradientTexture2D` modulated by `family_color`; metal `StyleBoxFlat` (T4 = `StyleBoxTexture` prismatic); 1–3 stat pods (pod rule = SPEC §B); lineage underbar; ability `RichTextLabel` reusing TooltipCard's `[url]` keyword logic; static level glow. One scalable size param (height = width × 1.45), graceful degradation per SPEC §D.

- [ ] **4 · Refactor the slots onto the one card.** `scenes/slots/InventorySlot.gd` → **extend `ElementCard`** (currently a bespoke `Button`); layer click/drag/F-forge on top — this deletes its duplicate `apply_item_style`. Add the width/scale param to `ShopItemTile`/`BattleSlot`.

- [ ] **5 · Validate end-to-end.** `godot --headless --import` → `--quit`; full GUT suites; eyeball the card in shop/inventory/battle at HD.

- [ ] **(parallel, non-blocking) · Pass-2 roster tagging.** Tag the remaining ~89 forged elements with a `"family"` by result-vibe — a reviewable data sweep. Until done, untagged elements render the neutral fallback hue (no crash). Can run anytime relative to steps 2–5.

## Deferred — separate features (out of scope here, file as issues)
- **`card animations`** — embers, L3 halo/sweep, prismatic motion, and the per-fire **firing FX**. The card must leave contrast headroom for firing FX; v1 static level separation is glow-intensity only, so L2↔L3 punch lands with this feature.
- **`card art`** — hand-built SVG portraits in the established style (see the SPEC's `ART_FIRE`-style SVG), replacing emoji. Portrait box is a fixed slot, so this is a non-breaking swap (`assets/elements/{id}.svg`, emoji fallback).

## Suggested skills
- `/grill-with-docs` if a build decision reopens a design question.
- `/design` to revisit any visual in-browser (conventions enforced).
- `/tdd` for the data-layer accessors (`canonical_family`, `family_color`).
