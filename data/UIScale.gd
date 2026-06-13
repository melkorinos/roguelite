class_name UIScale

# ── Tile emojis ───────────────────────────────────────────────────────────────
const SHOP_EMOJI  := 65
const SLOT_EMOJI  := 52
const FORGE_EMOJI := 49
const COMP_EMOJI  := 60

# ── Tile labels ───────────────────────────────────────────────────────────────
const SHOP_LABEL  := 18
const SLOT_NAME   := 14
const INV_SLOT    := 29
const SELL_HINT   := 20
const SOLD_LABEL  := 16

# ── Buttons ───────────────────────────────────────────────────────────────────
const FORGE_BUTTON := 20

# ── Combat ────────────────────────────────────────────────────────────────────
const FLOAT_LABEL := 20  # floating combat damage / status numbers
const STATUS_CHIP  := 22  # in-combat Status Tray emoji chips
const STATUS_COUNT := 14  # the stack-count badge beside a chip emoji

# ── Drag previews ─────────────────────────────────────────────────────────────
const DRAG_SHOP   := 48
const DRAG_SLOT   := 44

# ── Compendium ────────────────────────────────────────────────────────────────
const COMP_HEADER       := 25
const COMP_NAME         := 15
const COMP_STATS        := 13
const COMP_RECIPE_EMOJI := 22  # ingredient emojis in recipe row
const COMP_RECIPE       := 11  # ingredient names below emojis
const COMP_ABILITY      := 11  # ability description text on a card
const COMP_TRIGGER      := 11  # ability trigger line on a card

# ── Battle summary ────────────────────────────────────────────────────────────
const SUMMARY_HEADER := 16
const SUMMARY_ROW    := 14
const SUMMARY_EMPTY  := 13

# ── Event overlay (ADR 0011) ──────────────────────────────────────────────────
const EVENT_TITLE        := 22
const EVENT_REWARD_LABEL := 18
const EVENT_REWARD_DESC  := 12

# ── Tooltip card ──────────────────────────────────────────────────────────────
const TOOLTIP_TITLE   := 17
const TOOLTIP_STAT    := 14
const TOOLTIP_SECTION := 12
const TOOLTIP_BODY    := 13

# ── Element Card (ADR-0017) ───────────────────────────────────────────────────
# Sizes authored at the CARD_REFERENCE_WIDTH (200px); the card scales them per its
# actual width via apply_scaled, so one component degrades gracefully across contexts.
const CARD_REFERENCE_WIDTH := 200
const CARD_EMOJI           := 50
const CARD_NAME            := 18
const CARD_POD_VALUE       := 18  # 2-pod default
const CARD_POD_VALUE_SOLO  := 20  # single CD pod
const CARD_POD_VALUE_TRIO  := 14  # 3-pod squeeze
const CARD_POD_LABEL       := 9
const CARD_POD_LABEL_TRIO  := 8
const CARD_ABILITY         := 10


static func apply(node: Control, size: int) -> void:
	node.add_theme_font_size_override("font_size", size)


# RichTextLabel reads "normal_font_size" rather than "font_size".
static func apply_rich(node: RichTextLabel, size: int) -> void:
	node.add_theme_font_size_override("normal_font_size", size)


# Element Card font sizing: a reference size scaled by the card's width factor.
static func apply_scaled(node: Control, base: int, scale: float) -> void:
	node.add_theme_font_size_override("font_size", maxi(6, int(round(float(base) * scale))))


static func apply_rich_scaled(node: RichTextLabel, base: int, scale: float) -> void:
	node.add_theme_font_size_override("normal_font_size", maxi(6, int(round(float(base) * scale))))
