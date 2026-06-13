class_name ElementData


# The element roster, built once at load and shared (zero-copy). The "duplicate
# before mutating" contract holds — every caller that writes to a def .duplicate()s
# it first. Mirrors AbilityData.ABILITIES (const data + O(1) lookup).
const ELEMENTS: Array[Dictionary] = [
		# ── Tier 1 ──────────────────────────────────────────────────────────────
		{ "id": "water",     "name": "Water",     "emoji": "💧", "tier": 1, "price": 5, "cooldown_deciseconds": 30, "damage": 1, "effect": "cleanse"  },
		{ "id": "fire",      "name": "Fire",      "emoji": "🔥", "tier": 1, "price": 5, "cooldown_deciseconds": 25, "damage": 2, "effect": "burn"     },
		{ "id": "air",       "name": "Air",       "emoji": "🌬️", "tier": 1, "price": 5, "cooldown_deciseconds": 20, "damage": 1, "effect": "haste"    },
		{ "id": "earth",     "name": "Earth",     "emoji": "🌍", "tier": 1, "price": 5, "cooldown_deciseconds": 40, "damage": 1, "effect": "armor"    },
		{ "id": "lightning", "name": "Lightning", "emoji": "⚡", "tier": 1, "price": 5, "cooldown_deciseconds": 18, "damage": 2, "effect": "shock"    },
		{ "id": "nature",    "name": "Nature",    "emoji": "🌿", "tier": 1, "price": 5, "cooldown_deciseconds": 35, "damage": 1, "effect": "heal"     },
		{ "id": "light",     "name": "Light",     "emoji": "☀️",  "tier": 1, "price": 5, "cooldown_deciseconds": 25, "damage": 1, "effect": "blind"    },
		{ "id": "dark",      "name": "Dark",      "emoji": "🌑", "tier": 1, "price": 5, "cooldown_deciseconds": 30, "damage": 2, "effect": "curse"    },
		{ "id": "metal",     "name": "Metal",     "emoji": "⚙️",  "tier": 1, "price": 5, "cooldown_deciseconds": 50, "damage": 3, "effect": "plating"  },
		{ "id": "fungus",    "name": "Fungus",    "emoji": "🍄", "tier": 1, "price": 5, "cooldown_deciseconds": 45, "damage": 1, "effect": "poison"   },
		{ "id": "blood",     "name": "Blood",     "emoji": "🩸", "tier": 1, "price": 5, "cooldown_deciseconds": 25, "damage": 1, "effect": "leech"    },
		{ "id": "frost",     "name": "Frost",     "emoji": "🌨️", "tier": 1, "price": 5, "cooldown_deciseconds": 30, "damage": 1, "effect": "weaken"   },
		# ── Tier 2 — cross-combos (original 4 × original 4) ─────────────────────
		{ "id": "steam",      "name": "Steam",       "emoji": "♨️",  "tier": 2, "price": 8, "cooldown_deciseconds": 35, "damage": 2, "family": "water" },
		{ "id": "rain",       "name": "Rain",        "emoji": "🌧️", "tier": 2, "price": 8, "cooldown_deciseconds": 30, "damage": 1 },
		{ "id": "mud",        "name": "Mud",         "emoji": "🟫", "tier": 2, "price": 8, "cooldown_deciseconds": 45, "damage": 1 },
		{ "id": "smoke",      "name": "Smoke",       "emoji": "🌫️", "tier": 2, "price": 8, "cooldown_deciseconds": 25, "damage": 1 },
		{ "id": "lava",       "name": "Lava",        "emoji": "🟠", "tier": 2, "price": 8, "cooldown_deciseconds": 50, "damage": 3, "family": "fire" },
		{ "id": "dust",       "name": "Dust",        "emoji": "💨", "tier": 2, "price": 8, "cooldown_deciseconds": 25, "damage": 1 },
		# ── Tier 2 — cross-combos (Lightning / Nature / Light / Dark / Metal / Fungus × original 4) ──
		{ "id": "surge",        "name": "Surge",        "emoji": "💫",  "tier": 2, "price": 8, "cooldown_deciseconds": 25, "damage": 2 },
		{ "id": "static",       "name": "Static",       "emoji": "💠",  "tier": 2, "price": 8, "cooldown_deciseconds": 20, "damage": 1 },
		{ "id": "ember",        "name": "Ember",        "emoji": "🪵",  "tier": 2, "price": 8, "cooldown_deciseconds": 30, "damage": 2 },
		{ "id": "pollen",       "name": "Pollen",       "emoji": "🌼",  "tier": 2, "price": 8, "cooldown_deciseconds": 25, "damage": 1 },
		{ "id": "root",         "name": "Root",         "emoji": "🌱",  "tier": 2, "price": 8, "cooldown_deciseconds": 45, "damage": 1 },
		{ "id": "solar",        "name": "Solar",        "emoji": "🌞",  "tier": 2, "price": 8, "cooldown_deciseconds": 25, "damage": 2 },
		{ "id": "crystal",      "name": "Crystal",      "emoji": "🔮",  "tier": 2, "price": 8, "cooldown_deciseconds": 40, "damage": 2 },
		{ "id": "blight",       "name": "Blight",       "emoji": "🥀",  "tier": 2, "price": 8, "cooldown_deciseconds": 35, "damage": 2 },
		{ "id": "shade",        "name": "Shade",        "emoji": "🌘",  "tier": 2, "price": 8, "cooldown_deciseconds": 40, "damage": 2 },
		{ "id": "rust",         "name": "Rust",         "emoji": "🟤",  "tier": 2, "price": 8, "cooldown_deciseconds": 45, "damage": 1 },
		{ "id": "molten",       "name": "Molten",       "emoji": "🔶",  "tier": 2, "price": 8, "cooldown_deciseconds": 50, "damage": 3 },
		{ "id": "sporeflow",    "name": "Sporeflow",    "emoji": "🫧",  "tier": 2, "price": 8, "cooldown_deciseconds": 30, "damage": 1 },
		{ "id": "haze",         "name": "Haze",         "emoji": "💚",  "tier": 2, "price": 8, "cooldown_deciseconds": 20, "damage": 1 },
		{ "id": "rootrot",      "name": "Rootrot",      "emoji": "🍂",  "tier": 2, "price": 8, "cooldown_deciseconds": 45, "damage": 2 },
		# ── Tier 2 — cross-combos (Blood × all) ─────────────────────────────────
		{ "id": "pulse",        "name": "Pulse",        "emoji": "💓",  "tier": 2, "price": 8, "cooldown_deciseconds": 30, "damage": 2 },
		{ "id": "fever",        "name": "Fever",        "emoji": "🌡️",  "tier": 2, "price": 8, "cooldown_deciseconds": 25, "damage": 2 },
		{ "id": "nightveil",    "name": "Nightveil",    "emoji": "💀",  "tier": 2, "price": 8, "cooldown_deciseconds": 30, "damage": 2 },
		{ "id": "gore",         "name": "Gore",         "emoji": "⚔️",  "tier": 2, "price": 8, "cooldown_deciseconds": 30, "damage": 2, "effect": "leech" },
		# ── Tier 2 — cross-combos (Frost × all) ─────────────────────────────────
		{ "id": "blackice",     "name": "Black Ice",    "emoji": "🧊",  "tier": 2, "price": 8, "cooldown_deciseconds": 35, "damage": 1 },
		{ "id": "frostburn",    "name": "Frostburn",    "emoji": "💙",  "tier": 2, "price": 8, "cooldown_deciseconds": 30, "damage": 2 },
		{ "id": "permafrost",   "name": "Permafrost",   "emoji": "🏔️",  "tier": 2, "price": 8, "cooldown_deciseconds": 50, "damage": 2 },
		{ "id": "hail",         "name": "Hail",         "emoji": "🔵",  "tier": 2, "price": 8, "cooldown_deciseconds": 25, "damage": 2 },
		{ "id": "whiteout",     "name": "Whiteout",     "emoji": "⬜",  "tier": 2, "price": 8, "cooldown_deciseconds": 25, "damage": 1 },
		{ "id": "wither",       "name": "Wither",       "emoji": "🍃",  "tier": 2, "price": 8, "cooldown_deciseconds": 35, "damage": 2 },
		{ "id": "tempered",     "name": "Tempered",     "emoji": "🛡️",  "tier": 2, "price": 8, "cooldown_deciseconds": 50, "damage": 3 },
		# ── Tier 2 — cross-combos (extended T1 × extended T1) ───────────────────
		{ "id": "voltspore",       "name": "Voltspore",       "emoji": "🔋",  "tier": 2, "price": 8, "cooldown_deciseconds": 25, "damage": 2 },
		{ "id": "photosynthesis",  "name": "Photosynthesis",  "emoji": "🌻",  "tier": 2, "price": 8, "cooldown_deciseconds": 30, "damage": 1 },
		{ "id": "ironwood",        "name": "Ironwood",        "emoji": "🌲",  "tier": 2, "price": 8, "cooldown_deciseconds": 45, "damage": 2 },
		{ "id": "lucent",          "name": "Lucent",          "emoji": "🕯️",  "tier": 2, "price": 8, "cooldown_deciseconds": 25, "damage": 2 },
		{ "id": "hexcore",         "name": "Hexcore",         "emoji": "💜",  "tier": 2, "price": 8, "cooldown_deciseconds": 45, "damage": 3 },
		{ "id": "rot",             "name": "Rot",             "emoji": "🌵",  "tier": 2, "price": 8, "cooldown_deciseconds": 30, "damage": 2 },
		{ "id": "umbra",           "name": "Umbra",           "emoji": "☯️",  "tier": 2, "price": 8, "cooldown_deciseconds": 30, "damage": 2 },
		{ "id": "moldsteel",       "name": "Moldsteel",       "emoji": "🗜️",  "tier": 2, "price": 8, "cooldown_deciseconds": 30, "damage": 2 },
		# ── Tier 2 — self-combos ─────────────────────────────────────────────────
		{ "id": "sea",        "name": "Sea",         "emoji": "🏄", "tier": 2, "price": 8, "cooldown_deciseconds": 40, "damage": 2 },
		{ "id": "blaze",      "name": "Blaze",       "emoji": "🔆", "tier": 2, "price": 8, "cooldown_deciseconds": 15, "damage": 3 },
		{ "id": "gust",       "name": "Gust",        "emoji": "🌪️", "tier": 2, "price": 8, "cooldown_deciseconds": 15, "damage": 2 },
		{ "id": "boulder",    "name": "Boulder",     "emoji": "⛰️",  "tier": 2, "price": 8, "cooldown_deciseconds": 60, "damage": 4 },
		{ "id": "plasma",     "name": "Plasma",      "emoji": "🌩️", "tier": 2, "price": 8, "cooldown_deciseconds": 12, "damage": 3 },
		{ "id": "forest",     "name": "Forest",      "emoji": "🌳", "tier": 2, "price": 8, "cooldown_deciseconds": 45, "damage": 2 },
		{ "id": "radiance",   "name": "Radiance",    "emoji": "🌟", "tier": 2, "price": 8, "cooldown_deciseconds": 20, "damage": 2 },
		{ "id": "void",       "name": "Void",        "emoji": "🕳️", "tier": 2, "price": 8, "cooldown_deciseconds": 40, "damage": 3 },
		{ "id": "steel",      "name": "Steel",       "emoji": "🔩", "tier": 2, "price": 8, "cooldown_deciseconds": 45, "damage": 4 },
		{ "id": "mycelium",   "name": "Mycelium",    "emoji": "🕸️", "tier": 2, "price": 8, "cooldown_deciseconds": 15, "damage": 2 },
		{ "id": "freeze",     "name": "Freeze",      "emoji": "❄️",  "tier": 2, "price": 8, "cooldown_deciseconds": 35, "damage": 2 },
		{ "id": "ichor",      "name": "Ichor",        "emoji": "💉",  "tier": 2, "price": 8, "cooldown_deciseconds": 20, "damage": 1 },
		# ── Tier 3 ──────────────────────────────────────────────────────────────
		{ "id": "cloud",      "name": "Cloud",       "emoji": "☁️",  "tier": 3, "price": 12, "cooldown_deciseconds": 30, "damage": 2 },
		{ "id": "geyser",     "name": "Geyser",      "emoji": "💦", "tier": 3, "price": 12, "cooldown_deciseconds": 60, "damage": 4 },
		{ "id": "fog",        "name": "Fog",         "emoji": "🌁", "tier": 3, "price": 12, "cooldown_deciseconds": 35, "damage": 1 },
		{ "id": "rainbow",    "name": "Rainbow",     "emoji": "🌈", "tier": 3, "price": 12, "cooldown_deciseconds": 40, "damage": 2 },
		{ "id": "storm",      "name": "Storm",       "emoji": "⛈️",  "tier": 3, "price": 12, "cooldown_deciseconds": 25, "damage": 3 },
		{ "id": "plant",      "name": "Plant",       "emoji": "🌿", "tier": 3, "price": 12, "cooldown_deciseconds": 40, "damage": 1 },
		{ "id": "swamp",      "name": "Swamp",       "emoji": "🐊", "tier": 3, "price": 12, "cooldown_deciseconds": 50, "damage": 2 },
		{ "id": "brick",      "name": "Brick",       "emoji": "🧱", "tier": 3, "price": 12, "cooldown_deciseconds": 50, "damage": 2 },
		{ "id": "ash",        "name": "Ash",         "emoji": "⚫", "tier": 3, "price": 12, "cooldown_deciseconds": 20, "damage": 1 },
		{ "id": "acid",       "name": "Acid",        "emoji": "🧪", "tier": 3, "price": 12, "cooldown_deciseconds": 30, "damage": 3 },
		{ "id": "obsidian",   "name": "Obsidian",    "emoji": "🪨", "tier": 3, "price": 12, "cooldown_deciseconds": 60, "damage": 3 },
		{ "id": "volcano",    "name": "Volcano",     "emoji": "🌋", "tier": 3, "price": 12, "cooldown_deciseconds": 80, "damage": 6, "family": "fire" },
		{ "id": "sand",       "name": "Sand",        "emoji": "🏜️", "tier": 3, "price": 12, "cooldown_deciseconds": 30, "damage": 1 },
		{ "id": "sandstorm",  "name": "Sandstorm",   "emoji": "🌀", "tier": 3, "price": 12, "cooldown_deciseconds": 25, "damage": 3 },
		{ "id": "clay",       "name": "Clay",        "emoji": "🏺", "tier": 3, "price": 12, "cooldown_deciseconds": 40, "damage": 1 },
		# ── Tier 3 — Frost cluster ───────────────────────────────────────────────
		{ "id": "glacier",      "name": "Glacier",       "emoji": "🗻",  "tier": 3, "price": 12, "cooldown_deciseconds": 70, "damage": 4 },
		{ "id": "blizzard",     "name": "Blizzard",      "emoji": "⛄",  "tier": 3, "price": 12, "cooldown_deciseconds": 30, "damage": 3 },
		{ "id": "tundra",       "name": "Tundra",        "emoji": "🏕️", "tier": 3, "price": 12, "cooldown_deciseconds": 50, "damage": 2 },
		# ── Tier 3 — Nature cluster ──────────────────────────────────────────────
		{ "id": "rainforest",   "name": "Rainforest",    "emoji": "🌴",  "tier": 3, "price": 12, "cooldown_deciseconds": 50, "damage": 2 },
		{ "id": "ancientgrove", "name": "Ancient Grove", "emoji": "🍀",  "tier": 3, "price": 12, "cooldown_deciseconds": 55, "damage": 3 },
		# ── Tier 3 — Storm cluster ───────────────────────────────────────────────
		{ "id": "hurricane",    "name": "Hurricane",     "emoji": "🌀",  "tier": 3, "price": 12, "cooldown_deciseconds": 30, "damage": 4 },
		{ "id": "tempest",      "name": "Tempest",       "emoji": "🌩",  "tier": 3, "price": 12, "cooldown_deciseconds": 25, "damage": 3 },
		# ── Tier 3 — Earth cluster ───────────────────────────────────────────────
		{ "id": "mountain",     "name": "Mountain",      "emoji": "⛰",  "tier": 3, "price": 12, "cooldown_deciseconds": 70, "damage": 5 },
		{ "id": "tsunami",      "name": "Tsunami",       "emoji": "🌊",  "tier": 3, "price": 12, "cooldown_deciseconds": 60, "damage": 5 },
		# ── Tier 3 — Light / Dark cluster ────────────────────────────────────────
		{ "id": "eclipse",      "name": "Eclipse",       "emoji": "🌚",  "tier": 3, "price": 12, "cooldown_deciseconds": 40, "damage": 3 },
		{ "id": "voidrift",     "name": "Voidrift",      "emoji": "🪐",  "tier": 3, "price": 12, "cooldown_deciseconds": 45, "damage": 3 },
		# ── Tier 3 — Fungus cluster ──────────────────────────────────────────────
		{ "id": "plague",       "name": "Plague",        "emoji": "🧫",  "tier": 3, "price": 12, "cooldown_deciseconds": 40, "damage": 3 },
		{ "id": "underrot",     "name": "Underrot",      "emoji": "🪸",  "tier": 3, "price": 12, "cooldown_deciseconds": 50, "damage": 3 },
		# ── Tier 3 — Fire cluster ────────────────────────────────────────────────
		{ "id": "inferno",      "name": "Inferno",       "emoji": "🪔",  "tier": 3, "price": 12, "cooldown_deciseconds": 25, "damage": 4 },
		# ── Tier 3 — Blood cluster ───────────────────────────────────────────────
		{ "id": "hemorrhage",   "name": "Hemorrhage",    "emoji": "🫀",  "tier": 3, "price": 12, "cooldown_deciseconds": 35, "damage": 3 },
		{ "id": "carnage",      "name": "Carnage",       "emoji": "🗡️",  "tier": 3, "price": 12, "cooldown_deciseconds": 40, "damage": 3 },
		# ── Tier 3 — Metal cluster ───────────────────────────────────────────────
		{ "id": "meteorite",    "name": "Meteorite",     "emoji": "☄️",  "tier": 3, "price": 12, "cooldown_deciseconds": 60, "damage": 5 },
		# ── Tier 4 ──────────────────────────────────────────────────────────────
		{ "id": "iceage",       "name": "Ice Age",       "emoji": "🏔",  "tier": 4, "price": 16, "cooldown_deciseconds": 80, "damage": 5 },
		{ "id": "maelstrom",    "name": "Maelstrom",     "emoji": "🌀",  "tier": 4, "price": 16, "cooldown_deciseconds": 30, "damage": 5 },
		{ "id": "tectonic",     "name": "Tectonic",      "emoji": "🗺️",  "tier": 4, "price": 16, "cooldown_deciseconds": 90, "damage": 7 },
		{ "id": "supernova",    "name": "Supernova",     "emoji": "⭐",  "tier": 4, "price": 16, "cooldown_deciseconds": 50, "damage": 7, "family": "light" },
		{ "id": "singularity",  "name": "Singularity",   "emoji": "🌒",  "tier": 4, "price": 16, "cooldown_deciseconds": 60, "damage": 6 },
		{ "id": "worldtree",    "name": "World Tree",    "emoji": "🎋",  "tier": 4, "price": 16, "cooldown_deciseconds": 60, "damage": 4 },
		{ "id": "pandemic",     "name": "Pandemic",      "emoji": "🧬",  "tier": 4, "price": 16, "cooldown_deciseconds": 40, "damage": 4 },
		{ "id": "ragnarok",     "name": "Ragnarok",      "emoji": "🔱",  "tier": 4, "price": 16, "cooldown_deciseconds": 40, "damage": 6 },
		{ "id": "primordial",   "name": "Primordial",    "emoji": "🌏",  "tier": 4, "price": 16, "cooldown_deciseconds": 70, "damage": 6 },
		{ "id": "aether",       "name": "Aether",        "emoji": "✨",  "tier": 4, "price": 16, "cooldown_deciseconds": 35, "damage": 5 },
	]


static func all_elements() -> Array[Dictionary]:
	return ELEMENTS


# Lazy id→def index over the const ELEMENTS, built once on first lookup. Returns the
# SHARED def (zero-copy) — callers that mutate must .duplicate() first.
static var _by_id: Dictionary = {}

static func find(element_id: String) -> Dictionary:
	if _by_id.is_empty() and not ELEMENTS.is_empty():
		for elem: Dictionary in ELEMENTS:
			_by_id[elem["id"] as String] = elem
	return _by_id.get(element_id, {})


# The single place that turns a (shared, const) definition into a fresh, owned live
# instance — for a board slot, inventory slot, shop tile, forge result, or ghost grid.
# Always duplicates, so it never mutates the zero-copy find() result. Sets element_id +
# level; callers layer on extras (Starting Pick's damage_multiplier). Empty for unknown id.
static func instantiate(element_id: String, level: int = 1) -> Dictionary:
	var def: Dictionary = find(element_id)
	if def.is_empty():
		return {}
	var instance: Dictionary = def.duplicate()
	instance["element_id"] = def["id"] as String
	instance["level"] = level
	return instance


# Damage-dealers: the only elements that deal direct hit damage. Everyone else is
# "pure-effect" — its Status IS its damage (burn/poison ticks, etc.). A privilege of
# some T2+ (impact/physical theme), skewed to higher tiers. See docs/adr (damage redesign).
const DAMAGE_DEALERS: Dictionary = {
	# T1
	"blood": true,
	# T2
	"lava": true, "boulder": true, "molten": true, "steel": true,
	"gore": true, "pulse": true, "nightveil": true, "fever": true, "ichor": true,
	# T3
	"volcano": true, "obsidian": true, "meteorite": true, "mountain": true, "tsunami": true, "glacier": true, "carnage": true,
	"hemorrhage": true,
	# T4
	"iceage": true, "maelstrom": true, "tectonic": true, "supernova": true, "singularity": true,
	"ragnarok": true, "primordial": true, "aether": true,
}


# The tier-scaled potency of one element: how many status stacks/points one
# application lands AND the damage scalar for direct hits. potency = level ×
# TIER_POTENCY_MULTIPLIER[tier], rounded, floored at 1 — the single seam that makes
# a higher-tier element intrinsically stronger than a same-Level lower-tier one
# (first rough pass 2026-06-12; the multiplier table is the balance knob).
static func scaled_potency(tier: int, level: int) -> int:
	var multiplier: float = TuningData.TIER_POTENCY_MULTIPLIER.get(tier, 1.0) as float
	return maxi(1, int(round(float(maxi(1, level)) * multiplier)))


# One-line clarifier for the Element Card / Compendium: an ability's authored status
# amounts are written at potency 1, but every status application lands at this
# element's tier-scaled potency, so a "2 [curse]" reads as the multiplied amount in
# combat. Returns "" at potency 1 (all of Tier 1) — nothing to clarify. Direct-hit
# damage scales separately and is already shown on the Eff. Dmg row.
static func potency_note(tier: int, level: int) -> String:
	var potency: int = scaled_potency(tier, level)
	if potency <= 1:
		return ""
	return "Status amounts apply ×%d at this Level." % potency


# Direct hit damage = base × multiplier × level × tier multiplier. Pure-effect
# elements (not in DAMAGE_DEALERS) return 0 — no tier chip, no hit; their Status
# carries their damage. (`multiplier` is vestigial — nothing sets it now.)
static func effective_damage(item: Dictionary) -> int:
	var id: String = item.get("element_id", item.get("id", "")) as String
	if not DAMAGE_DEALERS.has(id):
		return 0
	var base: int = item.get("damage", 0) as int
	if base <= 0:
		return 0
	var level: int = item.get("level", 1) as int
	var multiplier: int = item.get("damage_multiplier", 1) as int
	var tier: int = item.get("tier", 1) as int
	var tier_multiplier: float = TuningData.TIER_POTENCY_MULTIPLIER.get(tier, 1.0) as float
	return maxi(1, int(round(float(base * multiplier * level) * tier_multiplier)))


# The single dominant Family that drives an element's Element Card hue (ADR-0017).
# A Tier-1 element IS its own family (id == family). A forged element carries an
# explicit "family" tag (designer-authored by result vibe). Untagged forged
# elements return "" — the card falls back to a neutral hue until they are tagged
# (the pass-2 roster sweep). Unknown ids also return "".
static func canonical_family(element_id: String) -> String:
	var def: Dictionary = find(element_id)
	if def.is_empty():
		return ""
	if def.has("family"):
		return def["family"] as String
	if (def.get("tier", 0) as int) == 1:
		return element_id
	return ""


# The 1–3 Element Card stat pods for an item (SPEC §B pod rule, ADR-0017). Always
# leads with the Cooldown pod; a damage-dealer adds a DMG pod (effective_damage).
# Each pod is { "value": String, "label": String, "highlight": bool }. Pure view
# logic kept out of the scene script so it is unit-testable.
static func stat_pods(item: Dictionary) -> Array[Dictionary]:
	var cd_value: String = "%.1fs" % (float(item.get("cooldown_deciseconds", 0) as int) / 10.0)
	var cd_pod: Dictionary = { "value": cd_value, "label": "CD", "highlight": false }
	var id: String = item.get("element_id", item.get("id", "")) as String
	var tier: int = item.get("tier", 1) as int
	var level: int = item.get("level", 1) as int
	# Dealer → CD + DMG (takes precedence; a T1 dealer like Blood shows DMG, not its status).
	if DAMAGE_DEALERS.has(id):
		var dmg: int = effective_damage(item)
		if dmg > 0:
			return [cd_pod, { "value": str(dmg), "label": "DMG", "highlight": false }] as Array[Dictionary]
	# T1 applier → CD + STATUS, from the element's `effect` keyword (base amount 1).
	if tier == 1 and item.has("effect"):
		var amount: int = scaled_potency(1, level)  # base 1 × tier-scaled potency
		return [cd_pod, { "value": str(amount), "label": item["effect"] as String, "highlight": true }] as Array[Dictionary]
	# T2+ on-activate applier → CD + STATUS from the ability's first apply_status effect.
	# Landed amount = authored amount × scaled_potency (the combat seam, AbilitySystem).
	var ability: Dictionary = AbilityData.get_ability(id)
	if (ability.get("trigger", "") as String) == "on_activate":
		var effects: Array = ability.get("effects", []) as Array
		if not effects.is_empty() and ((effects[0] as Dictionary).get("kind", "") as String) == "apply_status":
			var first: Dictionary = effects[0] as Dictionary
			var amount: int = (first.get("amount", 1) as int) * scaled_potency(tier, level)
			return [cd_pod, { "value": str(amount), "label": first["status"] as String, "highlight": true }] as Array[Dictionary]
	# else → CD only (reactive / passive / combat-start: output is conditional).
	return [cd_pod] as Array[Dictionary]
