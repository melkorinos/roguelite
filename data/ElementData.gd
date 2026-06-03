class_name ElementData


static func all_elements() -> Array[Dictionary]:
	return [
		# ── Tier 1 ──────────────────────────────────────────────────────────────
		{ "id": "water",     "name": "Water",     "emoji": "💧", "tier": 1, "price": 5, "cooldown": 3.0, "damage": 1, "effect": "cleanse"  },
		{ "id": "fire",      "name": "Fire",      "emoji": "🔥", "tier": 1, "price": 5, "cooldown": 2.5, "damage": 2, "effect": "burn"     },
		{ "id": "air",       "name": "Air",       "emoji": "🌬️", "tier": 1, "price": 5, "cooldown": 2.0, "damage": 1, "effect": "haste"    },
		{ "id": "earth",     "name": "Earth",     "emoji": "🌍", "tier": 1, "price": 5, "cooldown": 4.0, "damage": 1, "effect": "armor"    },
		{ "id": "lightning", "name": "Lightning", "emoji": "⚡", "tier": 1, "price": 5, "cooldown": 1.8, "damage": 2, "effect": "shock"    },
		{ "id": "nature",    "name": "Nature",    "emoji": "🌿", "tier": 1, "price": 5, "cooldown": 3.5, "damage": 1, "effect": "heal"     },
		{ "id": "light",     "name": "Light",     "emoji": "☀️",  "tier": 1, "price": 5, "cooldown": 2.5, "damage": 1, "effect": "blind"    },
		{ "id": "dark",      "name": "Dark",      "emoji": "🌑", "tier": 1, "price": 5, "cooldown": 3.0, "damage": 2, "effect": "curse"    },
		{ "id": "metal",     "name": "Metal",     "emoji": "⚙️",  "tier": 1, "price": 5, "cooldown": 5.0, "damage": 3, "effect": "plating"  },
		{ "id": "fungus",    "name": "Fungus",    "emoji": "🍄", "tier": 1, "price": 5, "cooldown": 3.5, "damage": 1, "effect": "poison"   },
		{ "id": "blood",     "name": "Blood",     "emoji": "🩸", "tier": 1, "price": 5, "cooldown": 2.5, "damage": 1, "effect": "leech"    },
		{ "id": "frost",     "name": "Frost",     "emoji": "🌨️", "tier": 1, "price": 5, "cooldown": 3.0, "damage": 1, "effect": "weaken"   },
		# ── Tier 2 — cross-combos ────────────────────────────────────────────────
		{ "id": "steam",      "name": "Steam",       "emoji": "♨️",  "tier": 2, "price": 8,  "cooldown": 3.5, "damage": 2 },
		{ "id": "rain",       "name": "Rain",        "emoji": "🌧️", "tier": 2, "price": 8,  "cooldown": 3.0, "damage": 1 },
		{ "id": "mud",        "name": "Mud",         "emoji": "🟫", "tier": 2, "price": 8,  "cooldown": 4.5, "damage": 1 },
		{ "id": "smoke",      "name": "Smoke",       "emoji": "🌫️", "tier": 2, "price": 8,  "cooldown": 2.5, "damage": 1 },
		{ "id": "lava",       "name": "Lava",        "emoji": "🟠", "tier": 2, "price": 8,  "cooldown": 5.0, "damage": 3 },
		{ "id": "dust",       "name": "Dust",        "emoji": "💨", "tier": 2, "price": 8,  "cooldown": 2.5, "damage": 1 },
		# ── Tier 2 — cross-combos (Lightning / Nature / Light / Dark / Metal / Fungus × originals) ──
		{ "id": "surge",     "name": "Surge",     "emoji": "💫",  "tier": 2, "price": 8, "cooldown": 2.5, "damage": 2 },
		{ "id": "arc",       "name": "Arc",       "emoji": "🌠",  "tier": 2, "price": 8, "cooldown": 2.5, "damage": 2 },
		{ "id": "static",    "name": "Static",    "emoji": "💠",  "tier": 2, "price": 8, "cooldown": 2.0, "damage": 1 },
		{ "id": "lodestone", "name": "Lodestone", "emoji": "🧲",  "tier": 2, "price": 8, "cooldown": 5.0, "damage": 2 },
		{ "id": "bloom",     "name": "Bloom",     "emoji": "🌸",  "tier": 2, "price": 8, "cooldown": 4.0, "damage": 1 },
		{ "id": "ember",     "name": "Ember",     "emoji": "🪵",  "tier": 2, "price": 8, "cooldown": 3.0, "damage": 2 },
		{ "id": "pollen",    "name": "Pollen",    "emoji": "🌼",  "tier": 2, "price": 8, "cooldown": 2.5, "damage": 1 },
		{ "id": "root",      "name": "Root",      "emoji": "🌱",  "tier": 2, "price": 8, "cooldown": 4.5, "damage": 1 },
		{ "id": "prism",     "name": "Prism",     "emoji": "💎",  "tier": 2, "price": 8, "cooldown": 3.0, "damage": 2 },
		{ "id": "solar",     "name": "Solar",     "emoji": "🌞",  "tier": 2, "price": 8, "cooldown": 2.5, "damage": 2 },
		{ "id": "aurora",    "name": "Aurora",    "emoji": "🌌",  "tier": 2, "price": 8, "cooldown": 2.0, "damage": 1 },
		{ "id": "crystal",   "name": "Crystal",   "emoji": "🔮",  "tier": 2, "price": 8, "cooldown": 4.0, "damage": 2 },
		{ "id": "abyss",     "name": "Abyss",     "emoji": "🌊",  "tier": 2, "price": 8, "cooldown": 5.0, "damage": 3 },
		{ "id": "blight",    "name": "Blight",    "emoji": "🥀",  "tier": 2, "price": 8, "cooldown": 3.5, "damage": 2 },
		{ "id": "miasma",    "name": "Miasma",    "emoji": "☣️",  "tier": 2, "price": 8, "cooldown": 2.5, "damage": 1 },
		{ "id": "shade",     "name": "Shade",     "emoji": "🌘",  "tier": 2, "price": 8, "cooldown": 4.0, "damage": 2 },
		{ "id": "rust",      "name": "Rust",      "emoji": "🟤",  "tier": 2, "price": 8, "cooldown": 4.5, "damage": 1 },
		{ "id": "molten",    "name": "Molten",    "emoji": "🔶",  "tier": 2, "price": 8, "cooldown": 5.0, "damage": 3 },
		{ "id": "shrapnel",  "name": "Shrapnel",  "emoji": "💥",  "tier": 2, "price": 8, "cooldown": 2.5, "damage": 2 },
		{ "id": "ore",       "name": "Ore",       "emoji": "⛏️",  "tier": 2, "price": 8, "cooldown": 6.0, "damage": 3 },
		{ "id": "sonar",     "name": "Sonar",     "emoji": "📡",  "tier": 2, "price": 8, "cooldown": 3.0, "damage": 1 },
		{ "id": "resonance", "name": "Resonance", "emoji": "〰️",  "tier": 2, "price": 8, "cooldown": 2.5, "damage": 2 },
		{ "id": "howl",      "name": "Howl",      "emoji": "🐺",  "tier": 2, "price": 8, "cooldown": 2.0, "damage": 1 },
		{ "id": "tremor",    "name": "Tremor",    "emoji": "🫨",  "tier": 2, "price": 8, "cooldown": 4.5, "damage": 2 },
		# ── Tier 2 — self-combos ─────────────────────────────────────────────────
		{ "id": "ice",        "name": "Ice",         "emoji": "🧊", "tier": 2, "price": 8,  "cooldown": 4.0, "damage": 2 },
		{ "id": "blaze",      "name": "Blaze",       "emoji": "🔆", "tier": 2, "price": 8,  "cooldown": 1.5, "damage": 3 },
		{ "id": "gale",       "name": "Gale",        "emoji": "🌪️", "tier": 2, "price": 8,  "cooldown": 1.5, "damage": 2 },
		{ "id": "boulder",    "name": "Boulder",     "emoji": "⛰️",  "tier": 2, "price": 8,  "cooldown": 6.0, "damage": 4 },
		{ "id": "plasma",     "name": "Plasma",      "emoji": "🌩️", "tier": 2, "price": 8,  "cooldown": 1.2, "damage": 3 },
		{ "id": "forest",     "name": "Forest",      "emoji": "🌳", "tier": 2, "price": 8,  "cooldown": 4.5, "damage": 2 },
		{ "id": "radiance",   "name": "Radiance",    "emoji": "🌟", "tier": 2, "price": 8,  "cooldown": 2.0, "damage": 2 },
		{ "id": "void",       "name": "Void",        "emoji": "🕳️", "tier": 2, "price": 8,  "cooldown": 4.0, "damage": 3 },
		{ "id": "steel",      "name": "Steel",       "emoji": "🔩", "tier": 2, "price": 8,  "cooldown": 4.5, "damage": 4 },
		{ "id": "echo",       "name": "Echo",        "emoji": "🔁", "tier": 2, "price": 8,  "cooldown": 1.5, "damage": 2 },
		# ── Tier 3 ──────────────────────────────────────────────────────────────
		{ "id": "cloud",      "name": "Cloud",       "emoji": "☁️",  "tier": 3, "price": 12, "cooldown": 3.0, "damage": 2 },
		{ "id": "geyser",     "name": "Geyser",      "emoji": "💦", "tier": 3, "price": 12, "cooldown": 6.0, "damage": 4 },
		{ "id": "fog",        "name": "Fog",         "emoji": "🌁", "tier": 3, "price": 12, "cooldown": 3.5, "damage": 1 },
		{ "id": "rainbow",    "name": "Rainbow",     "emoji": "🌈", "tier": 3, "price": 12, "cooldown": 4.0, "damage": 2 },
		{ "id": "storm",      "name": "Storm",       "emoji": "⛈️",  "tier": 3, "price": 12, "cooldown": 2.5, "damage": 3 },
		{ "id": "plant",      "name": "Plant",       "emoji": "🌿", "tier": 3, "price": 12, "cooldown": 4.0, "damage": 1 },
		{ "id": "swamp",      "name": "Swamp",       "emoji": "🐊", "tier": 3, "price": 12, "cooldown": 5.0, "damage": 2 },
		{ "id": "brick",      "name": "Brick",       "emoji": "🧱", "tier": 3, "price": 12, "cooldown": 5.0, "damage": 2 },
		{ "id": "ash",        "name": "Ash",         "emoji": "⚫", "tier": 3, "price": 12, "cooldown": 2.0, "damage": 1 },
		{ "id": "acid",       "name": "Acid",        "emoji": "🧪", "tier": 3, "price": 12, "cooldown": 3.0, "damage": 3 },
		{ "id": "obsidian",   "name": "Obsidian",    "emoji": "🪨", "tier": 3, "price": 12, "cooldown": 6.0, "damage": 3 },
		{ "id": "volcano",    "name": "Volcano",     "emoji": "🌋", "tier": 3, "price": 12, "cooldown": 8.0, "damage": 6 },
		{ "id": "sand",       "name": "Sand",        "emoji": "🏜️", "tier": 3, "price": 12, "cooldown": 3.0, "damage": 1 },
		{ "id": "sandstorm",  "name": "Sandstorm",   "emoji": "🌀", "tier": 3, "price": 12, "cooldown": 2.5, "damage": 3 },
		{ "id": "clay",       "name": "Clay",        "emoji": "🏺", "tier": 3, "price": 12, "cooldown": 4.0, "damage": 1 },
	]


static func find(element_id: String) -> Dictionary:
	for elem: Dictionary in all_elements():
		if elem["id"] == element_id:
			return elem
	return {}


# Effective damage = base_damage × level + tier. Applies universally (level-up and forge results).
static func effective_damage(item: Dictionary) -> int:
	var level: int = item.get("level", 1) as int
	return (item["damage"] as int) * level + (item["tier"] as int)
