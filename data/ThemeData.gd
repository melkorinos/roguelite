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
const TIER_1_BG     := Color(0.08, 0.11, 0.09, 0.97)  # common — dark green
const TIER_1_BORDER := Color(0.40, 0.65, 0.40, 0.90)
const TIER_2_BG     := Color(0.07, 0.09, 0.16, 0.97)  # uncommon — blue
const TIER_2_BORDER := Color(0.30, 0.52, 0.92, 0.90)
const TIER_3_BG     := Color(0.12, 0.09, 0.04, 0.97)  # rare — gold
const TIER_3_BORDER := Color(0.92, 0.68, 0.14, 0.90)

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
const FORGE_SLOT_BG     := Color(0.12, 0.06, 0.22, 0.95)
const FORGE_SLOT_BORDER := Color(0.65, 0.28, 0.95, 0.92)

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
const COLOR_COMP_HEADER_T1   := Color(0.45, 0.72, 0.45)  # compendium tier 1
const COLOR_COMP_HEADER_T2   := Color(0.40, 0.60, 0.95)  # compendium tier 2
const COLOR_COMP_HEADER_T3   := Color(0.92, 0.68, 0.18)  # compendium tier 3
const COLOR_COMP_TRIGGER     := Color(0.55, 0.85, 0.95)  # compendium ability trigger line
const COLOR_COMP_ABILITY     := Color(0.78, 0.82, 0.95)  # compendium ability description


static func tier_bg(tier: int) -> Color:
	match tier:
		1: return TIER_1_BG
		2: return TIER_2_BG
		3: return TIER_3_BG
		_: return TIER_1_BG


static func tier_border(tier: int) -> Color:
	match tier:
		1: return TIER_1_BORDER
		2: return TIER_2_BORDER
		3: return TIER_3_BORDER
		_: return TIER_1_BORDER


static func comp_tier_color(tier: int) -> Color:
	match tier:
		1: return COLOR_COMP_HEADER_T1
		2: return COLOR_COMP_HEADER_T2
		3: return COLOR_COMP_HEADER_T3
		_: return COLOR_COMP_HEADER_T1
