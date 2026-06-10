class_name StatusGlossary

# One-line definitions for the [keyword] tags used in ability descriptions. The
# Abilities Panel renders these as hoverable links; mousing over one shows a
# Keyword Tooltip with the matching definition.

const DEFINITIONS: Dictionary = {
	"burn": "Deals damage each second, then loses a stack. Armour absorbs half.",
	"poison": "Deals damage each second. Stacks are permanent — they never decay.",
	"shock": "Slows the afflicted side's cooldowns. More stacks, slower fires.",
	"weaken": "Reduces the afflicted side's damage output while it lasts.",
	"armor": "Absorbs incoming physical damage, depleting as it does.",
	"plating": "Flat reduction to every incoming hit. Never depletes.",
	"blind": "Chance for the afflicted side's fires to miss (cap 50%).",
	"curse": "Charges that amplify each incoming hit and damage-over-time tick, spent one per damaging event.",
	"leech": "Heals the attacker for the damage their hit dealt.",
	"heal": "Restores HP to your side.",
	"cleanse": "Removes a stack from each debuff on your side.",
	"haste": "Reduces your cooldowns when it triggers.",
	"freeze": "A frozen element is paused — it cannot fire until it thaws.",
	"multicast": "The element fires more than once per cooldown.",
}


static func get_definition(keyword: String) -> String:
	return DEFINITIONS.get(keyword.to_lower(), "") as String


static func has_keyword(keyword: String) -> bool:
	return DEFINITIONS.has(keyword.to_lower())


# All keyword tags, longest-first, so bracket replacement is unambiguous.
static func keywords() -> Array:
	return DEFINITIONS.keys()
