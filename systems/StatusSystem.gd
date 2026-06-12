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
	# Side-wide one-shot bonus consumed by this side's NEXT damaging direct hit
	# (primed by the prime_next_hit ability atom — Crystal, Aether).
	result["next_hit_bonus"] = 0
	return result


static func slow_pct(n: int) -> float:
	if n == 0:
		return 0.0
	return TuningData.SHOCK_SLOW_MAX_PERCENT * float(n) / (float(n) + TuningData.SHOCK_SLOW_HALF_STACKS)


# True while a curse holds charges (Curse v2: stacks consumed per damaging event).
static func curse_active(curse: Dictionary) -> bool:
	return (curse["stacks"] as int) > 0


# ── Status Tray readout (in-combat HUD) ───────────────────────────────────────
# Whether a status is currently in effect on `statuses` and worth showing a chip for.
# Reads each status's own "in effect" rule (a bare count_field check misses curse's
# permanent flag, weaken's expiry, and leech's modifier fields). `slow` is dead → never.
static func is_active(name: String, statuses: Dictionary) -> bool:
	if not statuses.has(name) or not (statuses[name] is Dictionary):
		return false
	var d: Dictionary = statuses[name] as Dictionary
	match name:
		"burn", "poison", "weaken": return (d["stacks"] as int) > 0 and (name != "weaken" or (d["ticks"] as int) > 0)
		"armor", "plating": return (d["value"] as int) > 0
		"blind": return (d["percent"] as int) > 0
		"shock": return (d["n"] as int) > 0
		"haste": return (d["reduction"] as int) > 0
		"curse": return curse_active(d)
		"leech": return (d["bonus"] as int) > 0 or (d["double"] as bool)
	return false


# Active statuses on `statuses`, in EffectRegistry (stable) order — the Status Tray's
# chips for one side.
static func active_statuses(statuses: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for name: Variant in EffectRegistry.EFFECTS:
		if is_active(name as String, statuses):
			result.append(name as String)
	return result


# Plain-language, magnitude-filled readout for one active status — the Status Readout
# shown on a chip's hover. Numbers come straight from TuningData so they match combat.
static func describe(name: String, statuses: Dictionary) -> String:
	var d: Dictionary = statuses.get(name, {}) as Dictionary
	match name:
		"burn":
			var stacks: int = d["stacks"] as int
			var per_tick: int = stacks * TuningData.BURN_DAMAGE_PER_STACK + (d["tick_damage_bonus"] as int)
			return "Burning: %d damage/tick · %d stack%s left" % [per_tick, stacks, _plural(stacks)]
		"poison":
			var stacks: int = d["stacks"] as int
			var per_tick: int = stacks * TuningData.POISON_DAMAGE_PER_STACK + (d["tick_damage_bonus"] as int)
			return "Poisoned: %d damage/tick · %d stacks (permanent)" % [per_tick, stacks]
		"armor":
			return "Armor: absorbs %d incoming damage" % [(d["value"] as int) * TuningData.ARMOR_ABSORB_PER_POINT]
		"plating":
			return "Plating: -%d damage per hit" % [(d["value"] as int) * TuningData.PLATING_REDUCTION_PER_POINT]
		"blind":
			return "Blinded: %d%% chance to miss" % [d["percent"] as int]
		"shock":
			var n: int = (d["n"] as int) + (d["effective_stack_bonus"] as int)
			return "Shocked: cooldowns %d%% slower" % [int(round(slow_pct(n)))]
		"haste":
			return "Hasted: fires %.1fs sooner" % [float(d["reduction"] as int) / 10.0]
		"weaken":
			return "Weakened: -%d damage per hit · %ds left" % [(d["stacks"] as int) * TuningData.WEAKEN_DAMAGE_REDUCTION_PER_STACK, d["ticks"] as int]
		"curse":
			return "Cursed: +%d damage per hit/tick · %d charge%s left" % [d["damage_amplifier"] as int, d["stacks"] as int, _plural(d["stacks"] as int)]
		"leech":
			var bonus: int = d["bonus"] as int
			var bonus_str: String = (" +%d" % bonus) if bonus > 0 else ""
			var double_str: String = " (doubled)" if (d["double"] as bool) else ""
			return "Leeching: heals for damage dealt%s%s" % [bonus_str, double_str]
	return ""


static func _plural(n: int) -> String:
	return "" if n == 1 else "s"


# Short stack/magnitude badge shown beside a chip's emoji (and echoed in the readout).
# "" when there's nothing meaningful to count. Permanent curse shows "∞".
static func chip_badge(name: String, statuses: Dictionary) -> String:
	if not statuses.has(name) or not (statuses[name] is Dictionary):
		return ""
	var d: Dictionary = statuses[name] as Dictionary
	if name == "curse":
		return str(d["stacks"] as int) if (d["stacks"] as int) > 0 else ""
	var n: int = 0
	match name:
		"burn", "poison", "weaken": n = d["stacks"] as int
		"armor", "plating": n = d["value"] as int
		"shock": n = (d["n"] as int) + (d["effective_stack_bonus"] as int)
		"blind":
			@warning_ignore("integer_division")
			n = (d["percent"] as int) / TuningData.BLIND_PERCENT_PER_STACK
		"haste":
			@warning_ignore("integer_division")
			n = (d["reduction"] as int) / TuningData.HASTE_REDUCTION_DECISECONDS
		"leech": n = d["bonus"] as int
	return str(n) if n > 0 else ""


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
# `potency` (the applying element's Level) scales the quantity applied this call —
# a Lv-N element applies N stacks / points / heal. Default 1 (instant effects, tests).
static func apply_effect(statuses: Dictionary, effect: String, potency: int = 1, source_slot: int = -1) -> Dictionary:
	var s: Dictionary = statuses.duplicate(true)
	var hp_delta: int = 0
	var p: int = maxi(1, potency)

	match effect:
		"burn":
			var d: Dictionary = s["burn"] as Dictionary
			var before: int = d["stacks"] as int
			d["stacks"] = mini(before + p, MAX_STACKS)
			_credit_source(d, source_slot, (d["stacks"] as int) - before)
		"poison":
			var d: Dictionary = s["poison"] as Dictionary
			var before: int = d["stacks"] as int
			d["stacks"] = mini(before + p, MAX_STACKS)
			_credit_source(d, source_slot, (d["stacks"] as int) - before)
		"armor":
			var d: Dictionary = s["armor"] as Dictionary
			# Acid passive: once this side's armor has been stripped to 0, it cannot
			# regenerate — further armor applications are swallowed.
			if not ((d["regen_blocked"] as bool) and (d["stripped"] as bool)):
				var before: int = d["value"] as int
				d["value"] = mini(before + p, MAX_STACKS)
				_credit_source(d, source_slot, (d["value"] as int) - before)
		"plating":
			var d: Dictionary = s["plating"] as Dictionary
			var before: int = d["value"] as int
			d["value"] = mini(before + p, MAX_STACKS)
			_credit_source(d, source_slot, (d["value"] as int) - before)
		"blind":
			var d: Dictionary = s["blind"] as Dictionary
			d["percent"] = mini((d["percent"] as int) + p * TuningData.BLIND_PERCENT_PER_STACK, TuningData.BLIND_PERCENT_CAP)
		"shock":
			var d: Dictionary = s["shock"] as Dictionary
			d["n"] = mini((d["n"] as int) + p, MAX_STACKS)
		"slow":
			var d: Dictionary = s["slow"] as Dictionary
			d["n"] = mini((d["n"] as int) + p, MAX_STACKS)
		"haste":
			var d: Dictionary = s["haste"] as Dictionary
			d["reduction"] = (d["reduction"] as int) + p * TuningData.HASTE_REDUCTION_DECISECONDS
		"weaken":
			var d: Dictionary = s["weaken"] as Dictionary
			d["stacks"] = mini((d["stacks"] as int) + p, MAX_STACKS)
			d["ticks"] = TuningData.WEAKEN_DURATION_TICKS + (d["duration_bonus"] as int)
		"curse":
			var d: Dictionary = s["curse"] as Dictionary
			d["stacks"] = mini((d["stacks"] as int) + p, MAX_STACKS)
			# Plain curse carries a base per-event amplifier; abilities may raise it.
			if (d["damage_amplifier"] as int) <= 0:
				d["damage_amplifier"] = TuningData.CURSE_DOT_AMPLIFIER
		"heal":
			hp_delta = TuningData.HEAL_PER_APPLICATION * p
		"cleanse":
			var remove: int = TuningData.CLEANSE_REMOVE_PER_APPLICATION * p
			var burn_d: Dictionary = s["burn"] as Dictionary
			burn_d["stacks"] = maxi(0, (burn_d["stacks"] as int) - remove)
			_decrement_source(burn_d["by_source"] as Dictionary, remove)
			var poison_d: Dictionary = s["poison"] as Dictionary
			poison_d["stacks"] = maxi(0, (poison_d["stacks"] as int) - remove)
			_decrement_source(poison_d["by_source"] as Dictionary, remove)
			var shock_d: Dictionary = s["shock"] as Dictionary
			# Tempest passive: shock on this side cannot be cleansed away.
			if not (shock_d["cleanse_immune"] as bool):
				shock_d["n"] = maxi(0, (shock_d["n"] as int) - remove)
			var slow_d: Dictionary = s["slow"] as Dictionary
			slow_d["n"] = maxi(0, (slow_d["n"] as int) - remove)
			var weaken_d: Dictionary = s["weaken"] as Dictionary
			weaken_d["stacks"] = maxi(0, (weaken_d["stacks"] as int) - remove)
			var blind_d: Dictionary = s["blind"] as Dictionary
			blind_d["percent"] = maxi(0, (blind_d["percent"] as int) - remove * TuningData.BLIND_PERCENT_PER_STACK)
		"leech":
			hp_delta = TuningData.LEECH_PER_APPLICATION * p

	return { "statuses": s, "hp_delta": hp_delta }


# Records `amount` stacks/points applied by `source_slot` into a status's per-source
# attribution ledger (`by_source`), so tick damage can later be split back to the
# element that laid each stack. No-op for unattributed applications (slot < 0, e.g.
# sandstorm or tests) or statuses that don't carry a ledger.
static func _credit_source(status: Dictionary, source_slot: int, amount: int) -> void:
	if source_slot < 0 or amount <= 0 or not status.has("by_source"):
		return
	var by_source: Dictionary = status["by_source"] as Dictionary
	by_source[source_slot] = (by_source.get(source_slot, 0) as int) + amount


# Advances all time-based statuses by one tick (1 second).
# Returns { "statuses": Dictionary, "damage": int } where damage is HP damage
# dealt this tick (burn + poison). Armor absorbs burn at half rate but never
# below its floor; Plating with reduces_dot shaves the tick total.
static func tick(statuses: Dictionary) -> Dictionary:
	var s: Dictionary = statuses.duplicate(true)
	var hp_damage: int = 0
	var events: Array = []
	var curse: Dictionary = s["curse"] as Dictionary
	# Per-source damage attribution for Contribution Bars: maps a DOT type to a
	# { source_slot: damage } split of the HP that type dealt this tick (pre global
	# plating/curse modifiers), so BattleSystem can credit each contributing element.
	var attribution: Dictionary = { "burn": {}, "poison": {} }
	# Damage Blocked this tick by THIS side's defences (armor soaking burn + plating
	# shaving the DOT total), split to the defending element(s) that laid them.
	var blocked_by_source: Dictionary = {}

	# Burn: deal damage (armor absorbs at half rate, never below floor), decrement stacks
	var burn: Dictionary = s["burn"] as Dictionary
	var burn_stacks: int = burn["stacks"] as int
	if burn_stacks > 0:
		# next_tick_bonus is a one-shot primer (prime_dot atom) consumed by this tick.
		var raw_burn: int = burn_stacks * TuningData.BURN_DAMAGE_PER_STACK + (burn["tick_damage_bonus"] as int) + (burn["next_tick_bonus"] as int)
		burn["next_tick_bonus"] = 0
		var armor: Dictionary = s["armor"] as Dictionary
		var armor_val: int = armor["value"] as int
		var absorbable: int = maxi(0, armor_val - (armor["floor"] as int))
		@warning_ignore("integer_division")
		var armor_absorbed: int = mini(absorbable, raw_burn / TuningData.ARMOR_BURN_ABSORB_DIVISOR)
		armor["value"] = armor_val - armor_absorbed
		if armor_val > 0 and (armor["value"] as int) == 0:
			armor["stripped"] = true
		if armor_absorbed > 0:
			_merge_split(blocked_by_source, _split_proportional(armor["by_source"] as Dictionary, armor_absorbed))
			_decrement_source(armor["by_source"] as Dictionary, armor_absorbed)
		var burn_dealt: int = raw_burn - armor_absorbed
		hp_damage += burn_dealt
		attribution["burn"] = _split_proportional(burn["by_source"] as Dictionary, burn_dealt)
		burn["stacks"] = burn_stacks - 1
		_decrement_source(burn["by_source"] as Dictionary, 1)
		events.append("on_burn_tick")

	# Poison: deal damage, stacks never decrease
	var poison: Dictionary = s["poison"] as Dictionary
	var poison_stacks: int = poison["stacks"] as int
	if poison_stacks > 0:
		# next_tick_bonus is a one-shot primer (prime_dot atom) consumed by this tick.
		var poison_dealt: int = poison_stacks * TuningData.POISON_DAMAGE_PER_STACK + (poison["tick_damage_bonus"] as int) + (poison["next_tick_bonus"] as int)
		poison["next_tick_bonus"] = 0
		hp_damage += poison_dealt
		attribution["poison"] = _split_proportional(poison["by_source"] as Dictionary, poison_dealt)
		events.append("on_poison_tick")

	# Plating-vs-DOT (Steel): plating shaves the tick total when flagged. The shaved HP
	# is Damage Blocked credited to the plating element(s).
	var plating: Dictionary = s["plating"] as Dictionary
	if (plating["reduces_dot"] as bool) and hp_damage > 0:
		var before_plating: int = hp_damage
		hp_damage = maxi(0, hp_damage - (plating["value"] as int))
		var plating_reduced: int = before_plating - hp_damage
		if plating_reduced > 0:
			_merge_split(blocked_by_source, _split_proportional(plating["by_source"] as Dictionary, plating_reduced))

	# Curse v2: a DOT tick is a damaging event — amplify the tick by damage_amplifier and
	# consume one curse stack. When stacks reach 0, the curse is spent.
	if hp_damage > 0 and (curse["stacks"] as int) > 0:
		hp_damage += curse["damage_amplifier"] as int
		curse["stacks"] = (curse["stacks"] as int) - 1

	# Weaken: decrement ticks, stacks stay
	var weaken: Dictionary = s["weaken"] as Dictionary
	var weaken_ticks: int = weaken["ticks"] as int
	if weaken_ticks > 0:
		weaken["ticks"] = weaken_ticks - 1

	return { "statuses": s, "damage": hp_damage, "events": events, "attribution": attribution, "blocked_by_source": blocked_by_source }


# Adds a { slot: amount } split into an accumulator dict (used to merge armor- and
# plating-blocked contributions from multiple defences into one blocked ledger).
static func _merge_split(target: Dictionary, addition: Dictionary) -> void:
	for slot: Variant in addition:
		target[slot] = (target.get(slot, 0) as int) + (addition[slot] as int)


# Removes `amount` stacks from a `by_source` ledger, taking from the largest source
# first (ties → lowest slot) so the ledger stays in sync with an aggregate that
# decrements (burn per-tick) or is cleansed. Deterministic; drops keys that hit 0.
static func _decrement_source(by_source: Dictionary, amount: int) -> void:
	for _i: int in amount:
		if by_source.is_empty():
			return
		var slots: Array = by_source.keys()
		slots.sort()  # ascending → first max found is the lowest slot among ties
		var target: int = slots[0] as int
		for slot: int in slots:
			if (by_source[slot] as int) > (by_source[target] as int):
				target = slot
		var left: int = (by_source[target] as int) - 1
		if left <= 0:
			by_source.erase(target)
		else:
			by_source[target] = left


# Splits `total` damage across the sources in `by_source` (a { slot: weight } ledger),
# proportionally to each source's weight. Uses largest-remainder apportionment with a
# deterministic tie-break (ascending slot) so the per-slot integers sum exactly to
# `total` and the result is reproducible under Replay. Empty when nothing to split.
static func _split_proportional(by_source: Dictionary, total: int) -> Dictionary:
	var result: Dictionary = {}
	if total <= 0 or by_source.is_empty():
		return result
	var slots: Array = by_source.keys()
	slots.sort()
	var weight_sum: int = 0
	for slot: int in slots:
		weight_sum += by_source[slot] as int
	if weight_sum <= 0:
		return result
	var assigned: int = 0
	var remainders: Array = []  # [{ slot, rem }], parallel to floor assignment
	for slot: int in slots:
		var exact: int = (by_source[slot] as int) * total
		@warning_ignore("integer_division")
		var base: int = exact / weight_sum
		result[slot] = base
		assigned += base
		remainders.append({ "slot": slot, "rem": exact % weight_sum })
	# Hand out the leftover one unit at a time to the largest remainders (ties → lower slot).
	remainders.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if (a["rem"] as int) != (b["rem"] as int):
			return (a["rem"] as int) > (b["rem"] as int)
		return (a["slot"] as int) < (b["slot"] as int))
	var leftover: int = total - assigned
	for i: int in leftover:
		var slot: int = remainders[i]["slot"] as int
		result[slot] = (result[slot] as int) + 1
	return result


# Computes final HP damage after Weaken (attacker penalty), Plating (flat reduction),
# Armor (physical absorption, never below floor), and Curse (defender vulnerability).
# Returns { "damage": int, "defender_statuses": Dictionary }.
static func compute_incoming_damage(raw: int, attacker_statuses: Dictionary, defender_statuses: Dictionary) -> Dictionary:
	var dmg: int = raw
	var def_s: Dictionary = defender_statuses.duplicate(true)
	# Per-source split of the HP this side's Armor prevents — credited to the defending
	# element(s) that laid the armor (the "Damage Blocked" Contribution).
	var blocked_by_source: Dictionary = {}

	# Weaken on attacker reduces their damage output (only while ticks > 0)
	var weaken: Dictionary = attacker_statuses["weaken"] as Dictionary
	if (weaken["ticks"] as int) > 0:
		dmg = maxi(0, dmg - (weaken["stacks"] as int) * TuningData.WEAKEN_DAMAGE_REDUCTION_PER_STACK)

	# Plating: flat integer reduction to all incoming. The reduced HP is Damage Blocked.
	var plating: Dictionary = def_s["plating"] as Dictionary
	var plating_val: int = plating["value"] as int
	var before_plating: int = dmg
	dmg = maxi(0, dmg - plating_val * TuningData.PLATING_REDUCTION_PER_POINT)
	if before_plating - dmg > 0:
		_merge_split(blocked_by_source, _split_proportional(plating["by_source"] as Dictionary, before_plating - dmg))

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
		blocked_by_source = _split_proportional(armor["by_source"] as Dictionary, absorbed)
		_decrement_source(armor["by_source"] as Dictionary, points_spent)
		armor["value"] = armor_val - points_spent
		if armor_val > 0 and (armor["value"] as int) == 0:
			armor["stripped"] = true
		dmg -= absorbed

	# Curse v2: a damaging hit consumes one curse stack and adds damage_amplifier. A hit
	# mitigated to 0 neither amplifies nor consumes.
	var curse: Dictionary = def_s["curse"] as Dictionary
	if dmg > 0 and (curse["stacks"] as int) > 0:
		dmg += curse["damage_amplifier"] as int
		curse["stacks"] = (curse["stacks"] as int) - 1

	return { "damage": dmg, "defender_statuses": def_s, "blocked_by_source": blocked_by_source }
