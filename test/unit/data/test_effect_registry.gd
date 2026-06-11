extends GutTest

# EffectRegistry is the single source for per-effect metadata. float_label() is the
# one place the floating combat popup text is composed, sharing the Tray's emoji.

func test_float_label_composes_emoji_and_label() -> void:
	var fx: Dictionary = EffectRegistry.float_label("burn")
	assert_eq(fx["text"], "🔥 BURN")
	assert_eq(fx["nudge"], -4.0)


func test_float_label_uses_the_registry_emoji_no_drift() -> void:
	# The popup must use the same emoji the Status Tray shows for this effect.
	var fx: Dictionary = EffectRegistry.float_label("blind")
	assert_true((fx["text"] as String).begins_with(EffectRegistry.EFFECTS["blind"]["emoji"] as String))


func test_float_label_empty_for_amount_only_and_unknown_effects() -> void:
	# heal/leech show an HP-gain amount (built at the call site), not a status popup.
	assert_true(EffectRegistry.float_label("heal").is_empty())
	assert_true(EffectRegistry.float_label("leech").is_empty())
	# slow has no popup; unknown effects return {}.
	assert_true(EffectRegistry.float_label("slow").is_empty())
	assert_true(EffectRegistry.float_label("nonexistent").is_empty())


func test_every_floatable_effect_has_a_color() -> void:
	# Each effect with a float popup must have a ThemeData color so it never renders white.
	for effect_key: Variant in EffectRegistry.EFFECTS:
		if (EffectRegistry.EFFECTS[effect_key] as Dictionary).has("float"):
			assert_true(ThemeData.FLOAT_LABEL_COLORS.has(effect_key), "missing float color: " + (effect_key as String))
