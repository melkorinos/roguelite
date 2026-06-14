# Spec — Shop layout + beveled "hardware" frame system

**2026-06-14 · Implementation spec.** Visual source of truth: [shop-layout-20260614.html](shop-layout-20260614.html) (open in browser). This doc is the build brief: locked decisions, exact tokens, the reusable frame node, the Shop changes, and the rollout to every other scene.

## What this is
Two coupled pieces of work:
1. **Shop screen** rebuilt to the finalised layout (fixes the FIGHT-button overflow from the taller cards).
2. A reusable **beveled frame panel** (`ScenePanel`) + `ThemeData` frame tokens — the new "hardware" look — applied to the Shop first, then rolled out to **MainMenu, Settings, Battle, Compendium** so the whole game shares one panel language.

No `systems/` changes. Pure view/scene work + `ThemeData`/`UIScale` tokens.

---

## Locked decisions

### A. Shop layout — V1 · 65 / 35 (no scroll, 1920×1080 native)
Two columns under the existing TopBar + DebugRow:

```
┌─ LEFT column (65%) ───────────────┐ ┌─ RIGHT column (35%) ─┐
│ 🛒 FOR SALE   (row of 5, fixed h) │ │ 🎒 INVENTORY         │
│  [Reroll chip → header top-right] │ │   2 cols × 3 rows = 6 │
│                                   │ │   (fills, tall)       │
│ ⚔ BATTLE BOARD (fills remaining)  │ │                       │
│   4×2 grid · [► FIGHT chip →      │ │                       │
│              header top-right]    │ ├───────────────────────┤
│                                   │ │ ⚒ FORGE               │
│                                   │ │  in + in → [result]   │
└───────────────────────────────────┘ └───────────────────────┘
```

- **FOR SALE** = `flex 0 0 auto` (one 5-card row), same width as the board (it's in the left column).
- **BATTLE BOARD** = `flex 1` (takes all remaining left height). Real grid is **4×2** (`GridSystem` / ADR-0014: 4 base → 8 max, 2 rows, 2–4 cols). Lay out with `GridSystem.dimensions(slot_count)`.
- **INVENTORY** = the full-height right column, **2 columns × 3 rows, max 6**.
- **FORGE** = bottom of the right column; must show the **result element** (in-slot + in-slot → result card preview).
- **FIGHT** = a small **gold chip in the BATTLE BOARD header, top-right** (mirrors the shop's Reroll chip, a touch bigger). The old full-width `FightRow` at the bottom is **deleted** — that reclaims the height the board needed and fixes the overflow that hid the button.

### B. Frame language — raised bevel + light stepped-matte, "frames as hardware"
Every area panel is a **thick raised-metal frame**, not a thin outline:
- **Raised bevel:** thick accent border read as extruded metal via a **single consistent light source (top-left)** — top + left edges lightened, bottom + right edges darkened. Same light direction on every panel in every scene.
- **Stepped-matte touch:** one thin accent inner line set a few px inside the thick border (a subtle second "step"), for the crafted/mounted feel.
- Accent lives **on the frame only**; interiors stay near-black (`#0d0a09`) so the family-glow Element Cards remain the only saturated thing on screen.
- One **internal detail** per frame (the step line) — no rivets/ornaments in v1 (kept as future flourish).

### C. Per-area accent (frame colour only)
| Area | Accent | Hex | Note |
|------|--------|-----|------|
| Shop | warm amber | `#d99e38` | **Deliberately not tier-gold** — gold stays the T3/T4 *card* signal; shop uses a warmer amber so the axes don't leak. |
| Inventory | cool blue | `#5a9bd8` | |
| Battle board | red-orange | `#d8643c` | the hero panel |
| Forge | purple | `#a64fe0` | alchemical |
| FIGHT chip | gold | bg `#e89a32`, rim `#ffe6a8` | the **one** gold object on screen — nothing else uses it, so the eye always finds the CTA. |

### D. Card text fix (lands with this work)
From the in-engine review: the bold-blue **trigger prefix read too heavy**, and body/name were too small. Adjust `UIScale` card constants so the hierarchy is **Name (largest) › trigger condition (only slightly above body) › body**:
- `CARD_NAME` 20 → **22**
- `CARD_ABILITY` 10 → **12** (body)
- add `CARD_TRIGGER` = **13** (the trigger prefix; was reusing CARD_ABILITY at the same size + bold → now a distinct, only-slightly-larger size, not heavier). `ElementCard._ability_bbcode` should size the trigger span with `CARD_TRIGGER` and the body with `CARD_ABILITY`.

---

## New `ThemeData` tokens (Godot)
```gdscript
# ── Scene frame system (beveled hardware panels) ──────────────────────────────
const FRAME_THICKNESS: int   = 5      # px border band (native 1920×1080)
const FRAME_RADIUS: int      = 11
const FRAME_STEP_GAP: int    = 4      # inset of the stepped inner line past the border
const FRAME_STEP_ALPHA: float = 0.22  # inner accent line opacity
const FRAME_BEVEL_LIGHT: float = 0.35 # accent.lightened() for top/left edge
const FRAME_BEVEL_DARK: float  = 0.45 # accent.darkened()  for bottom/right edge
const PANEL_INTERIOR := Color(0.050, 0.035, 0.030, 1.0)   # near-black, matches card inner

# Per-area accents (frame colour only — interiors stay PANEL_INTERIOR)
const AREA_SHOP      := Color(0.851, 0.620, 0.220)  # #d99e38 amber (NOT tier gold)
const AREA_INVENTORY := Color(0.353, 0.608, 0.847)  # #5a9bd8
const AREA_BATTLE    := Color(0.847, 0.392, 0.235)  # #d8643c
const AREA_FORGE     := Color(0.651, 0.310, 0.878)  # #a64fe0

# FIGHT call-to-action gold (the only gold UI chrome)
const FIGHT_BG     := Color(0.910, 0.604, 0.196)
const FIGHT_RIM    := Color(1.000, 0.902, 0.659)
const FIGHT_TEXT   := Color(0.227, 0.141, 0.000)
```

---

## New reusable node — `scenes/shared/ScenePanel.gd`
One node, used by every scene. `extends MarginContainer` so its content margins inset children past the frame; the frame is painted in `_draw()` (behind children).

```gdscript
class_name ScenePanel
extends MarginContainer

# A beveled "hardware" panel: thick accent frame (raised, top-left light source) +
# a stepped inner accent line, near-black interior. Header row (glyph + title +
# optional right-aligned action chip) on top; body container below for content.

var accent: Color = ThemeData.AREA_SHOP
var _header: HBoxContainer
var _title_lbl: Label
var _action_slot: HBoxContainer
var _body: VBoxContainer

func _ready() -> void:
    var pad: int = ThemeData.FRAME_THICKNESS + ThemeData.FRAME_STEP_GAP + 8
    add_theme_constant_override("margin_left", pad)
    add_theme_constant_override("margin_right", pad)
    add_theme_constant_override("margin_top", pad)
    add_theme_constant_override("margin_bottom", pad)
    # header row + body built here (glyph+title left, _action_slot right via SIZE_EXPAND on a spacer)
    ...

func setup(title: String, glyph: String, area_accent: Color) -> void   # sets accent, header text, queue_redraw()
func set_action(node: Control) -> void   # drops a chip (Reroll / FIGHT) into _action_slot, right-aligned
func body() -> VBoxContainer              # scene adds its content here

func _draw() -> void:
    var rect := Rect2(Vector2.ZERO, size)
    # 1. interior + thick accent border + rounding, in ONE StyleBoxFlat
    var box := StyleBoxFlat.new()
    box.bg_color = ThemeData.PANEL_INTERIOR
    box.set_border_width_all(ThemeData.FRAME_THICKNESS)
    box.border_color = accent
    box.set_corner_radius_all(ThemeData.FRAME_RADIUS)
    draw_style_box(box, rect)
    # 2. bevel: lighten top+left inner edge, darken bottom+right (consistent light source)
    var hi := accent.lightened(ThemeData.FRAME_BEVEL_LIGHT)
    var lo := accent.darkened(ThemeData.FRAME_BEVEL_DARK)
    var t := float(ThemeData.FRAME_THICKNESS)
    #  draw 2px polylines just inside the border: top+left in `hi`, bottom+right in `lo`
    #  (stop ~radius px short of each corner so the rounding reads clean)
    ...
    # 3. stepped inner accent line: a transparent-bg StyleBoxFlat, 2px border, accent@FRAME_STEP_ALPHA,
    #    inset by FRAME_THICKNESS + FRAME_STEP_GAP, radius FRAME_RADIUS - FRAME_STEP_GAP
    var step := StyleBoxFlat.new()
    step.draw_center = false
    step.set_border_width_all(2)
    step.border_color = Color(accent.r, accent.g, accent.b, ThemeData.FRAME_STEP_ALPHA)
    step.set_corner_radius_all(maxi(2, ThemeData.FRAME_RADIUS - ThemeData.FRAME_STEP_GAP))
    var inset := ThemeData.FRAME_THICKNESS + ThemeData.FRAME_STEP_GAP
    draw_style_box(step, rect.grow(-float(inset)))
```
- **Header builder:** glyph + tracked uppercase title in `accent.lightened(0.25)`, sized via a new `UIScale.PANEL_HEADER`; a spacer (`SIZE_EXPAND_FILL`) then `_action_slot` so chips land top-right.
- Call `queue_redraw()` from `setup()` and on resize (`_draw` re-runs on size change automatically for a redraw-on-resize Control — set `_draw` to use `size`).
- **Reroll / FIGHT chips:** small `Button`s styled with a StyleBoxFlat (Reroll = neutral; FIGHT = `FIGHT_BG` bg, `FIGHT_RIM` 1px border, `FIGHT_TEXT`, Fredoka, slight shadow). FIGHT chip is added to the board panel via `set_action`.

> StyleBox-only fallback (if `_draw` bevel is fiddly): outer `PanelContainer` with a thick-border `StyleBoxFlat` (single accent) + `shadow_offset = (0, 3)` for lift, nested over an inner `StyleBoxFlat` step. Loses the two-tone bevel but keeps thick+stepped. Prefer the `_draw` route for the true hardware look.

---

## Shop changes — `Shop.tscn` / `Shop.gd`
- **Restructure `MainArea`** to two columns 65/35 (replace the current single `LeftPanel` stack + `RightPanel`). Wrap each area in a `ScenePanel`:
  - Left col: `ScenePanel("FOR SALE","🛒",AREA_SHOP)` (Reroll chip via `set_action`) → `ScenePanel("BATTLE BOARD","⚔",AREA_BATTLE)` (FIGHT chip via `set_action`).
  - Right col: `ScenePanel("INVENTORY","🎒",AREA_INVENTORY)` → `ScenePanel("FORGE","⚒",AREA_FORGE)`.
- **Delete** `FightRow` + `FightButton` from the bottom; move the fight action to the board panel's `set_action`. Re-wire `_on_fight_pressed` to the new chip's `pressed`.
- **Inventory** → fill the right `ScenePanel.body()` with a `GridContainer(columns=2)` of 6 `InventorySlot`s (2×3).
- **Forge** → add a result preview slot (a non-interactive `ElementCard` or `ForgeSlot` showing `ForgeSystem` preview) after the two input slots + arrow.
- Existing `SellZone` drag-to-sell still overlaps the FOR SALE panel (unchanged behaviour).
- Card widths: tune so the board reads at the 4×2 footprint (see HTML: board ≈186, shop ≈196, inventory ≈124, forge in ≈98/result ≈118 at native scale).

**Validation:** `godot --headless --import` → `--quit`; full GUT (20 suites incl. `test/unit/scenes/`); eyeball the Shop at 1920×1080 — FIGHT chip visible in board header, nothing clipped.

---

## Rollout to the other scenes
Yes — this is designed to generalise. Once `ScenePanel` + tokens exist, each scene is a mechanical wrap: replace bespoke `PanelContainer`/`StyleBoxFlat` section backgrounds with a `ScenePanel` carrying an accent. **Do them one PR at a time, validating each.**

| Scene | Panels to wrap | Accent guidance | Effort |
|-------|----------------|-----------------|--------|
| **MainMenu** | title card / button stack container | single neutral or `AREA_SHOP` amber | low |
| **Settings** | the settings group(s), keybind list | neutral / `AREA_INVENTORY` | low |
| **Compendium** | the tier sections + keystone section + recipe rows panel | per-tier could reuse the card metals, or one `AREA_INVENTORY` frame around the grid | medium (many sub-panels) |
| **Battle** | player/opponent side panels, contribution panel, result/summary panels, status readout | `AREA_BATTLE` for arena, neutral for HUD readouts | **highest** (live combat HUD; verify nothing overlaps the grid/labels at speed) |

Per-scene checklist:
1. Wrap each visual section in a `ScenePanel`; pass title/glyph/accent.
2. Delete the section's old `StyleBoxFlat` background + ad-hoc header label (now the panel header).
3. Keep all logic/signals; only the container changes.
4. `--import` → `--quit` → GUT → eyeball at 1920×1080.

**Honest note:** MainMenu/Settings/Compendium are straightforward. **Battle is the real lift** — it has live, per-frame UI and tight vertical budget during combat; wrap conservatively and eyeball at 1×/2× speed. An agent can follow this spec for the easy three without handholding; Battle warrants a human eyeball pass.

---

## Out of scope / deferred
- **Frame flourishes** (rivets, corner ornaments, title plates) — kept as a later polish pass; v1 is bevel + step only.
- **Animation** (panel entrance, FIGHT pulse) — separate `card animations`-style feature.
- **Card art** (SVG portraits) — unchanged, still the deferred swap.

## Suggested skills
- `/design` to revisit any frame visual in-browser (the HTML stays the source of truth).
- `/tdd` only where logic appears (none expected — this is view work).
