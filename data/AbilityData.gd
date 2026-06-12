class_name AbilityData

# One Ability per element, keyed by element id. Pure data — ElementData stays pure
# stats. Returns {} for elements without an ability (all T1 carry description-only
# entries; their on-fire Action lives in the element's "effect" field).
#
# See systems/AbilitySystem.gd for the effect/trigger vocabulary and
# docs/adr/0004-ability-system-architecture.md for the design. All durations,
# intervals, and cooldown modifiers are integer deciseconds. Plating is integer.
#
# Trigger-mix policy (rebalanced 2026-06-12): combat_start is reserved for true
# setup (walls, freezes, deep curses, max-HP bulk); "every X seconds" periodic is
# capped at 3 iconic engines (lava, volcano, rainbow) since the element's own
# cooldown already provides a rhythm — on_activate rides it instead. Reactives
# (on_*) are the synergy glue; passives modify rules or carry adjacency auras.


static func get_ability(element_id: String) -> Dictionary:
	return ABILITIES.get(element_id, {})


# Human-readable label per ability trigger. Fixed triggers only; "periodic",
# "on_status_applied", and "on_activate" are formatted in trigger_label() from
# their extra fields.
const TRIGGER_LABELS: Dictionary = {
	"combat_start":      "Combat start",
	"passive":           "Passive",
	"passive_on_hit":    "On hit",
	"on_burn_applied":   "On [burn]",
	"on_heal_applied":   "On [heal]",
	"on_leech":          "On [leech]",
	"on_damage_dealt":   "On damage dealt",
	"on_poison_tick":    "On [poison] tick",
	"on_burn_tick":      "On [burn] tick",
	"on_armor_stripped": "On armor strip",
	"on_haste_applied":  "On [haste]",
}


# The single source for how an ability's Trigger reads on screen — the Battle
# Summary parenthetical and the Compendium card both call this, so the two can't
# drift. Fixed triggers come from TRIGGER_LABELS; periodic/on_status_applied/
# on_activate are built from their extra fields; a Multicast suffix is appended
# when present. Empty trigger (T1 / no ability) → "".
static func trigger_label(ability: Dictionary) -> String:
	var trigger: String = ability.get("trigger", "") as String
	if trigger.is_empty():
		return ""
	var label: String = ""
	match trigger:
		"periodic":
			var seconds_text: String = "%.1f" % (float(ability.get("interval_deciseconds", 0) as int) / 10.0)
			if seconds_text.ends_with(".0"):
				seconds_text = seconds_text.left(seconds_text.length() - 2)
			label = "Every %ss" % seconds_text
		"on_status_applied":
			label = "On [%s]" % (ability.get("status", "") as String)
		"on_activate":
			var every_n: int = ability.get("every_n", 1) as int
			label = ("Every %d activations" % every_n) if every_n > 1 else "On activation"
		_:
			label = TRIGGER_LABELS.get(trigger, trigger) as String
	var multicast: int = ability.get("multicast", 0) as int
	if multicast > 0:
		label += "  ×%d" % (multicast + 1)
	return label


const ABILITIES: Dictionary = {
	# ── T1 ───────────────────────────────────────────────────────────────────
	"water":     { "description": "Apply 1 [cleanse] to your side." },
	"fire":      { "description": "Apply 1 [burn] to the opponent." },
	"air":       { "description": "Apply 1 [haste] to your side." },
	"earth":     { "description": "Apply 1 [armor] to your side." },
	"lightning": { "description": "Apply 1 [shock] to the opponent." },
	"nature":    { "description": "Apply 1 [heal] to your side." },
	"light":     { "description": "Apply 1 [blind] to the opponent." },
	"dark":      { "description": "Apply 1 [curse] to the opponent." },
	"metal":     { "description": "Apply 1 [plating] to your side." },
	"fungus":    { "description": "Apply 1 [poison] to the opponent." },
	"blood":     { "description": "Apply 1 [leech] to your side." },
	"frost":     { "description": "Apply 1 [weaken] to the opponent." },

	# ── T2 — Original cross ──────────────────────────────────────────────────
	"steam": { "trigger": "on_burn_applied", "description": "When [burn] is applied, deal 1 bonus damage to the opponent.",
		"effects": [{ "kind": "deal_damage", "amount": 1, "target": "opponent" }] },
	"rain": { "trigger": "on_activate", "description": "Each activation washes your side: apply 1 [cleanse].",
		"effects": [{ "kind": "apply_status", "status": "cleanse", "amount": 1, "target": "own" }] },
	"mud": { "trigger": "combat_start", "description": "All opponent cooldowns +0.8s for the combat.",
		"effects": [{ "kind": "modify_cooldown", "deciseconds": 8, "target": "opponent" }] },
	"smoke": { "trigger": "combat_start", "description": "Apply 2 [blind] + 1 [curse] to the opponent.",
		"effects": [{ "kind": "apply_status", "status": "blind", "amount": 2, "target": "opponent" },
			{ "kind": "apply_status", "status": "curse", "amount": 1, "target": "opponent" }] },
	"lava": { "trigger": "periodic", "interval_deciseconds": 60, "description": "Every 6s, apply 2 [burn] to the opponent.",
		"effects": [{ "kind": "apply_status", "status": "burn", "amount": 2, "target": "opponent" }] },
	"dust": { "trigger": "passive_on_hit", "description": "15% chance to apply 1 [weaken] on any damage hit.",
		"effects": [{ "status": "weaken", "chance": 15, "target": "opponent" }] },

	# ── T2 — Lightning family ────────────────────────────────────────────────
	"surge": { "trigger": "on_activate", "description": "Each activation applies 1 [shock]; if the opponent has 3+ [shock], deal 2 bonus damage.",
		"effects": [{ "kind": "apply_status", "status": "shock", "amount": 1, "target": "opponent" },
			{ "kind": "deal_damage", "amount": 2, "target": "opponent",
				"when": [{ "kind": "target_has_status", "target": "opponent", "status": "shock", "at_least": 3 }] }] },
	"static": { "trigger": "passive_on_hit", "description": "20% chance to apply 1 [shock] on any damage hit.",
		"effects": [{ "status": "shock", "chance": 20, "target": "opponent" }] },
	# ── T2 — Self ────────────────────────────────────────────────────────────
	"sea": { "trigger": "on_activate", "every_n": 2, "description": "Every 2nd activation, apply 2 [cleanse] to your side.",
		"effects": [{ "kind": "apply_status", "status": "cleanse", "amount": 2, "target": "own" }] },
	"blaze": { "trigger": "passive", "multicast": 1, "description": "[burn] ticks deal +1 damage; fires twice per cooldown.",
		"effects": [{ "kind": "set_status_field", "status": "burn", "field": "tick_damage_bonus", "value": 1, "target": "opponent" }] },
	"boulder": { "trigger": "combat_start", "description": "Apply 4 [armor] to your side.",
		"effects": [{ "kind": "apply_status", "status": "armor", "amount": 4, "target": "own" }] },
	"plasma": { "trigger": "passive", "description": "[shock] slow is calculated as if 3 extra stacks exist.",
		"effects": [{ "kind": "set_status_field", "status": "shock", "field": "effective_stack_bonus", "value": 3, "target": "opponent" }] },
	"forest": { "trigger": "on_activate", "every_n": 2, "description": "Every 2nd activation, [heal] your side for 2.",
		"effects": [{ "kind": "apply_status", "status": "heal", "amount": 2, "target": "own" }] },
	"radiance": { "trigger": "on_activate", "every_n": 2, "description": "Every 2nd activation, apply 2 [blind] to the opponent.",
		"effects": [{ "kind": "apply_status", "status": "blind", "amount": 2, "target": "opponent" }] },
	"void": { "trigger": "combat_start", "description": "Apply a deep [curse] (10 charges) to the opponent.",
		"effects": [{ "kind": "apply_status", "status": "curse", "amount": 10, "target": "opponent" }] },
	"mycelium": { "trigger": "on_status_applied", "status": "poison", "description": "Each new [poison] stack also deals 1 instant damage.",
		"effects": [{ "kind": "deal_damage", "amount": 1, "target": "opponent" }] },
	"freeze": { "trigger": "combat_start", "description": "[freeze] one opponent element for 8s and apply 2 [weaken].",
		"effects": [{ "kind": "freeze", "deciseconds": 80, "count": 1, "target": "opponent" },
			{ "kind": "apply_status", "status": "weaken", "amount": 2, "target": "opponent" }] },
	"ichor": { "trigger": "passive", "multicast": 1, "description": "[leech] heals double; fires twice per cooldown.",
		"effects": [{ "kind": "set_status_field", "status": "leech", "field": "double", "value": true, "target": "own" }] },

	# ── T2 — Nature family ───────────────────────────────────────────────────
	"ember": { "trigger": "on_heal_applied", "adjacency_upgrade": true, "description": "When [heal] fires on your side, apply 1 [burn] to the opponent.",
		"effects": [{ "kind": "apply_status", "status": "burn", "amount": 1, "target": "opponent" }] },
	"pollen": { "trigger": "passive_on_hit", "description": "15% chance to apply 1 [poison] on any damage hit.",
		"effects": [{ "status": "poison", "chance": 15, "target": "opponent" }] },
	"root": { "trigger": "passive", "aura": { "adjacent_damage_bonus": 1 }, "description": "Adjacent elements deal +1 damage — roots feed their neighbors.",
		"effects": [] },
	"photosynthesis": { "trigger": "on_heal_applied", "adjacency_upgrade": true, "description": "Each [heal] reduces your cooldowns by 0.2s.",
		"effects": [{ "kind": "modify_cooldown", "deciseconds": -2, "target": "own" }] },

	# ── T2 — Light family ────────────────────────────────────────────────────
	"solar": { "trigger": "on_activate", "description": "Each activation applies 1 [burn] + 1 [blind] to the opponent.",
		"effects": [{ "kind": "apply_status", "status": "burn", "amount": 1, "target": "opponent" },
			{ "kind": "apply_status", "status": "blind", "amount": 1, "target": "opponent" }] },
	"crystal": { "trigger": "on_activate", "every_n": 2, "description": "Every 2nd activation, focus the light: your side's next hit deals +2 damage.",
		"effects": [{ "kind": "prime_next_hit", "amount": 2, "target": "own" }] },
	"lucent": { "trigger": "on_activate", "every_n": 2, "description": "Every 2nd activation, the guiding glow grants 1 [haste] to your side.",
		"effects": [{ "kind": "apply_status", "status": "haste", "amount": 1, "target": "own" }] },

	# ── T2 — Dark family ─────────────────────────────────────────────────────
	"blight": { "trigger": "on_status_applied", "status": "poison", "description": "Each new [poison] primes the opponent's next [poison] tick for +1 damage.",
		"effects": [{ "kind": "prime_dot", "status": "poison", "amount": 1, "target": "opponent" }] },
	"shade": { "trigger": "passive", "description": "Your [curse] deals +1 extra damage per consumed charge.",
		"effects": [{ "kind": "set_status_field", "status": "curse", "field": "damage_amplifier", "value": 1, "target": "opponent" }] },

	# ── T2 — Metal family ────────────────────────────────────────────────────
	"molten": { "trigger": "on_activate", "every_n": 2, "description": "Every 2nd activation, superheat: prime the next [burn] tick for +2 damage and gain 1 [plating].",
		"effects": [{ "kind": "prime_dot", "status": "burn", "amount": 2, "target": "opponent" },
			{ "kind": "apply_status", "status": "plating", "amount": 1, "target": "own" }] },
	# ── T2 — Fungus family ───────────────────────────────────────────────────
	"rootrot": { "trigger": "on_activate", "description": "On activation, apply 1 [poison] + 1 [weaken] to the opponent.",
		"effects": [{ "kind": "apply_status", "status": "poison", "amount": 1, "target": "opponent" },
			{ "kind": "apply_status", "status": "weaken", "amount": 1, "target": "opponent" }] },
	"sporeflow": { "trigger": "on_activate", "description": "Each activation applies 1 [poison]; +1 more if the opponent has [weaken].",
		"effects": [{ "kind": "apply_status", "status": "poison", "amount": 1, "target": "opponent" },
			{ "kind": "apply_status", "status": "poison", "amount": 1, "target": "opponent",
				"when": [{ "kind": "target_has_status", "target": "opponent", "status": "weaken", "at_least": 1 }] }] },
	"haze": { "trigger": "passive_on_hit", "description": "15% chance to apply 1 [blind] on any damage hit.",
		"effects": [{ "status": "blind", "chance": 15, "target": "opponent" }] },

	# ── T2 — Blood cross ─────────────────────────────────────────────────────
	"gore": { "trigger": "on_activate", "description": "On activation, lifesteal for the damage dealt and apply 1 [weaken] to the opponent.",
		"effects": [{ "kind": "apply_status", "status": "weaken", "amount": 1, "target": "opponent" }] },
	"fever": { "trigger": "on_burn_applied", "description": "When [burn] is applied, the fever feeds: trigger [leech] once.",
		"effects": [{ "kind": "apply_status", "status": "leech", "amount": 1, "target": "own" }] },
	"nightveil": { "trigger": "on_leech", "description": "Each [leech] trigger dims their sight: apply 1 [blind].",
		"effects": [{ "kind": "apply_status", "status": "blind", "amount": 1, "target": "opponent" }] },
	# ── T2 — Frost cross ─────────────────────────────────────────────────────
	"frostburn": { "trigger": "on_burn_applied", "description": "When [burn] is applied, also apply 1 [weaken] to the opponent.",
		"effects": [{ "kind": "apply_status", "status": "weaken", "amount": 1, "target": "opponent" }] },
	"permafrost": { "trigger": "combat_start", "description": "[freeze] one opponent element for 5s.",
		"effects": [{ "kind": "freeze", "deciseconds": 50, "count": 1, "target": "opponent" }] },
	"hail": { "trigger": "on_activate", "multicast": 1, "description": "Pelts twice per cooldown, each volley applying 1 [weaken].",
		"effects": [{ "kind": "apply_status", "status": "weaken", "amount": 1, "target": "opponent" }] },
	"whiteout": { "trigger": "on_status_applied", "status": "blind", "description": "When [blind] is applied, also apply 1 [weaken] — can't see, can't swing.",
		"effects": [{ "kind": "apply_status", "status": "weaken", "amount": 1, "target": "opponent" }] },
	"wither": { "trigger": "on_activate", "every_n": 2, "description": "Every 2nd activation, apply 2 [weaken] to the opponent and 1 [cleanse] to your side.",
		"effects": [{ "kind": "apply_status", "status": "weaken", "amount": 2, "target": "opponent" },
			{ "kind": "apply_status", "status": "cleanse", "amount": 1, "target": "own" }] },
	"tempered": { "trigger": "combat_start", "description": "Apply 1 [plating] and 2 [armor] to your side.",
		"effects": [{ "kind": "apply_status", "status": "plating", "amount": 1, "target": "own" },
			{ "kind": "apply_status", "status": "armor", "amount": 2, "target": "own" }] },
	# ── T2 — Extended-to-extended ────────────────────────────────────────────
	"rot": { "trigger": "on_activate", "description": "On activation, apply 1 [poison] + 1 [shock] to the opponent.",
		"effects": [{ "kind": "apply_status", "status": "poison", "amount": 1, "target": "opponent" },
			{ "kind": "apply_status", "status": "shock", "amount": 1, "target": "opponent" }] },
	"moldsteel": { "trigger": "on_activate", "description": "On activation, gain 1 [plating] and apply 1 [poison] to the opponent.",
		"effects": [{ "kind": "apply_status", "status": "plating", "amount": 1, "target": "own" },
			{ "kind": "apply_status", "status": "poison", "amount": 1, "target": "opponent" }] },
	"voltspore": { "trigger": "on_activate", "multicast": 1, "description": "Fires twice per cooldown, each activation applying 1 [shock].",
		"effects": [{ "kind": "apply_status", "status": "shock", "amount": 1, "target": "opponent" }] },
	"ironwood": { "trigger": "combat_start", "description": "Ironwood bulk: your side gains +6 max HP for the fight.",
		"effects": [{ "kind": "add_max_hp", "amount": 6, "target": "own" }] },
	"hexcore": { "trigger": "on_armor_stripped", "description": "When the opponent's [armor] is stripped, the hex erupts: apply 2 [curse].",
		"effects": [{ "kind": "apply_status", "status": "curse", "amount": 2, "target": "opponent" }] },
	"umbra": { "trigger": "on_status_applied", "status": "curse", "description": "When [curse] is applied, also apply 1 [blind] to the opponent.",
		"effects": [{ "kind": "apply_status", "status": "blind", "amount": 1, "target": "opponent" }] },

	# ── T3 ───────────────────────────────────────────────────────────────────
	"cloud": { "trigger": "on_activate", "every_n": 2, "description": "Every 2nd activation, ride the cloud: gain 1 [haste] and 1 [cleanse].",
		"effects": [{ "kind": "apply_status", "status": "haste", "amount": 1, "target": "own" },
			{ "kind": "apply_status", "status": "cleanse", "amount": 1, "target": "own" }] },
	"geyser": { "trigger": "on_activate", "every_n": 3, "description": "Every 3rd activation, erupt: deal 5 bonus damage and apply 2 [weaken].",
		"effects": [{ "kind": "deal_damage", "amount": 5, "target": "opponent" },
			{ "kind": "apply_status", "status": "weaken", "amount": 2, "target": "opponent" }] },
	"fog": { "trigger": "combat_start", "description": "Apply 3 [blind] + 1 [curse] to the opponent.",
		"effects": [{ "kind": "apply_status", "status": "blind", "amount": 3, "target": "opponent" },
			{ "kind": "apply_status", "status": "curse", "amount": 1, "target": "opponent" }] },
	"storm": { "trigger": "on_activate", "every_n": 3, "description": "Every 3rd activation, 2 [shock] to the opponent and 1 [haste] to your side.",
		"effects": [{ "kind": "apply_status", "status": "shock", "amount": 2, "target": "opponent" },
			{ "kind": "apply_status", "status": "haste", "amount": 1, "target": "own" }] },
	"swamp": { "trigger": "combat_start", "description": "All opponent cooldowns +1.5s and apply 2 [weaken].",
		"effects": [{ "kind": "modify_cooldown", "deciseconds": 15, "target": "opponent" },
			{ "kind": "apply_status", "status": "weaken", "amount": 2, "target": "opponent" }] },
	"brick": { "trigger": "combat_start", "description": "Apply 4 [armor] and 2 [plating] to your side.",
		"effects": [{ "kind": "apply_status", "status": "armor", "amount": 4, "target": "own" },
			{ "kind": "apply_status", "status": "plating", "amount": 2, "target": "own" }] },
	"obsidian": { "trigger": "passive", "aura": { "adjacent_damage_bonus": 2 }, "description": "Adjacent elements deal +2 damage — razor glass edges.",
		"effects": [] },
	"volcano": { "trigger": "periodic", "interval_deciseconds": 40, "multicast": 1, "description": "Every 4s, apply 3 [burn]; fires twice per cooldown.",
		"effects": [{ "kind": "apply_status", "status": "burn", "amount": 3, "target": "opponent" }] },
	"sand": { "trigger": "passive_on_hit", "description": "25% chance to apply 1 [weaken] on any damage hit.",
		"effects": [{ "status": "weaken", "chance": 25, "target": "opponent" }] },
	"sandstorm": { "trigger": "on_activate", "description": "Each activation scours: apply 1 [blind] + 1 [weaken].",
		"effects": [{ "kind": "apply_status", "status": "blind", "amount": 1, "target": "opponent" },
			{ "kind": "apply_status", "status": "weaken", "amount": 1, "target": "opponent" }] },
	"clay": { "trigger": "on_activate", "every_n": 2, "description": "Every 2nd activation, reshape itself: gain 1 [armor].",
		"effects": [{ "kind": "apply_status", "status": "armor", "amount": 1, "target": "own" }] },
	"glacier": { "trigger": "combat_start", "description": "[freeze] two opponent elements for 5s.",
		"effects": [{ "kind": "freeze", "deciseconds": 50, "count": 2, "target": "opponent" }] },
	"blizzard": { "trigger": "on_activate", "multicast": 1, "description": "Fires twice per cooldown, each pass applying 1 [weaken] + 1 [shock].",
		"effects": [{ "kind": "apply_status", "status": "weaken", "amount": 1, "target": "opponent" },
			{ "kind": "apply_status", "status": "shock", "amount": 1, "target": "opponent" }] },
	"tundra": { "trigger": "on_status_applied", "status": "weaken", "description": "Each [weaken] seeps into the ground: +0.1s to all opponent cooldowns.",
		"effects": [{ "kind": "modify_cooldown", "deciseconds": 1, "target": "opponent" }] },
	"rainforest": { "trigger": "on_heal_applied", "description": "Each [heal] also applies 1 [cleanse] to your side.",
		"effects": [{ "kind": "apply_status", "status": "cleanse", "amount": 1, "target": "own" }] },
	"hurricane": { "trigger": "on_activate", "every_n": 2, "description": "Every 2nd activation: 2 [shock], and the spinning winds shave 0.1s off your cooldowns.",
		"effects": [{ "kind": "apply_status", "status": "shock", "amount": 2, "target": "opponent" },
			{ "kind": "modify_cooldown", "deciseconds": -1, "target": "own" }] },
	"tsunami": { "trigger": "on_activate", "every_n": 4, "description": "Builds for 4 activations, then crashes: deal 8 bonus damage and apply 3 [weaken].",
		"effects": [{ "kind": "deal_damage", "amount": 8, "target": "opponent" },
			{ "kind": "apply_status", "status": "weaken", "amount": 3, "target": "opponent" }] },
	"eclipse": { "trigger": "combat_start", "description": "Apply 3 [blind] + 2 [curse]; your elements deal +2 damage while [curse] is active.",
		"effects": [{ "kind": "apply_status", "status": "blind", "amount": 3, "target": "opponent" },
			{ "kind": "apply_status", "status": "curse", "amount": 2, "target": "opponent" },
			{ "kind": "set_status_field", "status": "curse", "field": "damage_amplifier", "value": 2, "target": "opponent" }] },
	"plague": { "trigger": "on_activate", "multicast": 1, "description": "Fires twice per cooldown, each activation applying 2 [poison].",
		"effects": [{ "kind": "apply_status", "status": "poison", "amount": 2, "target": "opponent" }] },
	"underrot": { "trigger": "passive", "description": "[poison] ticks deal +1 damage.",
		"effects": [{ "kind": "set_status_field", "status": "poison", "field": "tick_damage_bonus", "value": 1, "target": "opponent" }] },
	"inferno": { "trigger": "on_burn_tick", "chance": 50, "description": "[burn] ticks have a 50% chance to reignite: +1 [burn].",
		"effects": [{ "kind": "apply_status", "status": "burn", "amount": 1, "target": "opponent" }] },
	"hemorrhage": { "trigger": "on_leech", "description": "Each [leech] tears the wound wider: deal 2 bonus damage.",
		"effects": [{ "kind": "deal_damage", "amount": 2, "target": "opponent" }] },
	"carnage": { "trigger": "passive", "multicast": 1, "description": "Fires twice per cooldown.",
		"effects": [] },
	"meteorite": { "trigger": "combat_start", "description": "Deal 5 bonus damage; apply 2 [armor] + 1 [plating] to your side.",
		"effects": [{ "kind": "deal_damage", "amount": 5, "target": "opponent" },
			{ "kind": "apply_status", "status": "armor", "amount": 2, "target": "own" },
			{ "kind": "apply_status", "status": "plating", "amount": 1, "target": "own" }] },
	"rainbow": { "trigger": "periodic", "interval_deciseconds": 50, "description": "Every 5s, apply 1 [armor], [heal] 3, 1 [cleanse], and 1 [haste] to your side.",
		"effects": [{ "kind": "apply_status", "status": "armor", "amount": 1, "target": "own" },
			{ "kind": "apply_status", "status": "heal", "amount": 3, "target": "own" },
			{ "kind": "apply_status", "status": "cleanse", "amount": 1, "target": "own" },
			{ "kind": "apply_status", "status": "haste", "amount": 1, "target": "own" },
			{ "kind": "haste_timers" }] },
	"plant": { "trigger": "on_activate", "every_n": 2, "description": "Every 2nd activation, [heal] your side for 2 and apply 1 [cleanse].",
		"effects": [{ "kind": "apply_status", "status": "heal", "amount": 2, "target": "own" },
			{ "kind": "apply_status", "status": "cleanse", "amount": 1, "target": "own" }] },
	"ash": { "trigger": "on_burn_applied", "description": "When [burn] is applied, apply 1 [blind] + 1 [weaken] to the opponent.",
		"effects": [{ "kind": "apply_status", "status": "blind", "amount": 1, "target": "opponent" },
			{ "kind": "apply_status", "status": "weaken", "amount": 1, "target": "opponent" }] },
	"ancientgrove": { "trigger": "combat_start", "description": "Ancient bulk: your side gains +10 max HP and 2 [armor] for the fight.",
		"effects": [{ "kind": "add_max_hp", "amount": 10, "target": "own" },
			{ "kind": "apply_status", "status": "armor", "amount": 2, "target": "own" }] },
	"voidrift": { "trigger": "combat_start", "description": "Apply a deep [curse] (10 charges) + 2 [blind] to the opponent; all opponent cooldowns +0.5s.",
		"effects": [{ "kind": "apply_status", "status": "curse", "amount": 10, "target": "opponent" },
			{ "kind": "apply_status", "status": "blind", "amount": 2, "target": "opponent" },
			{ "kind": "modify_cooldown", "deciseconds": 5, "target": "opponent" }] },

	# ── Passive-modifier abilities ────────────────────────────────────────────
	"gust": { "trigger": "passive", "description": "[haste] reduces cooldowns by 0.5s instead of 0.3s.",
		"effects": [{ "kind": "set_status_field", "status": "haste", "field": "reduction_bonus_deciseconds", "value": 2, "target": "own" }] },
	"pulse": { "trigger": "passive", "description": "[leech] heals damage + 1 instead of exact damage.",
		"effects": [{ "kind": "set_status_field", "status": "leech", "field": "bonus", "value": 1, "target": "own" }] },
	"steel": { "trigger": "passive", "description": "[plating] also reduces [burn] and [poison] tick damage.",
		"effects": [{ "kind": "set_status_field", "status": "plating", "field": "reduces_dot", "value": true, "target": "own" }] },
	"mountain": { "trigger": "passive", "description": "Your [armor] cannot be reduced below 2 stacks.",
		"effects": [{ "kind": "set_status_field", "status": "armor", "field": "floor", "value": 2, "target": "own" }] },
	"blackice": { "trigger": "passive", "description": "[weaken] on the opponent lasts 2 extra ticks before expiring.",
		"effects": [{ "kind": "set_status_field", "status": "weaken", "field": "duration_bonus", "value": 2, "target": "opponent" }] },
	"tempest": { "trigger": "passive", "description": "[shock] on the opponent cannot be cleansed away.",
		"effects": [{ "kind": "set_status_field", "status": "shock", "field": "cleanse_immune", "value": true, "target": "opponent" }] },
	"acid": { "trigger": "passive", "description": "Opponent [armor] stripped during this combat does not regenerate.",
		"effects": [{ "kind": "set_status_field", "status": "armor", "field": "regen_blocked", "value": true, "target": "opponent" }] },

	# ── Tick / armor / haste event reactives ──────────────────────────────────
	"rust": { "trigger": "on_armor_stripped", "description": "When the opponent's [armor] is stripped, deal 1 bonus damage.",
		"effects": [{ "kind": "deal_damage", "amount": 1, "target": "opponent" }] },
	# ── T4 — Phenomena (designed 2026-06-12; the payoff tier) ─────────────────
	"iceage": { "trigger": "combat_start", "description": "[freeze] two opponent elements for 8s and apply 3 [weaken].",
		"effects": [{ "kind": "freeze", "deciseconds": 80, "count": 2, "target": "opponent" },
			{ "kind": "apply_status", "status": "weaken", "amount": 3, "target": "opponent" }] },
	"maelstrom": { "trigger": "on_activate", "multicast": 2, "description": "The vortex strikes three times per cooldown, each pass applying 1 [shock] + 1 [weaken].",
		"effects": [{ "kind": "apply_status", "status": "shock", "amount": 1, "target": "opponent" },
			{ "kind": "apply_status", "status": "weaken", "amount": 1, "target": "opponent" }] },
	"tectonic": { "trigger": "on_activate", "description": "Each upheaval deals 4 bonus damage and raises 2 [armor].",
		"effects": [{ "kind": "deal_damage", "amount": 4, "target": "opponent" },
			{ "kind": "apply_status", "status": "armor", "amount": 2, "target": "own" }] },
	"supernova": { "trigger": "on_activate", "every_n": 3, "description": "Builds to detonation: every 3rd activation, deal 10 bonus damage and apply 3 [burn] + 2 [blind].",
		"effects": [{ "kind": "deal_damage", "amount": 10, "target": "opponent" },
			{ "kind": "apply_status", "status": "burn", "amount": 3, "target": "opponent" },
			{ "kind": "apply_status", "status": "blind", "amount": 2, "target": "opponent" }] },
	"singularity": { "trigger": "on_activate", "description": "Each activation drags them deeper: 1 [curse] and +0.1s to all opponent cooldowns.",
		"effects": [{ "kind": "apply_status", "status": "curse", "amount": 1, "target": "opponent" },
			{ "kind": "modify_cooldown", "deciseconds": 1, "target": "opponent" }] },
	"worldtree": { "trigger": "on_activate", "description": "It keeps growing: each activation [heal]s your side for 3 and grants +1 max HP.",
		"effects": [{ "kind": "apply_status", "status": "heal", "amount": 3, "target": "own" },
			{ "kind": "add_max_hp", "amount": 1, "target": "own" }] },
	"pandemic": { "trigger": "on_poison_tick", "description": "Every [poison] tick spreads the strain: +1 [poison]. It never stops.",
		"effects": [{ "kind": "apply_status", "status": "poison", "amount": 1, "target": "opponent" }] },
	"ragnarok": { "trigger": "on_damage_dealt", "chance": 20, "description": "When your side deals damage, 20% chance the end cascades: deal 2 bonus damage.",
		"effects": [{ "kind": "deal_damage", "amount": 2, "target": "opponent" }] },
	"primordial": { "trigger": "passive", "aura": { "adjacent_damage_bonus": 3 }, "description": "Adjacent elements deal +3 damage — the source empowers all.",
		"effects": [] },
	"aether": { "trigger": "on_activate", "every_n": 2, "description": "Every 2nd activation: gain 1 [haste] and your side's next hit deals +2 damage.",
		"effects": [{ "kind": "apply_status", "status": "haste", "amount": 1, "target": "own" },
			{ "kind": "prime_next_hit", "amount": 2, "target": "own" }] },
}
