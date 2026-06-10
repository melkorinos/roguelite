# Claude Design Handoff — Element Card v1

**Date:** 2026-06-09  
**Task:** Design the Element Card UI tile for an auto-battler game.  
**Output:** A polished HTML/CSS mockup showing all card variants, plus a design token spec.

---

## Technical context

The game is built in **Godot 4 / GDScript**. The HTML/CSS mockup you produce is not deployed — it is a visual specification that a developer hand-translates into Godot scene nodes and GDScript. Because of this:

- **Token names must use SCREAMING_SNAKE_CASE** — they map directly to GDScript constants in `ThemeData.gd` (colors) and `UIScale.gd` (font sizes).
- **Font sizes are integer px values** — no `rem`, no `em`. Each size corresponds to one named constant in `UIScale.gd`.
- **Colors map to Godot `Color(r, g, b, a)`** — CSS hex equivalents are provided for you; use them in the mockup but label each with its `ThemeData` constant name.
- The card is a `PanelContainer` in Godot with a `VBoxContainer` body. The tier-colored background and border are a `StyleBoxFlat`. Keep the layout as a vertical stack — no CSS grid or flexbox tricks that can't be expressed as a VBox.

A working v1 mockup already exists — open it first:  
`e:\desktop\game\roguelite\.claude\ai-helper\design\element-card-20260609.html`

---

## What you are designing

The **Element Card** is the core UI tile of the game. It represents one element (a combat piece) and appears identically in three places: the shop for-sale row, the player's inventory, and the Battlegrid during combat. It is always fully visible — no hover required to read its content (this is a deliberate departure from the genre convention).

The card must work at **130 × 195 px** (portrait). The player typically sees 4–8 on screen at once.

---

## Aesthetic

**Clean, minimal, weird, surreal.** Not cute. Not grimdark.  
Think: uncanny objects with polished execution. Dark backgrounds. Tier colors are the primary vibrancy — everything else is restrained. The card should feel like a physical artifact with slight weight, not a flat chip. Emoji are intentional placeholder art — do not replace them with illustrations.

---

## Element archetypes — critical for card layout

There are two archetypes. The card layout differs between them.

### Pure-effect element
Fires a status effect on cooldown. **No direct damage.** The effect IS the contribution.  
**All 12 Tier 1 elements are pure-effect.**  
Most T2+ elements are also pure-effect.  
Stats row: **CD only** (DMG stat absent — not "0", just not shown).

### Damage-dealer element
Deals direct damage on cooldown, may also apply a status.  
22 elements across T2/T3/T4 (whitelist in `ElementData.DAMAGE_DEALERS`).  
Stats row: **CD + DMG** side by side.

**Damage-dealer whitelist for reference:**
- T2 (7): Lava 🟠, Boulder, Shrapnel 💥, Flint ⛏️, Molten 🔶, Steel, Gore ⚔️
- T3 (7): Volcano, Obsidian, Meteorite, Mountain 🏔️, Tsunami, Glacier, Carnage
- T4 (8): Ice Age, Maelstrom 🌪️, Tectonic, Supernova, Singularity, Ragnarök, Primordial, Aether

---

## Level scaling — affects ability text

Level now scales effect potency: a Level N element applies N stacks/points.  
- Fire at Level 1 → "Apply 1 [burn]"  
- Fire at Level 2 → "Apply 2 [burn]"  
- Fire at Level 3 → "Apply 3 [burn]"  

The ability text on the card reflects the current level count. In the mockup, show the correct count per level variant.

`effective_damage` formula (damage-dealers only): `base × multiplier × level`  
Pure-effect elements always have `effective_damage = 0` — that is why the DMG stat is hidden.

---

## Card anatomy — 13 items

```
┌─────────────────────────────┐  ← [13] Charge Bar strip (6px, battle only)
│                      [T2]   │  ← [6]  Tier badge, top-right
│                             │
│             ♨️               │  ← [4]  Emoji icon, ~46px, centered
│                             │
│            Steam            │  ← [5]  Element name, 13px
│                             │
│   PURE-EFFECT:   3.5s       │  ← [7]  CD centered alone
│                  CD         │
│                             │
│   DAMAGE-DEALER: 3.5s  5    │  ← [7]+[9] CD + DMG side by side
│                  CD   DMG   │
│  ───────────────────────    │  ← separator
│  REACTIVE                   │  ← [10] Trigger label
│  When [burn] is applied,    │  ← [11] Ability text, 2 lines max
│  deal 1 bonus damage.       │
│                      [8g]   │  ← [12] Price badge (shop only)
└─────────────────────────────┘
  [1] bg  [2] border  [3] level glow
```

| # | Item | Spec |
|---|------|------|
| 1 | **Background** | Tier-colored fill |
| 2 | **Border** | Tier accent color, 2px, 4px corner radius |
| 3 | **Level indicator** | Border brightness + outer glow. L1: no glow. L2: border +25%, soft glow. L3: border +50%, strong glow. No number label. |
| 4 | **Emoji icon** | ~46px, centered, top section |
| 5 | **Element name** | 13px, centered, single line, ellipsis on overflow |
| 6 | **Tier badge** | "T1"/"T2"/"T3"/"T4" · top-right · dark semi-transparent pill · 10px bold |
| 7 | **Cooldown** | Stat value + "CD" label below. Centered alone on pure-effect cards. Left of DMG on damage-dealers. |
| 8 | ~~Base Dmg~~ | **Excluded** |
| 9 | **Eff. Dmg** | `base × mult × level`. Right of CD. **Only shown on damage-dealer cards.** Hidden entirely on pure-effect. |
| 10 | **Trigger label** | Human label: "On Fire" · "Every 5s" · "Combat Start" · "Reactive" · "Passive". 10px · UPPERCASE · accent color |
| 11 | **Ability text** | Max 2 lines, clips. Keywords in accent color, no underline. Level count in text reflects current level (e.g. "Apply 2 [burn]" at L2). |
| 12 | **Price badge** | Bottom-right · gold text · dark pill · **shop context only** |
| 13 | **Charge Bar** | 6px strip pinned to very top of card · fills left→right · **battle context only** · shifts blue→white at ≥85% |

Items 14, 15 deferred.

---

## Color tokens

| Token name (GDScript) | CSS hex | Role |
|---|---|---|
| `TIER_1_BG` | `#193821` | T1 card fill |
| `TIER_1_BORDER` | `#73cc73` | T1 border at Level 1 |
| `TIER_2_BG` | `#172940` | T2 card fill |
| `TIER_2_BORDER` | `#5999fa` | T2 border at Level 1 |
| `TIER_3_BG` | `#2e1a47` | T3 card fill |
| `TIER_3_BORDER` | `#b86bff` | T3 border at Level 1 |
| `TIER_4_BG` | `#3d2b0a` | T4 card fill |
| `TIER_4_BORDER` | `#fabd33` | T4 border at Level 1 |
| `BATTLE_PROGRESS_FILL` | `#4da6ff` | Charge bar fill (blue phase) |
| `CARD_CHARGE_FIRE_FILL` ★ | `#ffffff` | Charge bar fill at ≥85% |
| `COLOR_COMP_TRIGGER` | `#8fd3ff` | Trigger label + keyword accent |
| `COLOR_COMP_ABILITY` | `#c8caf2` | Ability body text |
| `CARD_TIER_BADGE_BG` ★ | `rgba(0,0,0,0.50)` | Tier badge pill bg |
| `CARD_PRICE_COLOR` ★ | `#ebcf73` | Price badge gold text |
| `TEXT_PRIMARY` | `#e8eaf4` | Name, stat values |
| `TEXT_DIM` | `#9a9cb8` | Stat labels (CD, DMG) |
| `PAGE_BG` | `#0a0c18` | Scene background |

★ = new constant not yet in `ThemeData.gd` — add during implementation.

**Level glow (per tier border color):**

| Level | Border brightness | Glow spread | Glow alpha |
|---|---|---|---|
| L1 | base | none | — |
| L2 | +25% | 9px | 0.35 |
| L3 | +50% | 16px | 0.60 |

---

## Font sizes (UIScale.gd constants)

| Token name (GDScript) | Size | Role |
|---|---|---|
| `SLOT_EMOJI` | 46px | Element icon |
| `SLOT_NAME` | 13px | Element name |
| `CARD_STAT` ★ | 11px | Stat value (2.5s, 4) |
| `CARD_STAT_LABEL` ★ | 9px | Stat key (CD, DMG) |
| `CARD_TRIGGER` ★ | 10px | Trigger label |
| `CARD_ABILITY` ★ | 10px | Ability description |
| `CARD_TIER_BADGE` ★ | 10px | Tier badge text |
| `CARD_PRICE` ★ | 11px | Price badge text |

---

## Sections to produce

### Section 1 — All four tiers (Level 1, inventory context, pure-effect examples)

| Element | Emoji | Tier | CD | Ability |
|---|---|---|---|---|
| Fire | 🔥 | T1 | 2.5s | On Fire · Apply 1 [burn] to the opponent. |
| Steam | ♨️ | T2 | 3.5s | Reactive · When [burn] is applied, deal 1 bonus damage. |
| Inferno | 🌋 | T3 | 4.5s | Every 6s · Apply 3 [burn] + 1 [curse] to opponent. |
| Maelstrom | 🌪️ | T4 | 5.0s | Combat Start · — ability design pending — |

No price badge, no charge bar.

### Section 2 — Archetype split (pure-effect vs damage-dealer)

Show two cards side by side at Level 1:

| Element | Emoji | Tier | Type | Stats row | Ability |
|---|---|---|---|---|---|
| Fire | 🔥 | T1 | Pure-effect | CD only (2.5s) | On Fire · Apply 1 [burn] to the opponent. |
| Lava | 🟠 | T2 | Damage-dealer | CD (5.0s) + DMG | Every 6s · Apply 2 [burn] to the opponent. |

This is the most important section — the layout difference must be immediately obvious.

### Section 3 — Level luminosity (T1 Fire, L1 → L2 → L3)

Show the same pure-effect card at three levels. Note the ability text changes:
- L1: "Apply 1 [burn]"
- L2: "Apply 2 [burn]" + soft glow
- L3: "Apply 3 [burn]" + strong glow

Also show T4 Maelstrom (damage-dealer) at L3 for the gold glow.

### Section 4 — Three contexts (T2 Steam L1, pure-effect)

- **Shop:** price badge `8g` bottom-right
- **Shop unaffordable:** `filter: brightness(0.55) saturate(0.45)`
- **Inventory:** clean — no badge, no bar
- **Battle 65%:** charge bar at 65% (blue fill)
- **Battle ≥85%:** charge bar near full (white fill, about to fire)
- **Battle frozen:** desaturated + dimmed + ❄ emoji overlay
- **Empty slot:** neutral dark fill (`#1a1a24` / `#474758` border), "＋" centered

### Section 5 — Design token reference table

Full table of all color + font-size tokens with GDScript name, CSS value, and role. Mark ★ new constants clearly.

---

## Geometry

| Property | Value |
|---|---|
| Width | `130px` — CSS variable `--card-w` (parameterised; future grid growth tunes one variable) |
| Height | `195px` fixed — uniform across all cards and contexts |
| Corner radius | `4px` — intentionally sharp, fits the uncanny aesthetic |
| Border | `2px` solid |
| Charge bar | `6px` height, full width, top edge of card |

---

## Card states summary

| State | Visual treatment |
|---|---|
| Default | Tier bg + border |
| Level 2 | Border +25% brightness + soft outer glow |
| Level 3 | Border +50% brightness + strong outer glow |
| Hover (shop) | `filter: brightness(1.10)` on whole card |
| Unaffordable | `filter: brightness(0.55) saturate(0.45)` |
| Frozen (battle) | `filter: brightness(0.65) saturate(0.35) hue-rotate(155deg)` + ❄ overlay |
| Charge ≥85% | Charge bar fill shifts to white |
| Empty slot | `SLOT_BG_EMPTY` + `SLOT_BORDER_EMPTY`, "＋" glyph |

---

## What NOT to do

- Do not replace emojis with illustrations
- Do not add items 14 (effect icon) or 15 (made-from hint) — deferred
- Do not show DMG stat on pure-effect cards — hidden entirely, not shown as 0
- Do not use `+tier` in the eff. dmg formula — it has been removed (ADR 0013)
- Do not use corner radius > 4px
- Do not use layout techniques that can't be expressed as a Godot VBoxContainer stack
