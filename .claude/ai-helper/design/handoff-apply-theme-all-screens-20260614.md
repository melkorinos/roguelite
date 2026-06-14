# Handoff — "hardware frame" theme + forge/tooltip revamp — ✅ CLOSED (2026-06-14)

**This handoff is done.** The whole-game UI revamp landed and is green: the beveled `ScenePanel`
frame on **every** screen (MainMenu/HowToPlay/Compendium/Settings/Battle) + pop-up, the shared
`UIStyle` chrome, the Compendium on real `ElementCard`s, the forge two-column redesign, the
hover/tooltip overhaul, and the Battle summary pop-up. There is no remaining work *in this
handoff* — open design/art items moved to the backlog below.

> (Renamed from `handoff-implement-element-card-20260613.md`; scope grew to the whole-game theme
> rollout, then the forge/tooltip revamp. Kept as the as-built record + entry point.)

## Where things live now
- **As-built specs** (build contracts / reference): [spec-element-card-20260613.md](spec-element-card-20260613.md) · [spec-shop-frame-system-20260614.md](spec-shop-frame-system-20260614.md).
- **Open design/art work:** [design-backlog.md](design-backlog.md) — the single list.
- The HTML mockups (`element-card-SPEC`, `shop-layout`) were **deleted** once the work landed — the
  running game is the visual reference now; the spec `.md` files are the build record. (For *new*
  in-flux design, `/design` still produces a working HTML per the "show in HTML, specify in MD" rule.)
- Also: ADR-0017 (3-axis card), `CONTEXT.md` glossary, `.claude/ai-helper/soul.md` (aesthetic).

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

## ✅ Rollout + revamp — DONE (2026-06-14). See `log.md` 2026-06-14.
- **Every screen + pop-up themed.** MainMenu / HowToPlay / Compendium / Settings / Battle in `ScenePanel`s; **per-screen accents** (`AREA_MENU`/`AREA_HELP`/`AREA_COMPENDIUM`/`AREA_SETTINGS`) — user chose per-screen over one neutral.
- **Compendium** on the **real `ElementCard`** node. **Battle** framed **aggressively** (user call): both boards + live DPS sidebar framed, buttons accent-styled, separators dropped.
- **Pop-ups** (Pause / StartingPick / Event / Battle-summary) — **lighter retint** (user call), via new `scenes/shared/UIStyle.gd` (`accent_button` / `dialog_panel` / `dialog_card`), all from ThemeData tokens.
- **Forge redesigned** — two columns (bench left = full `ElementCard`s; forge paths right; two valid → resulting card). **Element hover tooltip retired**; keyword popups → non-draggable contexts only via `ElementCard.keywords_interactive` + new `GlossaryPopup`; path-chip hover → new `CardPreview`. **Battle summary is a pop-up.**
- **Bad-info fixed:** native is **1920×1080** (`canvas_items`/`expand` scales the whole UI uniformly — no sub-1080 budget), not 1280×720. Corrected in README/goals/SKILL/spec.
- Validated: `--import`, boot each scene headless, headless forge harness, GUT 724/724.

## ⚠ Still-relevant build notes (carry forward)
- **Token reuse is the rule** — a new screen reuses an existing `AREA_*` accent + LayoutData gap; it never authors a `Color()` or magic spacing. `ScenePanel` adopts `.tscn` children via `reparent()` (preserves `%unique_name`; remove/add crashes boot in 4.6.3).
- **`CARD_BATTLE` is shared** — `BattleSlot` drives both the Shop board and the real Battle arena; if the arena needs its own footprint, split `CARD_BATTLE` board-vs-arena in LayoutData.
- **`TooltipCard.gd` was deleted** (2026-06-14) — the element hover stats tooltip is gone; on-card live stats (backlog) is the successor.

## ⏭ Open design/art work → [design-backlog.md](design-backlog.md)
The single list: on-card live stats · on-card recipe display · element-info surface · richer
single-element forge view · frame flourishes · the queued `AREA_*` desaturation pass · animations · card art.
