class_name StatusSystem

# Balance magnitudes (haste/blind/shock/curse/weaken/heal/leech/burn/poison/armor/
# plating, the CD floor and DOT cadence) live in TuningData. MAX_STACKS stays here:
# it's a runaway-build safety cap, not a balance knob.
# Safety ceiling on stacking statuses so a runaway "infinite build" can't grow numbers
# without bound over a 30 s combat. Far above any realistic stack count.
const MAX_STACKS: int = 99


static func empty_statuses() -> Dictionary:
	var result: Dictionary = {}
	for effect: Variant in EffectRegistry.EFFECTS:
		var entry: Dictionary = EffectRegistry.EFFECTS[effect] as Dictionary
		var shape: Dictionary = entry.get("status_shape", {}) as Dictionary
		if not shape.is_empty():
			result[effect as String] = shape.duplicate(true)
	result["cooldown_modifier_deciseconds"] = 0
	return result


static func slow_pct(n: int) -> float:
	if n == 0:
		return 0.0
	return TuningData.SHOCK_SLOW_MAX_PERCENT * float(n) / (float(n) + TuningData.SHOCK_SLOW_HALF_STACKS)


# True while a curse is in effect — either ticking down or pinned permanent.
static func curse_active(curse: Dictionary) -> bool:
	return (curse["is_permanent"] as bool) or (curse["ticks_remaining"] as int) > 0


# Effective firing cooldown for one element, in integer deciseconds.
# Applies the side-wide signed cooldown modifier (penalties +, reductions -) and
# shock-slow, then floors at 10 deciseconds (one fire per second). The slowed
# value is rounded to the nearest decisecond.
static func effective_cooldown_deciseconds(base_deciseconds: int, own_statuses: Dictionary) -> int:
	var shock_dict: Dictionary = own_statuses["shock"] as Dictionary
	var shock_stacks: int = (shock_dict["n"] as int) + (shock_dict.get("effective_stack_bonus", 0) as int)
	var cooldown_modifier_deciseconds: int = own_statuses.get("cooldown_modifier_deciseconds", 0) as int
	# Global firing-rate dial (G4, TuningData.COMBAT_COOLDOWN_MULTIPLIER) scales the base
	# before the side-wide modifier and shock-slow are applied.
	var scaled_base: float = float(base_deciseconds) * TuningData.COMBAT_COOLDOWN_MULTIPLIER
	var modified_base: float = scaled_base + float(cooldown_modifier_deciseconds)
	var slowed_deciseconds: float = modified_base * (1.0 + slow_pct(shock_stacks) / 100.0)
	return maxi(TuningData.EFFECTIVE_CD_FLOOR_DECISECONDS, int(round(slowed_deciseconds)))


# Returns { "statuses": Dictionary, "hp_delta": int }.
# hp_delta is non-zero only for instant self-effects (heal, leech).
static func apply_effect(statuses: Dictionary, effect: String) -> Dictionary:
	var s: Dictionary = statuses.duplicate(true)
	var hp_delta: int = 0

	match effect:
		"burn":
			var d: Dictionary = s["burn"] as Dictionary
			d["stacks"] = mini((d["stacks"] as int) + 1, MAX_STACKS)
		"poison":
			var d: Dictionary = s["poison"] as Dictionary
			d["stacks"] = mini((d["stacks"] as int) + 1, MAX_STACKS)
		"armor":
			var d: Dictionary = s["armor"] as Dictionary
			d["value"] = mini((d["value"] as int) + 1, MAX_STACKS)
		"plating":
			var d: Dictionary = s["plating"] as Dictionary
			d["value"] = mini((d["value"] as int) + 1, MAX_STACKS)
		"blind":
			var d: Dictionary = s["blind"] as Dictionary
			d["percent"] = mini((d["percent"] as int) + TuningData.BLIND_PERCENT_PER_STACK, TuningData.BLIND_PERCENT_CAP)
		"shock":
			var d: Dictionary = s["shock"] as Dictionary
			d["n"] = mini((d["n"] as int) + 1, MAX_STACKS)
		"slow":
			var d: Dictionary = s["slow"] as Dictionary
			d["n"] = mini((d["n"] as int) + 1, MAX_STACKS)
		"haste":
			var d: Dictionary = s["haste"] as Dictionary
			d["reduction"] = (d["reduction"] as int) + TuningData.HASTE_REDUCTION_DECISECONDS
		"weaken":
			var d: Dictionary = s["weaken"] as Dictionary
			d["stacks"] = mini((d["stacks"] as int) + 1, MAX_STACKS)
			d["ticks"] = TuningData.WEAKEN_DURATION_TICKS + (d["duration_bonus"] as int)
		"curse":
			var d: Dictionary = s["curse"] as Dictionary
			d["ticks_remaining"] = TuningData.CURSE_DURATION_TICKS
		"heal":
			hp_delta = TuningData.HEAL_PER_APPLICATION
		"cleanse":
			var remove: int = TuningData.CLEANSE_REMOVE_PER_APPLICATION
			var burn_d: Dictionary = s["burn"] as Dictionary
			burn_d["stacks"] = maxi(0, (burn_d["stacks"] as int) - remove)
			var poison_d: Dictionary = s["poison"] as Dictionary
			poison_d["stacks"] = maxi(0, (poison_d["stacks"] as int) - remove)
			var shock_d: Dictionary = s["shock"] as Dictionary
			shock_d["n"] = maxi(0, (shock_d["n"] as int) - remove)
			var slow_d: Dictionary = s["slow"] as Dictionary
			slow_d["n"] = maxi(0, (slow_d["n"] as int) - remove)
			var weaken_d: Dictionary = s["weaken"] as Dictionary
			weaken_d["stacks"] = maxi(0, (weaken_d["stacks"] as int) - remove)
			var blind_d: Dictionary = s["blind"] as Dictionary
			blind_d["percent"] = maxi(0, (blind_d["percent"] as int) - remove * TuningData.BLIND_PERCENT_PER_STACK)
		"leech":
			hp_delta = TuningData.LEECH_PER_APPLICATION

	return { "statuses": s, "hp_delta": hp_delta }


# Advances all time-based statuses by one tick (1 second).
# Returns { "statuses": Dictionary, "damage": int } where damage is HP damage
# dealt this tick (burn + poison). Armor absorbs burn at half rate but never
# below its floor; Plating with reduces_dot shaves the tick total.
static func tick(statuses: Dictionary) -> Dictionary:
	var s: Dictionary = statuses.duplicate(true)
	var hp_damage: int = 0
	var events: Array = []
	var curse: Dictionary = s["curse"] as Dictionary
	var curse_bonus: int = TuningData.CURSE_DOT_AMPLIFIER if curse_active(curse) else 0

	# Burn: deal damage (armor absorbs at half rate, never below floor), decrement stacks
	var burn: Dictionary = s["burn"] as Dictionary
	var burn_stacks: int = burn["stacks"] as int
	if burn_stacks > 0:
		var raw_burn: int = burn_stacks * TuningData.BURN_DAMAGE_PER_STACK + (burn["tick_damage_bonus"] as int) + curse_bonus
		var armor: Dictionary = s["armor"] as Dictionary
		var armor_val: int = armor["value"] as int
		var absorbable: int = maxi(0, armor_val - (armor["floor"] as int))
		@warning_ignore("integer_division")
		var armor_absorbed: int = mini(absorbable, raw_burn / TuningData.ARMOR_BURN_ABSORB_DIVISOR)
		armor["value"] = armor_val - armor_absorbed
		hp_damage += raw_burn - armor_absorbed
		burn["stacks"] = burn_stacks - 1
		events.append("on_burn_tick")

	# Poison: deal damage, stacks never decrease
	var poison: Dictionary = s["poison"] as Dictionary
	var poison_stacks: int = poison["stacks"] as int
	if poison_stacks > 0:
		hp_damage += poison_stacks * TuningData.POISON_DAMAGE_PER_STACK + (poison["tick_damage_bonus"] as int) + curse_bonus
		events.append("on_poison_tick")

	# Plating-vs-DOT (Steel): plating shaves the tick total when flagged
	var plating: Dictionary = s["plating"] as Dictionary
	if (plating["reduces_dot"] as bool) and hp_damage > 0:
		hp_damage = maxi(0, hp_damage - (plating["value"] as int))

	# Weaken: decrement ticks, stacks stay
	var weaken: Dictionary = s["weaken"] as Dictionary
	var weaken_ticks: int = weaken["ticks"] as int
	if weaken_ticks > 0:
		weaken["ticks"] = weaken_ticks - 1

	# Curse: decrement remaining ticks unless pinned permanent
	if not (curse["is_permanent"] as bool):
		var curse_ticks: int = curse["ticks_remaining"] as int
		if curse_ticks > 0:
			curse["ticks_remaining"] = curse_ticks - 1

	return { "statuses": s, "damage": hp_damage, "events": events }


# Computes final HP damage after Weaken (attacker penalty), Plating (flat reduction),
# Armor (physical absorption, never below floor), and Curse (defender vulnerability).
# Returns { "damage": int, "defender_statuses": Dictionary }.
static func compute_incoming_damage(raw: int, attacker_statuses: Dictionary, defender_statuses: Dictionary) -> Dictionary:
	var dmg: int = raw
	var def_s: Dictionary = defender_statuses.duplicate(true)

	# Weaken on attacker reduces their damage output (only while ticks > 0)
	var weaken: Dictionary = attacker_statuses["weaken"] as Dictionary
	if (weaken["ticks"] as int) > 0:
		dmg = maxi(0, dmg - (weaken["stacks"] as int) * TuningData.WEAKEN_DAMAGE_REDUCTION_PER_STACK)

	# Plating: flat integer reduction to all incoming
	var plating_val: int = (def_s["plating"] as Dictionary)["value"] as int
	dmg = maxi(0, dmg - plating_val * TuningData.PLATING_REDUCTION_PER_POINT)

	# Armor: absorbs remaining physical damage, depletes but never below floor.
	# Each armor point soaks ARMOR_ABSORB_PER_POINT damage (1:1 today).
	var armor: Dictionary = def_s["armor"] as Dictionary
	var armor_val: int = armor["value"] as int
	var absorbable: int = maxi(0, armor_val - (armor["floor"] as int))
	if absorbable > 0 and dmg > 0:
		var capacity: int = absorbable * TuningData.ARMOR_ABSORB_PER_POINT
		var absorbed: int = mini(capacity, dmg)
		@warning_ignore("integer_division")
		var points_spent: int = absorbed / TuningData.ARMOR_ABSORB_PER_POINT
		armor["value"] = armor_val - points_spent
		dmg -= absorbed

	# Curse: a cursed defender takes a flat vulnerability bonus on every hit
	var curse: Dictionary = def_s["curse"] as Dictionary
	if curse_active(curse):
		dmg += curse["damage_amplifier"] as int

	return { "damage": dmg, "defender_statuses": def_s }
