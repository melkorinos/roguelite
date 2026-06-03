class_name ElementData


static func all_elements() -> Array[Dictionary]:
	return [
		# ── Tier 1 ──────────────────────────────────────────────────────────────
		{ "id": "water",      "name": "Water",      "emoji": "💧", "tier": 1, "price": 5,  "cooldown": 3.0, "damage": 1 },
		{ "id": "fire",       "name": "Fire",       "emoji": "🔥", "tier": 1, "price": 5,  "cooldown": 2.5, "damage": 2 },
		{ "id": "air",        "name": "Air",        "emoji": "🌬️", "tier": 1, "price": 5,  "cooldown": 2.0, "damage": 1 },
		{ "id": "earth",      "name": "Earth",      "emoji": "🌍", "tier": 1, "price": 5,  "cooldown": 4.0, "damage": 1 },
		{ "id": "lightning",  "name": "Lightning",  "emoji": "⚡", "tier": 1, "price": 5,  "cooldown": 1.8, "damage": 2 },
		{ "id": "nature",     "name": "Nature",     "emoji": "🌿", "tier": 1, "price": 5,  "cooldown": 3.5, "damage": 1 },
		{ "id": "light",      "name": "Light",      "emoji": "☀️",  "tier": 1, "price": 5,  "cooldown": 2.5, "damage": 1 },
		{ "id": "dark",       "name": "Dark",       "emoji": "🌑", "tier": 1, "price": 5,  "cooldown": 3.0, "damage": 2 },
		{ "id": "metal",      "name": "Metal",      "emoji": "⚙️",  "tier": 1, "price": 5,  "cooldown": 5.0, "damage": 3 },
		{ "id": "sound",      "name": "Sound",      "emoji": "🔊", "tier": 1, "price": 5,  "cooldown": 2.0, "damage": 1 },
		# ── Tier 2 — cross-combos ────────────────────────────────────────────────
		{ "id": "steam",      "name": "Steam",       "emoji": "♨️",  "tier": 2, "price": 8,  "cooldown": 3.5, "damage": 2 },
		{ "id": "rain",       "name": "Rain",        "emoji": "🌧️", "tier": 2, "price": 8,  "cooldown": 3.0, "damage": 1 },
		{ "id": "mud",        "name": "Mud",         "emoji": "🟫", "tier": 2, "price": 8,  "cooldown": 4.5, "damage": 1 },
		{ "id": "smoke",      "name": "Smoke",       "emoji": "🌫️", "tier": 2, "price": 8,  "cooldown": 2.5, "damage": 1 },
		{ "id": "lava",       "name": "Lava",        "emoji": "🟠", "tier": 2, "price": 8,  "cooldown": 5.0, "damage": 3 },
		{ "id": "dust",       "name": "Dust",        "emoji": "💨", "tier": 2, "price": 8,  "cooldown": 2.5, "damage": 1 },
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
