class_name EffectRegistry

# Single source of truth for per-effect metadata consumed by StatusSystem,
# AbilitySystem, the in-combat Status Tray, and the floating combat labels.
#
# status_shape: initial dict written into StatusSystem.empty_statuses().
#               {} means no persistent status (heal, cleanse are instant-only).
# count_field:  the headline field read by AbilitySystem._status_count() for
#               "target_has_status" conditions. "" = not condition-testable.
# triggers:     trigger strings emitted when this effect fires on a hit.
#               on_damage_dealt is excluded — it depends on damage amount,
#               not the effect name, and is appended at the call site.
# emoji/valence: presentation for the Status Tray. valence is "buff" (helps the
#               side it sits on) or "debuff" (harms it).
# float:        the floating combat label — { label, nudge }. The popup text is
#               composed as "<emoji> <label>" so the Tray and the popup share ONE
#               emoji (see float_label()). Colors live in ThemeData. An effect with
#               no "float" entry shows no status popup: heal/leech show an HP-gain
#               amount built at the call site, and slow has no popup.
const EFFECTS: Dictionary = {
	"burn":    { "status_shape": { "stacks": 0, "tick_damage_bonus": 0, "next_tick_bonus": 0, "by_source": {} }, "count_field": "stacks",    "triggers": ["on_burn_applied", "on_status_applied:burn"], "emoji": "🔥", "valence": "debuff", "float": { "label": "BURN", "nudge": -4.0 } },
	"poison":  { "status_shape": { "stacks": 0, "tick_damage_bonus": 0, "next_tick_bonus": 0, "by_source": {} }, "count_field": "stacks",    "triggers": ["on_status_applied:poison"], "emoji": "🧪", "valence": "debuff", "float": { "label": "POISON", "nudge": -4.0 } },
	"armor":   { "status_shape": { "value": 0, "floor": 0, "regen_blocked": false, "stripped": false, "by_source": {} }, "count_field": "value", "triggers": [], "emoji": "🛡️", "valence": "buff", "float": { "label": "ARMOR", "nudge": -4.0 } },
	"plating": { "status_shape": { "value": 0, "reduces_dot": false, "by_source": {} }, "count_field": "value",     "triggers": [], "emoji": "🧱", "valence": "buff", "float": { "label": "PLATE", "nudge": -4.0 } },
	"blind":   { "status_shape": { "percent": 0 },                                     "count_field": "percent",   "triggers": ["on_status_applied:blind"], "emoji": "🙈", "valence": "debuff", "float": { "label": "BLIND", "nudge": -4.0 } },
	"shock":   { "status_shape": { "n": 0, "effective_stack_bonus": 0, "cleanse_immune": false }, "count_field": "n", "triggers": ["on_status_applied:shock"], "emoji": "⚡", "valence": "debuff", "float": { "label": "SHOCK", "nudge": -4.0 } },
	"slow":    { "status_shape": { "n": 0 },                                           "count_field": "n",         "triggers": [], "emoji": "🐌", "valence": "debuff" },
	"haste":   { "status_shape": { "reduction": 0, "reduction_bonus_deciseconds": 0 }, "count_field": "reduction", "triggers": ["on_haste_applied"], "emoji": "💨", "valence": "buff", "float": { "label": "HASTE", "nudge": -4.0 } },
	"weaken":  { "status_shape": { "stacks": 0, "ticks": 0, "duration_bonus": 0 },     "count_field": "stacks",    "triggers": ["on_status_applied:weaken"], "emoji": "📉", "valence": "debuff", "float": { "label": "WEAKEN", "nudge": -4.0 } },
	"curse":   { "status_shape": { "stacks": 0, "damage_amplifier": 0 },               "count_field": "stacks",    "triggers": ["on_status_applied:curse"], "emoji": "🌑", "valence": "debuff", "float": { "label": "CURSE", "nudge": -4.0 } },
	"leech":   { "status_shape": { "bonus": 0, "double": false },                      "count_field": "",          "triggers": ["on_leech"], "emoji": "🩸", "valence": "buff" },
	"heal":    { "status_shape": {},                                                   "count_field": "",          "triggers": ["on_heal_applied"], "emoji": "💚", "valence": "buff" },
	"cleanse": { "status_shape": {},                                                   "count_field": "",          "triggers": [], "emoji": "🫧", "valence": "buff", "float": { "label": "CLEANSE", "nudge": -4.0 } },
}


# Side-wide status fields — not owned by any single effect, but living in a side's
# status pool alongside the per-effect dicts. Declared here so the set is defined in
# one place; StatusSystem.empty_statuses() builds them from this instead of hardcoding.
const SIDE_WIDE_FIELDS: Dictionary = {
	# Signed cooldown shift on this side's fire timers (the modify_cooldown atom).
	"cooldown_modifier_deciseconds": 0,
	# One-shot bonus consumed by this side's NEXT damaging direct hit (prime_next_hit).
	"next_hit_bonus": 0,
}


# The author-writable modifier fields of a status: every status_shape key that is
# neither the headline count (count_field) nor the internal by_source attribution
# ledger. These are the only fields a set_status_field ability atom may target —
# everything else (the count, the ledger) is owned by StatusSystem's apply/tick/
# decrement. test_ability_data locks every set_status_field against this.
static func modifier_fields(status: String) -> Array[String]:
	var entry: Dictionary = EFFECTS.get(status, {}) as Dictionary
	var shape: Dictionary = entry.get("status_shape", {}) as Dictionary
	var count_field: String = entry.get("count_field", "") as String
	var result: Array[String] = []
	for field: String in shape.keys():
		if field == count_field or field == "by_source":
			continue
		result.append(field)
	return result


static func is_modifier_field(status: String, field: String) -> bool:
	return modifier_fields(status).has(field)


# The floating combat label for an on-fire effect — { text, nudge } — or {} if the
# effect has no status popup. Text is composed from the one canonical emoji so the
# popup and the Status Tray can't drift. Color comes from ThemeData.FLOAT_LABEL_COLORS
# at the call site (ThemeData owns colors).
static func float_label(effect: String) -> Dictionary:
	var entry: Dictionary = EFFECTS.get(effect, {}) as Dictionary
	if not entry.has("float"):
		return {}
	var f: Dictionary = entry["float"] as Dictionary
	return { "text": "%s %s" % [entry["emoji"] as String, f["label"] as String], "nudge": f["nudge"] as float }
