class_name RecipeData

# 55 recipes across 3 tiers. Multiple recipes may share a result (alternate discovery paths).
# All combinations are order-independent: a+b == b+a. Self-combos (a==b) are valid.
static func all_recipes() -> Array[Dictionary]:
	return [
		# ══ Tier 2 — the 6 basic cross-pairings ═════════════════════════════════
		{ "a": "water", "b": "fire",      "result": "steam"      },
		{ "a": "water", "b": "air",       "result": "rain"       },
		{ "a": "water", "b": "earth",     "result": "mud"        },
		{ "a": "fire",  "b": "air",       "result": "smoke"      },
		{ "a": "fire",  "b": "earth",     "result": "lava"       },
		{ "a": "air",   "b": "earth",     "result": "dust"       },
		# ══ Tier 2 — cross-combos (Lightning / Nature / Light / Dark / Metal / Fungus × originals) ════
		{ "a": "lightning", "b": "water",  "result": "surge"     },
		{ "a": "lightning", "b": "fire",   "result": "arc"       },
		{ "a": "lightning", "b": "air",    "result": "static"    },
		{ "a": "lightning", "b": "earth",  "result": "lodestone" },
		{ "a": "nature",    "b": "water",  "result": "bloom"     },
		{ "a": "nature",    "b": "fire",   "result": "ember"     },
		{ "a": "nature",    "b": "air",    "result": "pollen"    },
		{ "a": "nature",    "b": "earth",  "result": "root"      },
		{ "a": "light",     "b": "water",  "result": "prism"     },
		{ "a": "light",     "b": "fire",   "result": "solar"     },
		{ "a": "light",     "b": "air",    "result": "aurora"    },
		{ "a": "light",     "b": "earth",  "result": "crystal"   },
		{ "a": "dark",      "b": "water",  "result": "abyss"     },
		{ "a": "dark",      "b": "fire",   "result": "blight"    },
		{ "a": "dark",      "b": "air",    "result": "miasma"    },
		{ "a": "dark",      "b": "earth",  "result": "shade"     },
		{ "a": "metal",     "b": "water",  "result": "rust"      },
		{ "a": "metal",     "b": "fire",   "result": "molten"    },
		{ "a": "metal",     "b": "air",    "result": "shrapnel"  },
		{ "a": "metal",     "b": "earth",  "result": "ore"       },
		{ "a": "fungus",    "b": "water",  "result": "sonar"     },
		{ "a": "fungus",    "b": "fire",   "result": "resonance" },
		{ "a": "fungus",    "b": "air",    "result": "howl"      },
		{ "a": "fungus",    "b": "earth",  "result": "tremor"    },
		# ══ Tier 2 — self-combos ════════════════════════════════════════════════
		{ "a": "water",     "b": "water",     "result": "ice"       },
		{ "a": "fire",      "b": "fire",      "result": "blaze"     },
		{ "a": "air",       "b": "air",       "result": "gale"      },
		{ "a": "earth",     "b": "earth",     "result": "boulder"   },
		{ "a": "lightning", "b": "lightning", "result": "plasma"    },
		{ "a": "nature",    "b": "nature",    "result": "forest"    },
		{ "a": "light",     "b": "light",     "result": "radiance"  },
		{ "a": "dark",      "b": "dark",      "result": "void"      },
		{ "a": "metal",     "b": "metal",     "result": "steel"     },
		{ "a": "fungus",    "b": "fungus",    "result": "echo"      },
		# ══ Tier 3 — basics × tier-2 ════════════════════════════════════════════
		{ "a": "steam",  "b": "air",      "result": "cloud"      },
		{ "a": "steam",  "b": "earth",    "result": "geyser"     },
		{ "a": "steam",  "b": "rain",     "result": "fog"        },
		{ "a": "rain",   "b": "fire",     "result": "rainbow"    },
		{ "a": "rain",   "b": "air",      "result": "storm"      },
		{ "a": "rain",   "b": "earth",    "result": "plant"      },
		{ "a": "mud",    "b": "rain",     "result": "swamp"      },
		{ "a": "mud",    "b": "fire",     "result": "brick"      },
		{ "a": "smoke",  "b": "fire",     "result": "ash"        },
		{ "a": "smoke",  "b": "rain",     "result": "acid"       },
		{ "a": "lava",   "b": "water",    "result": "obsidian"   },
		{ "a": "lava",   "b": "earth",    "result": "volcano"    },
		{ "a": "dust",   "b": "earth",    "result": "sand"       },
		{ "a": "dust",   "b": "air",      "result": "sandstorm"  },
		{ "a": "dust",   "b": "rain",     "result": "clay"       },
	]


# Returns the result element id, or "" if no recipe exists. Order-independent.
static func find_result(id_a: String, id_b: String) -> String:
	for recipe: Dictionary in all_recipes():
		var ra: String = recipe["a"]
		var rb: String = recipe["b"]
		if (ra == id_a and rb == id_b) or (ra == id_b and rb == id_a):
			return recipe["result"]
	return ""
