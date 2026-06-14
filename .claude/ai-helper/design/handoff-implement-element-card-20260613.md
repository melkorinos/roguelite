# Handoff — Implement the Element Card (build phase) — COMPLETE

**2026-06-13 · Supersedes the old design handoff.** Design is finalised; this is the build brief.
**2026-06-14 · All steps done. Pass-2 roster tagging superseded — hue is now auto-blended from T1 root weights (`ElementData.root_family_weights` + `ThemeData.blended_family_color`); no manual family tags needed.**

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

- [x] **1 · Confirm pass 1 is green.** ✅ (2026-06-13) import + GUT data suite green.

- [x] **2 · Finish the data-layer tokens** ✅ (2026-06-13):
  - `ThemeData.gd` — `FRAME_METAL_T1/T2/T3`, `FRAME_PRISMATIC_STOPS`, `LEVEL_GLOW_PX`/`LEVEL_BRIGHT` + accessors `frame_metal/level_glow_px/level_bright`. `TIER_*_BG/BORDER` kept (ForgeSlot + Compendium still use them); card path no longer uses them. TooltipCard never used them.
  - `UIScale.gd` — `CARD_*` font consts + `apply_scaled`/`apply_rich_scaled` (one scalable component).
  - **Plus TDD:** `ElementData.stat_pods(item)` (pure §B pod rule) + tests; ThemeData frame/glow-clamp tests.

- [x] **3 · Rebuilt `scenes/shared/ElementCard.gd`** ✅ (2026-06-13). Frame panel + inner dark panel; portrait `GradientTexture2D` radial glow (level-brightened); metal `StyleBoxFlat` (T4 = prismatic `StyleBoxTexture`); pods from `stat_pods`; lineage underbar; ability `RichTextLabel` with keyword `[url]` links + trigger prefix; `card_width` param (height = width × 1.45) with §D width-band degradation (ability hides <140px, secondary pods <110px). Runtime-verified by `test/unit/scenes/test_element_card.gd`.

- [x] **4 · Refactored the slots onto the one card** ✅ (2026-06-13). `InventorySlot` now extends `ElementCard` (drag/F-forge layered on; bespoke Button styling deleted); `ShopItemTile`/`BattleSlot` set `card_width`; `Shop.gd` inventory rebuild uses `render()`/`clear()`.

- [x] **5 · Validate end-to-end.** ✅ import · boot · GUT 715/715 · visual verified at HD 1280×720 (board, forge bench, inventory all confirmed). (Also fixed a pre-existing unrelated drift: `test_advance_round_adds_5_gold` hardcoded 8 while `TuningData.GOLD_PER_ROUND=10` → now asserts `3 + GOLD_PER_ROUND`, renamed `..._adds_gold_per_round`.)

- [ ] **(parallel, non-blocking) · Pass-2 roster tagging.** Tag the remaining ~89 forged elements with a `"family"` by result-vibe — a reviewable data sweep. Until done, untagged elements render the neutral fallback hue (no crash). Can run anytime relative to steps 2–5.

## Deferred — separate features (out of scope here, file as issues)
- **`card animations`** — embers, L3 halo/sweep, prismatic motion, and the per-fire **firing FX**. The card must leave contrast headroom for firing FX; v1 static level separation is glow-intensity only, so L2↔L3 punch lands with this feature.
- **`card art`** — hand-built SVG portraits in the established style (see the SPEC's `ART_FIRE`-style SVG), replacing emoji. Portrait box is a fixed slot, so this is a non-breaking swap (`assets/elements/{id}.svg`, emoji fallback).

## Suggested skills
- `/grill-with-docs` if a build decision reopens a design question.
- `/design` to revisit any visual in-browser (conventions enforced).
- `/tdd` for the data-layer accessors (`canonical_family`, `family_color`).
