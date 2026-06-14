class_name ThemeData

# ──────────────────────────────────────────────────────────────────────────────
# ThemeData — single source of truth for all visual style constants.
# Change colors here; they propagate everywhere automatically.
# ──────────────────────────────────────────────────────────────────────────────

# ── Scene backgrounds ─────────────────────────────────────────────────────────
const BG_MAIN_MENU  := Color(0.05, 0.03, 0.11, 1.0)  # cosmic void / deep indigo
const BG_SHOP       := Color(0.06, 0.07, 0.12, 1.0)  # dark navy merchant hall
const BG_BATTLE     := Color(0.09, 0.04, 0.07, 1.0)  # dark crimson war chamber
const BG_COMPENDIUM := Color(0.04, 0.09, 0.12, 1.0)  # dark teal arcane library

# ── Area panel tints ──────────────────────────────────────────────────────────
const FORGE_PANEL_BG     := Color(0.10, 0.05, 0.18, 1.0)  # alchemical purple
const FORGE_PANEL_BORDER := Color(0.50, 0.20, 0.80, 0.55)

# Shop left-panel section backgrounds (subtle — just enough to separate areas)
const SHOP_FORSALE_BG      := Color(0.10, 0.08, 0.05, 0.70)  # warm amber — for-sale
const SHOP_FORSALE_BORDER  := Color(0.42, 0.30, 0.10, 0.45)
const SHOP_INVENTORY_BG    := Color(0.05, 0.09, 0.16, 0.68)  # cool blue — inventory
const SHOP_INVENTORY_BORDER:= Color(0.20, 0.30, 0.52, 0.42)
const SHOP_BATTLEGRID_BG   := Color(0.13, 0.08, 0.04, 0.68)  # warm red-amber — fighters
const SHOP_BATTLEGRID_BORDER:= Color(0.48, 0.28, 0.08, 0.42)

# ── Item tier colors ──────────────────────────────────────────────────────────
# Backgrounds are saturated enough to read the tier at a glance (the old near-black
# fills all looked identical); borders stay bright for the accent.
const TIER_1_BG     := Color(0.10, 0.22, 0.13, 0.97)  # common — green
const TIER_1_BORDER := Color(0.45, 0.80, 0.45, 0.95)
const TIER_2_BG     := Color(0.09, 0.16, 0.30, 0.97)  # uncommon — blue
const TIER_2_BORDER := Color(0.35, 0.60, 0.98, 0.95)
const TIER_3_BG     := Color(0.18, 0.10, 0.28, 0.97)  # epic — purple
const TIER_3_BORDER := Color(0.72, 0.42, 1.00, 0.95)
const TIER_4_BG     := Color(0.24, 0.17, 0.04, 0.97)  # legendary — gold
const TIER_4_BORDER := Color(0.98, 0.74, 0.20, 0.95)

# ── Family colours (ADR-0017) ─────────────────────────────────────────────────
# Hue = an element's Canonical Family (its identity), independent of Tier. The 12
# base families; forged elements borrow one of these via ElementData.canonical_family.
const FAMILY_COLOR: Dictionary = {
	"fire":      Color(0.941, 0.439, 0.125),  # 240,112,32
	"water":     Color(0.184, 0.624, 0.847),  # 47,159,216
	"earth":     Color(0.612, 0.478, 0.275),  # 156,122,70
	"air":       Color(0.737, 0.816, 0.878),  # 188,208,224
	"lightning": Color(0.957, 0.824, 0.235),  # 244,210,60
	"nature":    Color(0.361, 0.761, 0.290),  # 92,194,74
	"light":     Color(1.000, 0.878, 0.541),  # 255,224,138
	"dark":      Color(0.478, 0.357, 0.690),  # 122,91,176
	"metal":     Color(0.604, 0.643, 0.706),  # 154,164,180
	"fungus":    Color(0.690, 0.380, 0.878),  # 176,97,224
	"blood":     Color(0.784, 0.188, 0.227),  # 200,48,58
	"frost":     Color(0.498, 0.816, 0.910),  # 127,208,232
}
const FAMILY_COLOR_FALLBACK := Color(0.60, 0.60, 0.66)  # untagged element → neutral

# ── Tier frame metals (ADR-0017) ──────────────────────────────────────────────
# Tier = the Element Card's frame MATERIAL, never a background fill. Bronze → silver
# → gold → prismatic. T4 has no flat metal: its border is FRAME_PRISMATIC_STOPS baked
# into a conic gradient (StyleBoxTexture). Independent of Hue (Family) and Level (glow).
const FRAME_METAL_T1 := Color(0.659, 0.439, 0.235)  # #a8703c bronze
const FRAME_METAL_T2 := Color(0.706, 0.729, 0.776)  # #b4bac6 silver
const FRAME_METAL_T3 := Color(0.863, 0.714, 0.325)  # #dcb653 gold
const FRAME_PRISMATIC_STOPS: Array[Color] = [
	Color(1.000, 0.353, 0.235),  # #ff5a3c
	Color(1.000, 0.824, 0.235),  # #ffd23c
	Color(0.353, 0.824, 0.298),  # #5ad24c
	Color(0.235, 0.784, 1.000),  # #3cc8ff
	Color(0.608, 0.353, 0.871),  # #9b5ade
	Color(1.000, 0.353, 0.235),  # #ff5a3c (loop close)
]

# ── Level glow ramp (ADR-0017, static v1) ─────────────────────────────────────
# Level = portrait glow intensity, never a number on the frame. Glow radius (px) +
# brightness multiplier per level; clamped 1–3 (animations deferred — "card animations").
const LEVEL_GLOW_PX: Dictionary = { 1: 3, 2: 13, 3: 24 }
const LEVEL_BRIGHT: Dictionary = { 1: 1.24, 2: 1.46, 3: 1.72 }

# ── Scene frame system (beveled "hardware" panels — see ScenePanel) ────────────
# Every area panel is a thick raised-metal frame (one top-left light source) + a
# stepped inner accent line, near-black interior. Accent is per-area (frame only).
const FRAME_THICKNESS: int    = 5      # px border band (native 1920×1080)
const FRAME_RADIUS: int       = 11
const FRAME_STEP_GAP: int     = 4      # inset of the stepped inner line past the border
const FRAME_STEP_ALPHA: float = 0.22   # inner accent line opacity
const FRAME_BEVEL_LIGHT: float = 0.35  # accent.lightened() for the top/left edge
const FRAME_BEVEL_DARK: float  = 0.45  # accent.darkened()  for the bottom/right edge
const PANEL_INTERIOR := Color(0.050, 0.035, 0.030, 1.0)  # near-black; matches the card interior

# Per-area accents (frame colour only — interiors stay PANEL_INTERIOR). Shop is a warm
# amber, NOT tier gold: gold stays the T3/T4 card signal + the FIGHT chip, so axes don't leak.
const AREA_SHOP      := Color(0.851, 0.620, 0.220)  # #d99e38 amber
const AREA_INVENTORY := Color(0.353, 0.608, 0.847)  # #5a9bd8 blue
const AREA_BATTLE    := Color(0.847, 0.392, 0.235)  # #d8643c red-orange
const AREA_FORGE     := Color(0.651, 0.310, 0.878)  # #a64fe0 purple

# FIGHT call-to-action gold — the only gold UI chrome (so the eye always finds it).
const FIGHT_BG   := Color(0.910, 0.604, 0.196)
const FIGHT_RIM  := Color(1.000, 0.902, 0.659)
const FIGHT_TEXT := Color(0.227, 0.141, 0.000)

# ── Slot / tile empty state ───────────────────────────────────────────────────
const SLOT_BG_EMPTY     := Color(0.10, 0.10, 0.14, 0.85)
const SLOT_BORDER_EMPTY := Color(0.28, 0.28, 0.36, 0.65)

# ── Battle slot ───────────────────────────────────────────────────────────────
const BATTLE_SLOT_BG_EMPTY     := Color(0.10, 0.06, 0.08, 0.80)
const BATTLE_SLOT_BORDER_EMPTY := Color(0.30, 0.18, 0.24, 0.65)
const BATTLE_PROGRESS_BG       := Color(0.08, 0.06, 0.10, 0.80)
const BATTLE_PROGRESS_FILL     := Color(0.30, 0.65, 1.00, 0.90)

# ── HP bars (battle screen) ───────────────────────────────────────────────────
const HP_BAR_FILL   := Color(0.85, 0.15, 0.15, 1.00)  # red health fill
const HP_BAR_BG     := Color(0.07, 0.03, 0.03, 1.00)  # near-black tray
const HP_BAR_BORDER := Color(0.50, 0.18, 0.18, 0.90)  # dark-red border

# ── Forge slot ────────────────────────────────────────────────────────────────
# Empty forge slots use the neutral empty-slot look; once an item is dropped the
# slot shows that item's tier color (see ForgeSlot.set_item), so the purple is gone.
const FORGE_SLOT_BG     := Color(0.12, 0.06, 0.22, 0.95)
const FORGE_SLOT_BORDER := Color(0.65, 0.28, 0.95, 0.92)

# ── Forge button (red action button — distinct from tier/forge purples) ─────────
const FORGE_BUTTON_BG          := Color(0.55, 0.13, 0.13, 1.0)
const FORGE_BUTTON_BG_HOVER    := Color(0.70, 0.18, 0.18, 1.0)
const FORGE_BUTTON_BG_DISABLED := Color(0.22, 0.12, 0.12, 0.85)
const FORGE_BUTTON_BORDER      := Color(0.92, 0.36, 0.32, 0.95)

# ── Sell zone (drag-to-sell drop target, overlaps FOR SALE section) ──────────
const SELL_BG           := Color(0.10, 0.08, 0.05, 0.70)  # matches SHOP_FORSALE_BG
const SELL_BORDER       := Color(0.38, 0.28, 0.10, 0.50)
const SELL_HOVER_BG     := Color(0.07, 0.24, 0.10, 0.75)
const SELL_HOVER_BORDER := Color(0.18, 0.92, 0.28, 0.92)

# ── Sold tile ─────────────────────────────────────────────────────────────────
const SOLD_TILE_BG     := Color(0.07, 0.07, 0.10, 0.70)
const SOLD_TILE_BORDER := Color(0.20, 0.20, 0.27, 0.50)

# ── Label / heading accents ───────────────────────────────────────────────────
const COLOR_TITLE            := Color(0.75, 0.55, 1.00)  # main menu title
const COLOR_SUBTITLE         := Color(0.50, 0.38, 0.68)  # dim purple sub-text
const COLOR_HEADER_SHOP      := Color(0.55, 0.80, 1.00)  # FOR SALE
const COLOR_HEADER_INVENTORY := Color(0.50, 0.88, 0.62)  # INVENTORY
const COLOR_HEADER_GRID      := Color(1.00, 0.65, 0.32)  # BATTLE GRID
const COLOR_HEADER_FORGE     := Color(0.82, 0.48, 1.00)  # FORGE BENCH
const COLOR_HEADER_BATTLE    := Color(1.00, 0.42, 0.45)  # BATTLE header
const COLOR_PLAYER_SIDE      := Color(0.38, 0.92, 0.55)  # YOU
const COLOR_OPP_SIDE         := Color(1.00, 0.38, 0.38)  # OPPONENT
const COLOR_ROUND_LABEL      := Color(0.78, 0.78, 1.00)  # round / timer text
const COLOR_COMP_HEADER_T1   := Color(0.45, 0.72, 0.45)  # compendium tier 1 — green
const COLOR_COMP_HEADER_T2   := Color(0.40, 0.60, 0.95)  # compendium tier 2 — blue
const COLOR_COMP_HEADER_T3   := Color(0.78, 0.50, 1.00)  # compendium tier 3 — epic purple
const COLOR_COMP_HEADER_T4   := Color(0.95, 0.72, 0.20)  # compendium tier 4 — legendary gold
const COLOR_COMP_TRIGGER     := Color(0.55, 0.85, 0.95)  # compendium ability trigger line
const COLOR_COMP_ABILITY     := Color(0.78, 0.82, 0.95)  # compendium ability description


# ── Status Tray (in-combat) ───────────────────────────────────────────────────
const STATUS_BUFF_TINT   := Color(0.55, 0.95, 0.62)   # buffs — green
const STATUS_DEBUFF_TINT := Color(1.00, 0.52, 0.45)   # debuffs — red
const STATUS_COUNT_TINT  := Color(0.96, 0.96, 1.00)   # the stack-count badge text
# Status Readout (the framed hover popup)
const STATUS_READOUT_BG     := Color(0.08, 0.08, 0.13, 0.98)
const STATUS_READOUT_BORDER := Color(0.55, 0.55, 0.72, 0.95)
const STATUS_READOUT_TEXT   := Color(0.90, 0.92, 1.00)


# ── Floating combat labels (Battle) ───────────────────────────────────────────
# Generic popups + the per-effect status-label colors. Effect labels are keyed by
# effect id (the text + emoji come from EffectRegistry.float_label).
const FLOAT_DAMAGE := Color(1.00, 0.35, 0.35, 1.0)  # "-N" damage popup
const FLOAT_MISS   := Color(0.55, 0.55, 0.55, 0.9)  # "MISS"
const FLOAT_HEAL   := Color(0.30, 1.00, 0.55)       # heal / leech "+N HP"
const FLOAT_LABEL_COLORS: Dictionary = {
	"burn":    Color(1.00, 0.55, 0.15),
	"poison":  Color(0.55, 0.92, 0.28),
	"shock":   Color(0.50, 0.80, 1.00),
	"blind":   Color(0.75, 0.75, 0.75),
	"curse":   Color(0.75, 0.32, 1.00),
	"weaken":  Color(0.38, 0.80, 0.80),
	"armor":   Color(0.72, 0.72, 0.72),
	"plating": Color(0.60, 0.65, 0.72),
	"cleanse": Color(0.92, 0.92, 0.45),
	"haste":   Color(0.55, 0.92, 0.92),
}


# ── Contribution Bars (live, in-combat) ───────────────────────────────────────
# Per-Contribution-type segment colours; CONTRIB_SEGMENT_ORDER fixes the stacking
# order so bars read consistently. Player-spec palette: damage red, poison purple,
# burn orange, heal green, Damage Blocked blue.
const CONTRIB_SEGMENT_ORDER: Array = ["direct", "poison", "burn", "heal", "blocked"]
const CONTRIB_COLORS: Dictionary = {
	"direct":  Color(0.95, 0.27, 0.27),   # red — direct hit damage
	"poison":  Color(0.70, 0.32, 0.95),   # purple — poison DOT
	"burn":    Color(1.00, 0.55, 0.15),   # orange — burn DOT
	"heal":    Color(0.30, 0.90, 0.45),   # green — healing
	"blocked": Color(0.30, 0.62, 1.00),   # blue — Damage Blocked
}
const CONTRIB_BAR_BG     := Color(0.10, 0.07, 0.14, 0.92)
const CONTRIB_BAR_BORDER := Color(0.32, 0.24, 0.46, 0.9)
const CONTRIB_PANEL_BG   := Color(0.07, 0.05, 0.11, 0.85)


# ── Event overlay (ADR 0011) ──────────────────────────────────────────────────
const EVENT_DIMMER             := Color(0.0, 0.0, 0.0, 0.7)
const EVENT_PANEL_BG           := Color(0.08, 0.08, 0.13, 0.98)
const EVENT_PANEL_BORDER       := Color(0.55, 0.45, 0.85, 0.9)
const EVENT_TITLE_COLOR        := Color(0.92, 0.82, 0.45)   # warm gold — "reward"
const EVENT_REWARD_BG          := Color(0.12, 0.13, 0.20, 1.0)
const EVENT_REWARD_BG_HOVER    := Color(0.19, 0.21, 0.32, 1.0)
const EVENT_REWARD_BORDER      := Color(0.55, 0.50, 0.85, 0.9)
const EVENT_REWARD_LABEL_COLOR := Color(0.96, 0.93, 0.72)
const EVENT_REWARD_DESC_COLOR  := Color(0.74, 0.77, 0.90)


static func tier_bg(tier: int) -> Color:
	match tier:
		1: return TIER_1_BG
		2: return TIER_2_BG
		3: return TIER_3_BG
		4: return TIER_4_BG
		_: return TIER_1_BG


static func tier_border(tier: int) -> Color:
	match tier:
		1: return TIER_1_BORDER
		2: return TIER_2_BORDER
		3: return TIER_3_BORDER
		4: return TIER_4_BORDER
		_: return TIER_1_BORDER


static func comp_tier_color(tier: int) -> Color:
	match tier:
		1: return COLOR_COMP_HEADER_T1
		2: return COLOR_COMP_HEADER_T2
		3: return COLOR_COMP_HEADER_T3
		4: return COLOR_COMP_HEADER_T4
		_: return COLOR_COMP_HEADER_T1


# Hue for a single named family. Unknown names fall back to neutral.
static func family_color(family: String) -> Color:
	return FAMILY_COLOR.get(family, FAMILY_COLOR_FALLBACK) as Color


# Weighted-average hue from a root_family_weights dict (ElementData). A single
# T1 element gives its exact color. A dual-parent T2 gives 50/50. A T3 with two
# water-lineage parents and one frost-lineage parent gives 2/3 water + 1/3 frost.
# Empty weights dict → FAMILY_COLOR_FALLBACK.
static func blended_family_color(weights: Dictionary) -> Color:
	if weights.is_empty():
		return FAMILY_COLOR_FALLBACK
	var total: int = 0
	for key: String in weights:
		total += weights[key] as int
	var result: Color = Color(0.0, 0.0, 0.0, 0.0)
	for family: String in weights:
		var c: Color = family_color(family)
		var w: float = float(weights[family] as int) / float(total)
		result.r += c.r * w
		result.g += c.g * w
		result.b += c.b * w
	result.a = 1.0
	return result


# Frame metal for a tier (ADR-0017). T4 has no flat metal — it uses the prismatic
# gradient; gold is returned as a safe fallback for any non-prismatic T4 usage.
static func frame_metal(tier: int) -> Color:
	match tier:
		1: return FRAME_METAL_T1
		2: return FRAME_METAL_T2
		3: return FRAME_METAL_T3
		_: return FRAME_METAL_T3


# Level glow radius (px) and brightness multiplier (ADR-0017). Levels above 3 clamp
# to the L3 ramp (static v1; per-level animation is the deferred "card animations").
static func level_glow_px(level: int) -> int:
	return LEVEL_GLOW_PX.get(clampi(level, 1, 3), 3) as int


static func level_bright(level: int) -> float:
	return LEVEL_BRIGHT.get(clampi(level, 1, 3), 1.24) as float
