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


# ── modifier fields + side-wide schema ────────────────────────────────────────

func test_modifier_fields_excludes_count_and_ledger() -> void:
	# burn: count_field "stacks" and the by_source ledger are NOT author-writable
	# modifiers; tick_damage_bonus and next_tick_bonus are.
	var mods: Array[String] = EffectRegistry.modifier_fields("burn")
	assert_does_not_have(mods, "stacks", "the count field is owned by StatusSystem")
	assert_does_not_have(mods, "by_source", "the attribution ledger is internal")
	assert_has(mods, "tick_damage_bonus")
	assert_has(mods, "next_tick_bonus")


func test_is_modifier_field_true_for_registered_modifier() -> void:
	assert_true(EffectRegistry.is_modifier_field("armor", "floor"))
	assert_true(EffectRegistry.is_modifier_field("shock", "cleanse_immune"))


func test_is_modifier_field_false_for_count_or_unknown() -> void:
	assert_false(EffectRegistry.is_modifier_field("armor", "value"), "value is the count field")
	assert_false(EffectRegistry.is_modifier_field("armor", "nonexistent"))
	assert_false(EffectRegistry.is_modifier_field("nonexistent", "floor"))


func test_side_wide_fields_are_declared() -> void:
	assert_true(EffectRegistry.SIDE_WIDE_FIELDS.has("cooldown_modifier_deciseconds"))
	assert_true(EffectRegistry.SIDE_WIDE_FIELDS.has("next_hit_bonus"))
