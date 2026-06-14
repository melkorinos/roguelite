# Handoff — UI design system (Element Card ✓ · Shop layout + frame system → implement)

**Agent entry point.** The Element Card is built and green. The **next task is the Shop layout + beveled frame system**, whose reusable foundation is already landed (compiling) — what remains is the `Shop.tscn`/`Shop.gd` restructure and then rolling the frame to the other scenes.

> Filename is historical (`handoff-implement-element-card`); scope is now the whole UI design system. Rename if desired.

## The four design artifacts (convention: show in HTML, specify in Markdown)
| | Visual (HTML) | Build spec (MD) |
|---|---|---|
| **Element Card** | [element-card-SPEC-20260613.html](element-card-SPEC-20260613.html) | [spec-element-card-20260613.md](spec-element-card-20260613.md) |
| **Shop + frame system** | [shop-layout-20260614.html](shop-layout-20260614.html) | [spec-shop-frame-system-20260614.md](spec-shop-frame-system-20260614.md) |

Also: ADR-0017 (3-axes card), `CONTEXT.md` glossary, `.claude/ai-helper/soul.md` (aesthetic).

---

## ✅ DONE — Element Card (see spec-element-card)
3-axis card (hue = blended T1 root families · tier = metal/prismatic frame · level = glow), tested `stat_pods` pod rule, `card_width` scaling + §D degradation, all slots refactored onto the one card. Full build history + as-built detail in the card spec. Tests green: `test_element_data`, `test_theme_data`, `test_element_card`.

## ✅ DONE — Frame-system foundation (landed, compiling, tested)
- **`ThemeData`** frame tokens: `FRAME_THICKNESS/RADIUS/STEP_GAP/STEP_ALPHA/BEVEL_LIGHT/BEVEL_DARK`, `PANEL_INTERIOR`, area accents `AREA_SHOP/INVENTORY/BATTLE/FORGE`, `FIGHT_BG/RIM/TEXT`.
- **`scenes/shared/ScenePanel.gd`** — beveled "hardware" panel (raised bevel + stepped inner line, top-left light source). `setup(title, glyph, accent)` · `set_action(node)` (header chip) · `body()` (content). Adopts pre-existing `.tscn` children into its body, so it can wrap existing nodes — **reference those nodes via unique names (`%Name`) so the reparent is safe.**
- **Card font hierarchy fix:** `UIScale.CARD_NAME` 20, `CARD_ABILITY` 12, new `CARD_TRIGGER` 13; `ElementCard._ability_bbcode` sizes the trigger prefix with `CARD_TRIGGER` (de-emphasised, keeps bold/blue style).

## ⏭ NEXT — Shop restructure (build per spec-shop-frame-system §"Shop changes")
Layout **V1 · 65/35** (locked): left col = SHOP (top) / BATTLE BOARD (fills) ; right col = INVENTORY (2×3, tall) / FORGE. **FIGHT becomes a small gold chip in the BATTLE BOARD header** (delete the bottom `FightRow` — this is what fixes the overflow that currently hides the button). Frames = **raised bevel + stepped matte** via `ScenePanel`, per-area accent.

**Do it in two safe commits** (each compiles + boots so layout bugs surface early, not buried in one 200-line scene diff):
1. **Layout + FIGHT fix** — MainArea → 65/35 columns; move INVENTORY to the right column as a 2×3 `GridContainer`; delete `FightRow`/`FightButton`; create a gold FIGHT chip + Reroll chip and place them in the board/shop headers; re-path Shop.gd. Fixes the bug.
2. **Frames** — wrap the four areas in `ScenePanel` (accents `AREA_*`). **Two wrinkles (not mechanical):**
   - **`SellZone`** (FOR SALE) paints its own amber panel + green hover border. Reduce its resting style to transparent so `ScenePanel` is the frame; keep only its drag-hover state.
   - **`ForgePanel`** keeps its own children (`$ForgeHeader/$ForgeButton/$ForgeSlotsRow/$ForgeResultLabel/$ForgeInfoLabel` — reached by `$path`, so don't reparent *its* children). Wrap the whole `ForgePanel` node; resolve the redundant "FORGE BENCH" header (either drop `ForgeHeader` or give the wrapping `ScenePanel` an empty title). Add the forge **result preview** card slot.

**Decouple paths first:** before restructuring, set `unique_name_in_owner = true` on the nodes Shop.gd touches (`SellZone`, `ShopGrid`, `BattleGrid`, the inventory grid, `ForgePanel`) and switch `Shop.gd` `$VBox/MainArea/…` references to `%Name` — then moving nodes into `ScenePanel` bodies won't break them.

**Validate each commit:** `godot --headless --import` → `--quit` → GUT (4 leaf dirs incl. `test/unit/scenes/`, per CLAUDE.md).

## ⏭ THEN — roll the frame to the other scenes (spec §"Rollout")
One PR each, validate each: **MainMenu / Settings / Compendium** are straightforward `ScenePanel` wraps; **Battle** is the highest-effort (live per-frame HUD, tight vertical budget) — wrap conservatively. Per-scene accent table + checklist in the shop spec.

## Deferred (out of scope)
Card animations · card art · frame flourishes (rivets/ornaments/title-plates — v1 is bevel + step only) · panel/FIGHT animation.
