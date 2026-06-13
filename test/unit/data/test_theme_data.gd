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


# ── tier frame metals (ADR-0017: tier = frame material) ───────────────────────

func test_frame_metal_is_distinct_per_tier() -> void:
	assert_eq(ThemeData.frame_metal(1), ThemeData.FRAME_METAL_T1)
	assert_eq(ThemeData.frame_metal(2), ThemeData.FRAME_METAL_T2)
	assert_eq(ThemeData.frame_metal(3), ThemeData.FRAME_METAL_T3)
	# bronze, silver, gold must read differently
	assert_ne(ThemeData.frame_metal(1), ThemeData.frame_metal(2))
	assert_ne(ThemeData.frame_metal(2), ThemeData.frame_metal(3))


func test_prismatic_stops_loop_closed() -> void:
	# A conic gradient needs the last stop to equal the first for a seamless wrap.
	var stops: Array[Color] = ThemeData.FRAME_PRISMATIC_STOPS
	assert_gt(stops.size(), 2)
	assert_eq(stops[0], stops[stops.size() - 1], "prismatic ring must close on its first colour")


# ── level glow ramp (ADR-0017: level = glow intensity) ────────────────────────

func test_level_glow_ramps_up_with_level() -> void:
	assert_lt(ThemeData.level_glow_px(1), ThemeData.level_glow_px(2))
	assert_lt(ThemeData.level_glow_px(2), ThemeData.level_glow_px(3))
	assert_lt(ThemeData.level_bright(1), ThemeData.level_bright(3))


func test_level_glow_clamps_above_three() -> void:
	# Levels can exceed 3 in play (forge/upgrades); the static v1 ramp tops out at L3.
	assert_eq(ThemeData.level_glow_px(7), ThemeData.level_glow_px(3))
	assert_eq(ThemeData.level_bright(7), ThemeData.level_bright(3))
	assert_eq(ThemeData.level_glow_px(0), ThemeData.level_glow_px(1))
