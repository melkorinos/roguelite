class_name UIScale

# ── Tile emojis ───────────────────────────────────────────────────────────────
const SHOP_EMOJI  := 50
const SLOT_EMOJI  := 40
const FORGE_EMOJI := 38
const COMP_EMOJI  := 60

# ── Tile labels ───────────────────────────────────────────────────────────────
const SHOP_LABEL  := 14
const SLOT_NAME   := 11
const INV_SLOT    := 22
const SELL_HINT   := 20
const SOLD_LABEL  := 16

# ── Drag previews ─────────────────────────────────────────────────────────────
const DRAG_SHOP   := 48
const DRAG_SLOT   := 44

# ── Compendium ────────────────────────────────────────────────────────────────
const COMP_HEADER       := 25
const COMP_NAME         := 15
const COMP_STATS        := 13
const COMP_RECIPE_EMOJI := 22  # ingredient emojis in recipe row
const COMP_RECIPE       := 11  # ingredient names below emojis

# ── Battle summary ────────────────────────────────────────────────────────────
const SUMMARY_HEADER := 16
const SUMMARY_ROW    := 14
const SUMMARY_EMPTY  := 13

# ── Tooltip card ──────────────────────────────────────────────────────────────
const TOOLTIP_TITLE   := 17
const TOOLTIP_STAT    := 14
const TOOLTIP_SECTION := 12
const TOOLTIP_BODY    := 13


static func apply(node: Control, size: int) -> void:
	node.add_theme_font_size_override("font_size", size)
