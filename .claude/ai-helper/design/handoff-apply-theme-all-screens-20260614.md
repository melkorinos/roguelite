# Handoff — apply the "hardware frame" theme to every screen

**Agent entry point.** The Element Card, the beveled frame system, and the **Shop** are all built and green. The remaining work is **rolling the same theme to the other screens** (MainMenu, Settings, Compendium, Battle) using the shared node + the centralized tokens — no new colors, sizes, or spacings invented per screen.

> (Renamed from `handoff-implement-element-card-20260613.md`; scope is now the whole-game theme rollout.)

## Design artifacts (convention: show in HTML, specify in Markdown)
| | Visual (HTML) | Build spec (MD) |
|---|---|---|
| **Element Card** | [element-card-SPEC-20260613.html](element-card-SPEC-20260613.html) | [spec-element-card-20260613.md](spec-element-card-20260613.md) |
| **Shop + frame system** | [shop-layout-20260614.html](shop-layout-20260614.html) | [spec-shop-frame-system-20260614.md](spec-shop-frame-system-20260614.md) |

Also: ADR-0017 (3-axis card), `CONTEXT.md` glossary, `.claude/ai-helper/soul.md` (aesthetic).

---

## ✅ DONE
- **Element Card** — 3-axis (hue = blended T1 roots · tier = metal/prismatic frame · level = glow). Tests green.
- **Frame foundation** — `scenes/shared/ScenePanel.gd`: thick raised bevel (top-left light) + stepped inner line, near-black interior. `setup(title, glyph, accent)` · `set_action(chip)` · `body()`. **It adopts its `.tscn` children into `body()` via `reparent()`** (NOT remove/add — that drops `%unique_name` registration in Godot 4.6.3 and crashed boot; fixed). So a scene can wrap existing nodes; reference them via `%Name`.
- **Shop** — fully themed: 50/50 columns; left = FOR SALE / INVENTORY, right = BATTLE BOARD / FORGE; each area a `ScenePanel` with its accent; Reroll + gold FIGHT chips in panel headers; SellZone resting style transparent (frame owns the border). Thin separators gone — separation now *is* the framing.

## The token files — REUSE THESE, never hardcode per screen
This is the whole point of the rollout: every screen draws from the same sources.
- **`data/ThemeData.gd`** — colors. Frame geometry+color tokens (`FRAME_THICKNESS/RADIUS/STEP_GAP/STEP_ALPHA/BEVEL_*`, `PANEL_INTERIOR`), per-area accents (`AREA_SHOP/INVENTORY/BATTLE/FORGE`), `FIGHT_*`. **This is the standard palette** — a new screen picks an existing `AREA_*`, it does not author a new `Color()`.
- **`data/LayoutData.gd`** (new) — spatial values: per-context card widths (`CARD_SHOP/INVENTORY/BATTLE/FORGE/COMPENDIUM`), `CARD_HEIGHT_RATIO`, screen split, and the **spacing rhythm** (`COLUMN_GAP`, `PANEL_GAP`, `GRID_CELL_GAP`, `PANEL_INNER_PAD/GAP`). `ScenePanel` reads the `PANEL_INNER_*`; scenes apply the gaps in code (see `Shop._apply_theme` for the reference pattern). Family: ThemeData=color, LayoutData=space, UIScale=fonts, TuningData=balance.
- **`data/UIScale.gd`** — font sizes (incl. card-scaled + `PANEL_HEADER`).

## ⏭ NEXT — roll the theme to the other screens (one PR each, validate each)
Mechanical wrap per `spec-shop-frame-system §"Rollout"` (per-scene accent table + checklist there). Use `Shop` as the worked example.
- **MainMenu / Settings / Compendium** — straightforward `ScenePanel` wraps; reuse `AREA_*` accents + LayoutData gaps; replace bespoke `StyleBoxFlat` section backgrounds + ad-hoc header labels with the panel.
- **Battle** — highest effort (live per-frame HUD, tight vertical budget); wrap conservatively, eyeball at 1×/2× speed.
- For each: `--import` → `--quit` → boot the scene directly (`godot ... res://scenes/screens/X.tscn`) → GUT (4 leaf dirs).

## ⚠ Pending / deferred (info that shapes the rollout)
- **"Neon commercial" over-saturation** — the current `AREA_*` accents read too saturated/loud as a set. A global **desaturation/tuning pass** is queued for a later session; because the accents are centralized in `ThemeData`, it's a one-file change. Do the rollout against the current tokens; when they're toned down, every screen updates at once. **Don't pre-tune per screen.**
- **Forge result preview card** — the forge still shows the result as the `ForgeResultLabel` text; the planned non-interactive `ElementCard` preview (`ForgeSystem.result_element`) was not built yet.
- **`CARD_BATTLE` is shared** — `BattleSlot` drives both the Shop board and the real Battle arena. The arena isn't redesigned; if it needs a different footprint, split `CARD_BATTLE` into board-vs-arena in LayoutData.
- **Frame flourishes** (rivets / ornaments / title-plates), **animations** (panel entrance, FIGHT pulse), **card art** — all still deferred. v1 is bevel + step only.
