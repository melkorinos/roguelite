class_name StatusSystem

# Per-application strength of the Haste action, in deciseconds (0.3 s). Gust upgrades this.
const HASTE_REDUCTION_DECISECONDS: int = 3


static func empty_statuses() -> Dictionary:
	return {
		"burn":    { "stacks": 0, "tick_damage_bonus": 0 },
		"poison":  { "stacks": 0, "tick_damage_bonus": 0 },
		"armor":   { "value": 0 },
		"plating": { "value": 0 },
		"blind":   { "percent": 0 },
		"shock":   { "n": 0, "effective_stack_bonus": 0 },
		"slow":    { "n": 0 },
		"haste":   { "reduction": 0 },
		"weaken":  { "stacks": 0, "ticks": 0 },
		"curse":   { "ticks_remaining": 0, "is_permanent": false, "damage_amplifier": 0 },
		"cooldown_modifier_deciseconds": 0,
	}


static func slow_pct(n: int) -> float:
	if n == 0:
		return 0.0
	return 50.0 * float(n) / (float(n) + 5.0)


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
	var modified_base: int = base_deciseconds + cooldown_modifier_deciseconds
	var slowed_deciseconds: float = float(modified_base) * (1.0 + slow_pct(shock_stacks) / 100.0)
	return maxi(10, int(round(slowed_deciseconds)))


# Returns { "statuses": Dictionary, "hp_delta": int }.
# hp_delta is non-zero only for instant self-effects (heal, leech).
# Caller passes the relevant side's statuses dict (own for armor/haste/heal/cleanse,
# opponent for burn/poison/blind/shock/weaken/curse).
static func apply_effect(statuses: Dictionary, effect: String) -> Dictionary:
	var s: Dictionary = statuses.duplicate(true)
	var hp_delta: int = 0

	match effect:
		"burn":
			var d: Dictionary = s["burn"] as Dictionary
			d["stacks"] = (d["stacks"] as int) + 1
		"poison":
			var d: Dictionary = s["poison"] as Dictionary
			d["stacks"] = (d["stacks"] as int) + 1
		"armor":
			var d: Dictionary = s["armor"] as Dictionary
			d["value"] = (d["value"] as int) + 1
		"plating":
			var d: Dictionary = s["plating"] as Dictionary
			d["value"] = (d["value"] as int) + 1
		"blind":
			var d: Dictionary = s["blind"] as Dictionary
			d["percent"] = mini((d["percent"] as int) + 15, 50)
		"shock":
			var d: Dictionary = s["shock"] as Dictionary
			d["n"] = (d["n"] as int) + 1
		"slow":
			var d: Dictionary = s["slow"] as Dictionary
			d["n"] = (d["n"] as int) + 1
		"haste":
			var d: Dictionary = s["haste"] as Dictionary
			d["reduction"] = (d["reduction"] as int) + HASTE_REDUCTION_DECISECONDS
		"weaken":
			var d: Dictionary = s["weaken"] as Dictionary
			d["stacks"] = (d["stacks"] as int) + 1
			d["ticks"] = 3
		"curse":
			var d: Dictionary = s["curse"] as Dictionary
			d["ticks_remaining"] = 3
		"heal":
			hp_delta = 1
		"cleanse":
			var burn_d: Dictionary = s["burn"] as Dictionary
			burn_d["stacks"] = maxi(0, (burn_d["stacks"] as int) - 1)
			var poison_d: Dictionary = s["poison"] as Dictionary
			poison_d["stacks"] = maxi(0, (poison_d["stacks"] as int) - 1)
			var shock_d: Dictionary = s["shock"] as Dictionary
			shock_d["n"] = maxi(0, (shock_d["n"] as int) - 1)
			var slow_d: Dictionary = s["slow"] as Dictionary
			slow_d["n"] = maxi(0, (slow_d["n"] as int) - 1)
			var weaken_d: Dictionary = s["weaken"] as Dictionary
			weaken_d["stacks"] = maxi(0, (weaken_d["stacks"] as int) - 1)
			var blind_d: Dictionary = s["blind"] as Dictionary
			blind_d["percent"] = maxi(0, (blind_d["percent"] as int) - 15)
		"leech":
			hp_delta = 1

	return { "statuses": s, "hp_delta": hp_delta }


# Advances all time-based statuses by one tick (1 second).
# Returns { "statuses": Dictionary, "damage": int } where damage is HP damage
# dealt this tick (burn + poison). Armor absorbs burn at half rate.
static func tick(statuses: Dictionary) -> Dictionary:
	var s: Dictionary = statuses.duplicate(true)
	var hp_damage: int = 0
	var curse: Dictionary = s["curse"] as Dictionary
	var curse_bonus: int = 1 if curse_active(curse) else 0

	# Burn: deal damage (armor absorbs at half rate), decrement stacks
	var burn: Dictionary = s["burn"] as Dictionary
	var burn_stacks: int = burn["stacks"] as int
	if burn_stacks > 0:
		var raw_burn: int = burn_stacks + (burn["tick_damage_bonus"] as int) + curse_bonus
		var armor: Dictionary = s["armor"] as Dictionary
		var armor_val: int = armor["value"] as int
		@warning_ignore("integer_division")
		var armor_absorbed: int = mini(armor_val, raw_burn / 2)
		armor["value"] = armor_val - armor_absorbed
		hp_damage += raw_burn - armor_absorbed
		burn["stacks"] = burn_stacks - 1

	# Poison: deal damage, stacks never decrease
	var poison: Dictionary = s["poison"] as Dictionary
	var poison_stacks: int = poison["stacks"] as int
	if poison_stacks > 0:
		hp_damage += poison_stacks + (poison["tick_damage_bonus"] as int) + curse_bonus

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

	return { "statuses": s, "damage": hp_damage }


# Computes final HP damage after applying Weaken (attacker output penalty),
# Plating (flat reduction on defender), Armor (physical absorption on defender),
# and Curse (defender vulnerability bonus). Returns { "damage": int,
# "defender_statuses": Dictionary } — armor depletion is reflected in the returned
# defender_statuses; caller must write it back.
static func compute_incoming_damage(raw: int, attacker_statuses: Dictionary, defender_statuses: Dictionary) -> Dictionary:
	var dmg: int = raw
	var def_s: Dictionary = defender_statuses.duplicate(true)

	# Weaken on attacker reduces their damage output (only while ticks > 0)
	var weaken: Dictionary = attacker_statuses["weaken"] as Dictionary
	if (weaken["ticks"] as int) > 0:
		dmg = maxi(0, dmg - (weaken["stacks"] as int))

	# Plating: flat integer reduction to all incoming
	var plating_val: int = (def_s["plating"] as Dictionary)["value"] as int
	dmg = maxi(0, dmg - plating_val)

	# Armor: absorbs remaining physical damage, depletes
	var armor: Dictionary = def_s["armor"] as Dictionary
	var armor_val: int = armor["value"] as int
	if armor_val > 0:
		var absorbed: int = mini(armor_val, dmg)
		armor["value"] = armor_val - absorbed
		dmg -= absorbed

	# Curse: a cursed defender takes a flat vulnerability bonus on every hit
	var curse: Dictionary = def_s["curse"] as Dictionary
	if curse_active(curse):
		dmg += curse["damage_amplifier"] as int

	return { "damage": dmg, "defender_statuses": def_s }
