# Spec — Element Card (ADR-0017)

**Status: IMPLEMENTED** (build complete 2026-06-13/14). This is the build contract / as-built reference. Visual source of truth: [element-card-SPEC-20260613.html](element-card-SPEC-20260613.html) (open in browser). Convention: *show in HTML, specify in Markdown.*

## What it is
One always-visible component (`scenes/shared/ElementCard.gd`, `extends PanelContainer`) that renders an element **identically** in every context — shop for-sale tile, inventory slot, battle-board slot — differing only by price badge / charge bar. Subclasses layer interaction on top; the base owns all visuals + the hover→Item-Tooltip behaviour.

## Three independent visual axes (keep non-overlapping)
| Axis | Means | Rendered as | Source |
|------|-------|-------------|--------|
| **Hue** | Canonical Family (identity) | portrait radial glow + name tint + lineage underbar | `ThemeData.blended_family_color(ElementData.root_family_weights(id))` |
| **Tier** | frame **material** | bronze→silver→gold metal `StyleBoxFlat`; **T4 = prismatic `StyleBoxTexture`** | `element.tier` → `ThemeData.frame_metal(tier)` / `FRAME_PRISMATIC_STOPS` |
| **Level** | glow **intensity** (static v1) | portrait brightness + glow radius | `element.level` → `ThemeData.level_bright/level_glow_px` |

> **Hue is auto-derived, not hand-tagged.** Superseded the old per-element `"family"` tags: an element's hue is the weighted blend of its Tier-1 *root* families (`root_family_weights` walks the recipe tree; each tier doubles the root count — T1→1, T2→2, T3→4, T4→8), blended via `blended_family_color`. No manual roster tagging needed.

## Stat pods — the §B pod rule (tested pure helper)
`ElementData.stat_pods(item) -> Array[Dictionary]`, each pod `{ "value": String, "label": String, "highlight": bool }`:
- **Damage-dealer** (`DAMAGE_DEALERS.has(id)`, `effective_damage > 0`) → `[CD, DMG]`. Takes precedence (a T1 dealer like Blood shows DMG, not its status).
- **On-activate applier** → `[CD, STATUS]`. Status amount = **authored amount × `scaled_potency(tier, level)`** (the landed combat value, confirmed at the `AbilitySystem.apply_effect` seam). Source: `ElementData.effect` for T1, `AbilityData.effects[0]` (when `trigger == "on_activate"` and `kind == "apply_status"`) for T2+.
- **Reactive / passive / combat-start / no-ability** → `[CD]` only (output is conditional — a static number would lie; the trigger label + ability text carry it).

Kept out of the scene script so it is unit-testable. Pod rule lives in [data/ElementData.gd](../../../data/ElementData.gd).

## Node tree (built in code, `_ready`)
```
ElementCard (PanelContainer)        ← "panel" = tier frame: metal StyleBoxFlat (T4 StyleBoxTexture prismatic)
└ InnerPanel (PanelContainer)       ← near-black interior; frame shows as a ring via content margins
  └ VBox
    ├ [ChargeBar]  (ProgressBar)    ← battle context only (show_charge)
    ├ Portrait (Control)            ← clip; radial family glow
    │   ├ TextureRect (GradientTexture2D radial, level-brightened)
    │   └ Label (emoji)
    ├ Underbar (HBox: 2 ColorRect)  ← lineage split bar (T2+), parents' blended hues
    ├ NameLabel (Label)             ← family-tinted (Fredoka)
    ├ StatsRow (HBox)               ← 1–3 pods from stat_pods()
    ├ AbilityRich (RichTextLabel)   ← trigger prefix + [url] keyword links (reuses TooltipCard logic)
    └ [PriceLabel] (Label)          ← shop context (show_price)
```

## Sizing & degradation
- One scalable param `card_width`; **height = width × 1.45** (`HEIGHT_RATIO`). Fonts scale via `UIScale.apply_scaled(base, card_width/CARD_REFERENCE_WIDTH)`.
- Graceful degradation by width band (SPEC §D): ability text hidden below `ABILITY_MIN_WIDTH` (140px → lives in tooltip); secondary pods + lineage drop below `SECONDARY_POD_MIN_WIDTH` (110px, CD pod survives).
- **Native canvas 1920×1080** (`canvas_items`/`expand`) — the design budget. The width-band degradation above is the card's own responsiveness, NOT a sub-1080 layout target (`canvas_items`/`expand` scales the whole UI uniformly to the window).

## Tokens
**`ThemeData`:** `FAMILY_COLOR` (12) + `family_color()`/`blended_family_color()`/`FAMILY_COLOR_FALLBACK`; `FRAME_METAL_T1/T2/T3` (#a8703c/#b4bac6/#dcb653) + `frame_metal()`; `FRAME_PRISMATIC_STOPS` (6 stops, conic, baked **linear** `StyleBoxTexture` in v1); `LEVEL_GLOW_PX {1:3,2:13,3:24}` / `LEVEL_BRIGHT {1:1.24,2:1.46,3:1.72}` + `level_glow_px()/level_bright()` (clamp 1–3).

**`UIScale`** (authored at `CARD_REFERENCE_WIDTH = 200`): `CARD_EMOJI 50`, `CARD_NAME 20`, `CARD_POD_VALUE 18` / `_SOLO 20` / `_TRIO 14`, `CARD_POD_LABEL 9` / `_TRIO 8`, `CARD_ABILITY 12`, `CARD_TRIGGER 13`; helpers `apply_scaled` / `apply_rich_scaled`.

## Font hierarchy (corrected in-engine)
**Name (largest) › trigger condition (only slightly above body) › body.** The bold-blue trigger prefix read too heavy at first build — it keeps its style but is sized with `CARD_TRIGGER` (13), a hair above the `CARD_ABILITY` (12) body, via `[font_size=…]` in `ElementCard._ability_bbcode`. Body + name bumped up for readability.

## Subclasses (interaction layered on the one card)
- `scenes/slots/ShopItemTile.gd` — price + click-to-buy + "shop" drag source; `card_width` from `SIZE`.
- `scenes/slots/BattleSlot.gd` — charge bar + drag + F-quick-forge + fire animation; `card_width`.
- `scenes/slots/InventorySlot.gd` — **extends ElementCard** (was a bespoke Button); drag + F-forge; `card_width`.
Set config (`card_width`, `show_*`, `empty_*`) BEFORE `super._ready()`.

## Tests
- Pod rule + `root_family_weights` → [test/unit/data/test_element_data.gd](../../../test/unit/data/test_element_data.gd)
- Family / frame metals / level-glow clamp / `blended_family_color` → [test/unit/data/test_theme_data.gd](../../../test/unit/data/test_theme_data.gd)
- Runtime render (glow / metal+prismatic frame / pods / lineage / clear) → [test/unit/scenes/test_element_card.gd](../../../test/unit/scenes/test_element_card.gd)

## Deferred (separate features)
- **card animations** — embers, L3 halo/sweep, prismatic motion, per-fire firing FX. (v1 level separation is glow-intensity only; leave contrast headroom.)
- **card art** — hand-built SVG portraits replacing emoji (`assets/elements/{id}.svg`, emoji fallback). Portrait box is a fixed slot → non-breaking swap.
