class_name LayoutData

# Spatial layout knobs — card footprints per context + screen splits. The sibling of
# UIScale (font sizes), ThemeData (colors), and TuningData (balance): one home for the
# pixel/ratio values that were previously dug into individual slot scripts and scenes.
#
# Card widths are per *context* on purpose — the same Element Card reads at a different
# size in the shop vs the battle board vs the compendium. Height follows width via
# CARD_HEIGHT_RATIO (the ElementCard aspect). ElementCard reads the ratio from here so
# there is a single source of truth for the card aspect.

# ── Card aspect ───────────────────────────────────────────────────────────────
const CARD_HEIGHT_RATIO: float = 1.45   # card height = width × this

# ── Card widths per context (px, native 1920×1080) ────────────────────────────
const CARD_SHOP: int        = 170   # FOR SALE tiles (5-across the left column)
const CARD_INVENTORY: int   = 170   # inventory slots (3-across, kept equal to shop)
const CARD_BATTLE: int      = 180   # battle slots — SHARED with the Battle scene (see note)
const CARD_FORGE: int       = 150   # forge bench slots — full ElementCards, like every other context
const CARD_COMPENDIUM: int  = 160   # compendium grid cards
const CARD_PREVIEW: int     = 190   # floating ElementCard preview (forge-path chip hover, CardPreview)

# NOTE: CARD_BATTLE drives BattleSlot, which the Battle arena also uses. The Battle
# scene art has not been redesigned yet — revisit / split this if the arena needs a
# different footprint than the shop's planning board.

# ── Shop screen split (column stretch ratios, applied by Shop.gd) ─────────────
const SHOP_SPLIT_LEFT: float  = 50.0   # FOR SALE / INVENTORY column
const SHOP_SPLIT_RIGHT: float = 50.0   # BATTLE BOARD / FORGE column

# ── Spacing rhythm — shared across every screen for one consistent feel ───────
# The standard the theme rollout (MainMenu / Settings / Compendium / Battle) reuses;
# applied in code (theme_constant_overrides) so there is a single source, not per-.tscn
# magic numbers. ScenePanel reads PANEL_INNER_*; scenes read the gaps.
const COLUMN_GAP: int      = 20   # between major columns of a screen
const PANEL_GAP: int       = 12   # between stacked framed panels in a column
const GRID_CELL_GAP: int   = 8    # between cards within a grid
const PANEL_INNER_PAD: int = 8    # ScenePanel content inset past the frame band
const PANEL_INNER_GAP: int = 8    # ScenePanel internal separation (header / body)


# Card minimum size for a given width, honoring the card aspect. Use for non-ElementCard
# placeholders (e.g. the shop's SOLD tile) that must match a card's footprint.
static func card_min_size(width: int) -> Vector2:
	return Vector2(width, roundi(width * CARD_HEIGHT_RATIO))
