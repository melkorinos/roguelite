class_name ElementData


static func all_elements() -> Array[Dictionary]:
	return [
		# ── Tier 1 ──────────────────────────────────────────────────────────────
		{ "id": "water",      "name": "Water",      "emoji": "💧", "tier": 1, "price": 5,  "cooldown": 3.0, "damage": 1 },
		{ "id": "fire",       "name": "Fire",        "emoji": "🔥", "tier": 1, "price": 5,  "cooldown": 2.5, "damage": 2 },
		{ "id": "air",        "name": "Air",         "emoji": "🌬️", "tier": 1, "price": 5,  "cooldown": 2.0, "damage": 1 },
		{ "id": "earth",      "name": "Earth",       "emoji": "🌍", "tier": 1, "price": 5,  "cooldown": 4.0, "damage": 1 },
		# ── Tier 2 ──────────────────────────────────────────────────────────────
		{ "id": "steam",      "name": "Steam",       "emoji": "♨️",  "tier": 2, "price": 8,  "cooldown": 3.5, "damage": 2 },
		{ "id": "rain",       "name": "Rain",        "emoji": "🌧️", "tier": 2, "price": 8,  "cooldown": 3.0, "damage": 1 },
		{ "id": "mud",        "name": "Mud",         "emoji": "🟫", "tier": 2, "price": 8,  "cooldown": 4.5, "damage": 1 },
		{ "id": "smoke",      "name": "Smoke",       "emoji": "🌫️", "tier": 2, "price": 8,  "cooldown": 2.5, "damage": 1 },
		{ "id": "lava",       "name": "Lava",        "emoji": "🟠", "tier": 2, "price": 8,  "cooldown": 5.0, "damage": 3 },
		{ "id": "dust",       "name": "Dust",        "emoji": "💨", "tier": 2, "price": 8,  "cooldown": 2.5, "damage": 1 },
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
		# ── Tier 4 ──────────────────────────────────────────────────────────────
		{ "id": "lightning",  "name": "Lightning",   "emoji": "⚡", "tier": 4, "price": 16, "cooldown": 1.5, "damage": 5 },
		{ "id": "mountain",   "name": "Mountain",    "emoji": "⛰️",  "tier": 4, "price": 16, "cooldown": 7.0, "damage": 4 },
		{ "id": "snow",       "name": "Snow",        "emoji": "❄️",  "tier": 4, "price": 16, "cooldown": 3.5, "damage": 2 },
		{ "id": "earthquake", "name": "Earthquake",  "emoji": "💢", "tier": 4, "price": 16, "cooldown": 8.0, "damage": 5 },
		{ "id": "flood",      "name": "Flood",       "emoji": "🌊", "tier": 4, "price": 16, "cooldown": 5.0, "damage": 4 },
		{ "id": "forest",     "name": "Forest",      "emoji": "🌲", "tier": 4, "price": 16, "cooldown": 5.0, "damage": 2 },
		{ "id": "tree",       "name": "Tree",        "emoji": "🌳", "tier": 4, "price": 16, "cooldown": 4.5, "damage": 2 },
		{ "id": "glass",      "name": "Glass",       "emoji": "🪟", "tier": 4, "price": 16, "cooldown": 3.0, "damage": 2 },
		{ "id": "beach",      "name": "Beach",       "emoji": "🏖️", "tier": 4, "price": 16, "cooldown": 4.0, "damage": 1 },
		{ "id": "pottery",    "name": "Pottery",     "emoji": "🫙", "tier": 4, "price": 16, "cooldown": 5.0, "damage": 2 },
		{ "id": "stone",      "name": "Stone",       "emoji": "🗿", "tier": 4, "price": 16, "cooldown": 6.0, "damage": 3 },
		{ "id": "island",     "name": "Island",      "emoji": "🏝️", "tier": 4, "price": 16, "cooldown": 7.0, "damage": 3 },
		{ "id": "oil",        "name": "Oil",         "emoji": "🛢️", "tier": 4, "price": 16, "cooldown": 4.0, "damage": 2 },
		{ "id": "coal",       "name": "Coal",        "emoji": "⛏️", "tier": 4, "price": 16, "cooldown": 5.0, "damage": 3 },
		{ "id": "gem",        "name": "Gem",         "emoji": "💎", "tier": 4, "price": 16, "cooldown": 5.0, "damage": 3 },
		{ "id": "wall",       "name": "Wall",        "emoji": "🏗️", "tier": 4, "price": 16, "cooldown": 6.0, "damage": 2 },
		{ "id": "shard",      "name": "Shard",       "emoji": "🔷", "tier": 4, "price": 16, "cooldown": 4.0, "damage": 3 },
		{ "id": "poison",     "name": "Poison",      "emoji": "☠️",  "tier": 4, "price": 16, "cooldown": 3.5, "damage": 3 },
		# ── Tier 5 ──────────────────────────────────────────────────────────────
		{ "id": "jungle",     "name": "Jungle",      "emoji": "🌴", "tier": 5, "price": 20, "cooldown": 5.0, "damage": 3 },
		{ "id": "wildfire",   "name": "Wildfire",    "emoji": "🔆", "tier": 5, "price": 20, "cooldown": 2.0, "damage": 4 },
		{ "id": "charcoal",   "name": "Charcoal",    "emoji": "🪵", "tier": 5, "price": 20, "cooldown": 4.5, "damage": 3 },
		{ "id": "mirror",     "name": "Mirror",      "emoji": "🪞", "tier": 5, "price": 20, "cooldown": 4.0, "damage": 3 },
		{ "id": "glacier",    "name": "Glacier",     "emoji": "🧊", "tier": 5, "price": 20, "cooldown": 7.0, "damage": 4 },
		{ "id": "explosion",  "name": "Explosion",   "emoji": "💥", "tier": 5, "price": 20, "cooldown": 3.0, "damage": 6 },
		{ "id": "diamond",    "name": "Diamond",     "emoji": "💠", "tier": 5, "price": 20, "cooldown": 6.0, "damage": 5 },
		{ "id": "tsunami",    "name": "Tsunami",     "emoji": "🐚", "tier": 5, "price": 20, "cooldown": 6.0, "damage": 6 },
	]


static func find(element_id: String) -> Dictionary:
	for elem: Dictionary in all_elements():
		if elem["id"] == element_id:
			return elem
	return {}
