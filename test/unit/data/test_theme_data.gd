extends GutTest


# ── family colours (ADR-0017: hue = Canonical Family) ─────────────────────────

const FAMILIES: Array[String] = [
	"fire", "water", "earth", "air", "lightning", "nature",
	"light", "dark", "metal", "fungus", "blood", "frost",
]


func test_family_color_map_covers_all_12_base_families() -> void:
	for fam: String in FAMILIES:
		assert_true(ThemeData.FAMILY_COLOR.has(fam), "FAMILY_COLOR missing '" + fam + "'")
	assert_eq(ThemeData.FAMILY_COLOR.size(), 12, "exactly 12 base families expected")


func test_family_color_accessor_returns_mapped_color() -> void:
	for fam: String in FAMILIES:
		assert_eq(ThemeData.family_color(fam), ThemeData.FAMILY_COLOR[fam] as Color,
			"family_color('" + fam + "') must equal the map entry")


func test_family_color_unknown_returns_a_color_not_a_crash() -> void:
	var c: Color = ThemeData.family_color("not_a_family")
	assert_true(c is Color, "unknown family must fall back to a Color, never error")
