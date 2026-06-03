class_name StatusSystem


static func empty_statuses() -> Dictionary:
	return {
		"burn":    { "stacks": 0 },
		"poison":  { "stacks": 0 },
		"armor":   { "value": 0 },
		"plating": { "value": 0.0 },
		"blind":   { "pct": 0.0 },
		"shock":   { "n": 0 },
		"slow":    { "n": 0 },
		"haste":   { "reduction": 0.0 },
		"weaken":  { "stacks": 0, "ticks": 0 },
		"curse":   { "ticks": 0 },
	}


static func slow_pct(n: int) -> float:
	if n == 0:
		return 0.0
	return 50.0 * float(n) / (float(n) + 5.0)


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
			d["value"] = (d["value"] as float) + 0.1
		"blind":
			var d: Dictionary = s["blind"] as Dictionary
			d["pct"] = minf((d["pct"] as float) + 0.15, 0.50)
		"shock":
			var d: Dictionary = s["shock"] as Dictionary
			d["n"] = (d["n"] as int) + 1
		"slow":
			var d: Dictionary = s["slow"] as Dictionary
			d["n"] = (d["n"] as int) + 1
		"haste":
			var d: Dictionary = s["haste"] as Dictionary
			d["reduction"] = (d["reduction"] as float) + 0.3
		"weaken":
			var d: Dictionary = s["weaken"] as Dictionary
			d["stacks"] = (d["stacks"] as int) + 1
			d["ticks"] = 3
		"curse":
			var d: Dictionary = s["curse"] as Dictionary
			d["ticks"] = 3
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
			blind_d["pct"] = maxf(0.0, (blind_d["pct"] as float) - 0.15)
		"leech":
			hp_delta = 1

	return { "statuses": s, "hp_delta": hp_delta }


# Advances all time-based statuses by one tick (1 second).
# Returns { "statuses": Dictionary, "damage": int } where damage is HP damage
# dealt this tick (burn + poison). Armor absorbs burn at half rate.
static func tick(statuses: Dictionary) -> Dictionary:
	var s: Dictionary = statuses.duplicate(true)
	var hp_damage: int = 0
	var curse_active: bool = ((s["curse"] as Dictionary)["ticks"] as int) > 0
	var curse_bonus: int = 1 if curse_active else 0

	# Burn: deal damage (armor absorbs at half rate), decrement stacks
	var burn: Dictionary = s["burn"] as Dictionary
	var burn_stacks: int = burn["stacks"] as int
	if burn_stacks > 0:
		var raw_burn: int = burn_stacks + curse_bonus
		var armor: Dictionary = s["armor"] as Dictionary
		var armor_val: int = armor["value"] as int
		var armor_absorbed: int = mini(armor_val, raw_burn / 2)
		armor["value"] = armor_val - armor_absorbed
		hp_damage += raw_burn - armor_absorbed
		burn["stacks"] = burn_stacks - 1

	# Poison: deal damage, stacks never decrease
	var poison: Dictionary = s["poison"] as Dictionary
	var poison_stacks: int = poison["stacks"] as int
	if poison_stacks > 0:
		hp_damage += poison_stacks + curse_bonus

	# Weaken: decrement ticks, stacks stay
	var weaken: Dictionary = s["weaken"] as Dictionary
	var weaken_ticks: int = weaken["ticks"] as int
	if weaken_ticks > 0:
		weaken["ticks"] = weaken_ticks - 1

	# Curse: decrement ticks
	var curse: Dictionary = s["curse"] as Dictionary
	var curse_ticks: int = curse["ticks"] as int
	if curse_ticks > 0:
		curse["ticks"] = curse_ticks - 1

	return { "statuses": s, "damage": hp_damage }


# Computes final HP damage after applying Weaken (attacker output penalty),
# Plating (flat reduction on defender), and Armor (physical absorption on defender).
# Returns { "damage": int, "defender_statuses": Dictionary } — armor depletion
# is reflected in the returned defender_statuses; caller must write it back.
static func compute_incoming_damage(raw: int, attacker_statuses: Dictionary, defender_statuses: Dictionary) -> Dictionary:
	var dmg: int = raw
	var def_s: Dictionary = defender_statuses.duplicate(true)

	# Weaken on attacker reduces their damage output (only while ticks > 0)
	var weaken: Dictionary = attacker_statuses["weaken"] as Dictionary
	if (weaken["ticks"] as int) > 0:
		dmg = maxi(0, dmg - (weaken["stacks"] as int))

	# Plating: flat reduction to all incoming
	var plating_val: float = (def_s["plating"] as Dictionary)["value"] as float
	dmg = maxi(0, dmg - int(floor(plating_val)))

	# Armor: absorbs remaining physical damage, depletes
	var armor: Dictionary = def_s["armor"] as Dictionary
	var armor_val: int = armor["value"] as int
	if armor_val > 0:
		var absorbed: int = mini(armor_val, dmg)
		armor["value"] = armor_val - absorbed
		dmg -= absorbed

	return { "damage": dmg, "defender_statuses": def_s }
