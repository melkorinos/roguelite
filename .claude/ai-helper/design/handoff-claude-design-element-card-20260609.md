# Element Card — Design Handoff
**2026-06-09 · Status: Ready for design · DATA REFRESHED 2026-06-12** (roster 132→105 after the T2 consolidation, ability overhaul landed: example tables below updated to live data; spec itself unchanged)

## What
Core UI tile. 1 card = 1 combat piece. Lives in 3 contexts (shop for-sale row, inventory, Battlegrid) — **layout identical everywhere**; context only adds/removes price badge + charge bar. Always fully visible, no hover needed (strategic layer lives on the face).

## Tech (Godot 4 / GDScript)
Output = static HTML/CSS spec, hand-translated to Godot nodes.
- Tokens: **SCREAMING_SNAKE_CASE** (→ GDScript consts). Font px-only, no rem/em.
- Layout = vertical stack (VBoxContainer); no CSS-grid tricks.
- Colors labeled with `ThemeData.gd` const + hex.
- Art: SVG at `assets/elements/{key}.svg` (key = `ElementData.gd` dict key), import as Texture2D, ~46px in darker inner art box. Missing SVG → emoji fallback.
- Ability keywords (`[burn]`, `[shock]`) = `RichTextLabel` `[url]` tags → `TooltipCard` on click/hover.

## Aesthetic
Clean, minimal, weird, surreal. Not cute, not grimdark. Uncanny objects, polished. Dark bg. Tier color = only vibrancy; text/chrome restrained. Physical artifact w/ slight weight, not flat chip. Sharp 4px radius.

## Archetypes (drives layout split)
- **Pure-effect** — fires status on CD, no direct dmg. Stats row = **CD only**, centered.
- **Damage-dealer** — direct dmg on CD (may also apply status). Stats row = **CD + DMG**.

All 12 T1 = pure-effect. 20 elements T2/T3/T4 = damage-dealers (whitelist in code). Most T2+ also pure-effect.

## Layout — portrait 130×195 fixed
```
┌─────────────────────────┐
│█████████████████████████│ ← [13] Charge Bar 6px top · battle only
│                   [T2]  │ ← [6] Tier badge · top-right pill
│            ♨️           │ ← [4] art/emoji ~46px centered
│          Steam          │ ← [5] name 13px centered
│   3.5s          1       │ ← pure:  [7] CD left · [9] count+label right
│    CD          BURN     │
│   3.5s          5       │ ← dealer:[7] CD left · [9] DMG right
│    CD          DMG      │
│  ─────────────────────  │ ← separator
│  REACTIVE               │ ← [10] trigger 10px
│  When [burn] applied,   │ ← [11] ability text 10px · 2 lines
│  deal 1 bonus dmg.      │
│                  [8g]   │ ← [12] price · shop only
└─────────────────────────┘
[1] bg  [2] border  [3] level glow
```

## Items
| # | Item | Spec |
|---|---|---|
| 1 | Background | Tier fill. T1 green / T2 blue / T3 purple / T4 gold. |
| 2 | Border | Tier accent. 2px solid, 4px radius. |
| 3 | Level glow | Border luminosity + outer glow only, no number. L1 base/no glow · L2 +25% bright+soft · L3 +50% bright+strong. Hue tier-locked; only brightness moves. |
| 4 | Art/emoji | SVG `assets/elements/{key}.svg` ~46px in darker inset art box (rounded). Emoji fallback. Centered, top. |
| 5 | Name | 13px centered, single line, ellipsis. |
| 6 | Tier badge | "T1".."T4" top-right. Dark semi-transparent pill, 10px bold. |
| 7 | Cooldown | Value bold 11px + "CD" 9px dimmed below. **Always left stat**, paired w/ [9]. |
| 8 | ~~Base Dmg~~ | **Excluded.** |
| 9 | Right stat | **Dealer:** Eff.Dmg (`base×level×tier-mult`) bold 11px + "DMG" 9px. **Pure:** effect count/cast (1@L1, 2@L2…) + keyword label below (BURN/SHOCK). Reactive/passive pure w/ no status application: **TBD — deferred to design review.** |
| 10 | Trigger label | 10px bold UPPERCASE, `#8fd3ff`. "ON FIRE"(on_activate) / "EVERY 2 ACT."(on_activate every_n) / "EVERY 5s"(periodic — only 3 elements still use it) / "COMBAT START" / "REACTIVE"(on_*) / "PASSIVE". `AbilityData.trigger_label()` is the source. |
| 11 | Ability text | 10px reg, max 2 lines, ellipsis. `#c8caf2`. Keywords `#8fd3ff` no underline. Potency reflects current level. Godot: `RichTextLabel` `[url=burn]` → TooltipCard. |
| 12 | Price badge | Bottom-right. Gold `#ebcf73`, dark pill, 11px bold. **Shop only.** |
| 13 | Charge bar | 6px top strip, fills L→R toward fire. Blue `#4da6ff` 0–84% → white `#ffffff` ≥85%. **Battle only.** |

## Level glow
| Lv | Border bright | Glow spread | Alpha |
|---|---|---|---|
| L1 | base | — | — |
| L2 | +25% | 9px | 0.35 |
| L3 | +50% | 16px | 0.60 |
Glow color = tier border color @ alpha.

## Color tokens (★ = new, not in ThemeData.gd)
| Const | Hex | Role |
|---|---|---|
| `TIER_1_BG` | `#193821` | T1 bg |
| `TIER_1_BORDER` | `#73cc73` | T1 border (L1) |
| `TIER_2_BG` | `#172940` | T2 bg |
| `TIER_2_BORDER` | `#5999fa` | T2 border |
| `TIER_3_BG` | `#2e1a47` | T3 bg |
| `TIER_3_BORDER` | `#b86bff` | T3 border |
| `TIER_4_BG` | `#3d2b0a` | T4 bg |
| `TIER_4_BORDER` | `#fabd33` | T4 border |
| `BATTLE_PROGRESS_BG` | `#140f1a` | charge tray |
| `BATTLE_PROGRESS_FILL` | `#4da6ff` | charge 0–84% |
| `CARD_CHARGE_FIRE_FILL` ★ | `#ffffff` | charge ≥85% |
| `COLOR_COMP_TRIGGER` | `#8fd3ff` | trigger + keyword |
| `COLOR_COMP_ABILITY` | `#c8caf2` | ability body |
| `CARD_TIER_BADGE_BG` ★ | `rgba(0,0,0,.50)` | tier pill |
| `CARD_PRICE_COLOR` ★ | `#ebcf73` | price gold |
| `CARD_PRICE_BADGE_BG` ★ | `rgba(0,0,0,.55)` | price pill |
| `SLOT_BG_EMPTY` | `#1a1a24` | empty slot bg |
| `SLOT_BORDER_EMPTY` | `#474758` | empty slot border |
| `PAGE_BG` | `#0a0c18` | page bg |
| `TEXT_PRIMARY` | `#e8eaf4` | name, stat values |
| `TEXT_DIM` | `#9a9cb8` | stat labels, secondary |

## Font tokens (★ = new, not in UIScale.gd)
| Const | px | Role |
|---|---|---|
| `SLOT_EMOJI` | 46 | emoji |
| `SLOT_NAME` | 13 | name |
| `CARD_STAT` ★ | 11 | stat value bold |
| `CARD_STAT_LABEL` ★ | 9 | stat label |
| `CARD_TRIGGER` ★ | 10 | trigger bold uppercase |
| `CARD_ABILITY` ★ | 10 | ability text |
| `CARD_TIER_BADGE` ★ | 10 | tier badge bold |
| `CARD_PRICE` ★ | 11 | price bold |

## Geometry
W 130px (`--card-w`, parameterized) · H 195px fixed · radius 4px · border 2px · charge bar 6px full-width top · padding 7 sides / 8 top / 28 bottom (reserves price) · separator 1px `rgba(255,255,255,.08)`.

## States
| State | Treatment |
|---|---|
| Default | tier bg + border |
| L2 | border +25% + soft glow |
| L3 | border +50% + strong glow |
| Hover (shop/inv) | `brightness(1.10)` |
| Unaffordable | `brightness(.55) saturate(.45)` |
| Frozen (battle) | `brightness(.65) saturate(.35) hue-rotate(155deg)` + ❄ ~38px centered |
| Charging 0–84% | blue bar |
| Charging ≥85% | white bar |
| Empty slot | `SLOT_BG_EMPTY` + `SLOT_BORDER_EMPTY` + "＋" centered |

## Examples (real data, Eff.Dmg @ L1)
**T1 — all pure-effect (CD left + effect right)**
| Elem | Emoji | CD | Count L1 | Label | Trigger | Text L1 |
|---|---|---|---|---|---|---|
| Fire | 🔥 | 2.5s | 1 | BURN | ON FIRE | Apply 1 [burn] to opponent. |
| Water | 💧 | 3.0s | 1 | CLEANSE | ON FIRE | Apply 1 [cleanse] to your side. |
| Lightning | ⚡ | 1.8s | 1 | SHOCK | ON FIRE | Apply 1 [shock] to opponent. |
| Metal | ⚙️ | 5.0s | 1 | PLATING | ON FIRE | Apply 1 [plating] to your side. |
| Frost | 🌨️ | 3.0s | 1 | WEAKEN | ON FIRE | Apply 1 [weaken] to opponent. |

**T2 — mixed** (refreshed 2026-06-12)
| Elem | Emoji | Type | CD | Dmg | Trigger | Text |
|---|---|---|---|---|---|---|
| Steam | ♨️ | pure | 3.5s | — | REACTIVE | When [burn] applied, deal 1 bonus dmg. |
| Rain | 🌧️ | pure | 3.0s | — | ON FIRE | Each activation washes your side: apply 1 [cleanse]. |
| Lava | 🟠 | dealer | 5.0s | 5 | EVERY 6s | Apply 2 [burn] to opponent. |
| Boulder | ⛰️ | dealer | 6.0s | 6 | COMBAT START | Apply 4 [armor] to your side. |
| Molten | 🔶 | dealer | 5.0s | 5 | EVERY 2 ACT. | Prime next [burn] tick +2, gain 1 [plating]. |

**T3 — mixed** (refreshed 2026-06-12)
| Elem | Emoji | Type | CD | Dmg | Trigger | Text |
|---|---|---|---|---|---|---|
| Inferno | 🪔 | pure | 2.5s | — | REACTIVE | [burn] ticks: 50% chance to reignite, +1 [burn]. |
| Mountain | ⛰ | dealer | 7.0s | 13 | PASSIVE | Your [armor] cannot drop below 2 stacks. |
| Glacier | 🗻 | dealer | 7.0s | 10 | COMBAT START | [freeze] two opponent elements for 5s. |

**T4 — mixed (8 dealers, 2 pure; abilities designed 2026-06-12)**
| Elem | Emoji | Type | CD | Dmg | Trigger | Text |
|---|---|---|---|---|---|---|
| Maelstrom | 🌀 | dealer | 3.0s | 18 | ON FIRE ×3 | Strikes 3× per cooldown: 1 [shock] + 1 [weaken] each pass. |
| Supernova | ⭐ | dealer | 5.0s | 25 | EVERY 3 ACT. | Detonate: 10 dmg + 3 [burn] + 2 [blind]. |
| Pandemic | 🧬 | pure | 4.0s | — | REACTIVE | Every [poison] tick spreads: +1 [poison]. |

> New ability vocabulary since 2026-06-12 — 🎯 primers (next-tick/next-hit), ⚔️ adjacency auras, ❤️ max-HP — falls under the same "right stat TBD for non-applying abilities" review as item 9.

## Mockup sections to produce
1. **Four tiers, L1, inventory** — Fire T1, Steam T2, Inferno T3, Maelstrom T4 (pure). No price/charge. Shows [6][7][9][10][11].
2. **Archetype split (most important)** — Fire 🔥 T1 pure (CD 2.5s + count 1/BURN, "Apply 1 [burn]") vs Lava 🟠 T2 dealer (CD 5.0s + DMG 5, "Every 6s · Apply 2 [burn]"). Layout diff must be obvious.
3. **Level luminosity** — Fire T1 L1→L2→L3 (text: Apply 1/2/3 [burn]; glow none/soft/strong). + Maelstrom T4 L3 (gold glow, dealer).
4. **All states** — Steam T2 L1 row: shop / shop-unaffordable / inventory / battle 65% / battle 90%+ / frozen / empty.
5. **Token reference** — full table grouped: tier fills, borders, glow, charge, text, badges, geometry. Mark ★.

## Constraints — do NOT
- Omit inner art box (SVG primary, emoji fallback).
- Per-element accent colors — tier-based only.
- Show DMG on pure-effect (absent, never "0").
- Add items 14 (effect icon) / 15 (made-from) — deferred.
- Old eff.dmg formulas `base×level+tier` / plain `base×level` — current: `base × level × tier multiplier` (TuningData.TIER_POTENCY_MULTIPLIER, 2026-06-12).
- Radius >4px.
- Layout not expressible as vertical stack.
- Hover animations — static mockup.
- Design the Battlegrid — card is sole scope.
