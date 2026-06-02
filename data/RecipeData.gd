class_name RecipeData

# 49 recipes across 5 tiers. Multiple recipes may share a result (alternate discovery paths).
# All combinations are order-independent: a+b == b+a.
static func all_recipes() -> Array[Dictionary]:
	return [
		# ══ Tier 2 — the 6 basic pairings ══════════════════════════════════════
		{ "a": "water", "b": "fire",      "result": "steam"      },
		{ "a": "water", "b": "air",       "result": "rain"       },
		{ "a": "water", "b": "earth",     "result": "mud"        },
		{ "a": "fire",  "b": "air",       "result": "smoke"      },
		{ "a": "fire",  "b": "earth",     "result": "lava"       },
		{ "a": "air",   "b": "earth",     "result": "dust"       },
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
		# ══ Tier 4 — tier-2 × tier-3 or tier-3 × tier-3 ════════════════════════
		{ "a": "cloud",    "b": "fire",   "result": "lightning"  },
		{ "a": "cloud",    "b": "earth",  "result": "mountain"   },
		{ "a": "cloud",    "b": "water",  "result": "snow"       },
		{ "a": "storm",    "b": "earth",  "result": "earthquake" },
		{ "a": "storm",    "b": "water",  "result": "flood"      },
		{ "a": "plant",    "b": "earth",  "result": "forest"     },
		{ "a": "plant",    "b": "water",  "result": "tree"       },
		{ "a": "sand",     "b": "fire",   "result": "glass"      },
		{ "a": "sand",     "b": "water",  "result": "beach"      },
		{ "a": "clay",     "b": "fire",   "result": "pottery"    },
		{ "a": "clay",     "b": "earth",  "result": "stone"      },
		{ "a": "volcano",  "b": "water",  "result": "island"     },
		{ "a": "swamp",    "b": "earth",  "result": "oil"        },
		{ "a": "ash",      "b": "earth",  "result": "coal"       },
		{ "a": "rainbow",  "b": "earth",  "result": "gem"        },
		{ "a": "brick",    "b": "earth",  "result": "wall"       },
		{ "a": "obsidian", "b": "air",    "result": "shard"      },
		{ "a": "acid",     "b": "earth",  "result": "poison"     },
		# ══ Tier 5 — deeper combinations ════════════════════════════════════════
		{ "a": "forest",     "b": "rain",  "result": "jungle"    },
		{ "a": "island",     "b": "rain",  "result": "jungle"    },  # alt path
		{ "a": "forest",     "b": "fire",  "result": "wildfire"  },
		{ "a": "lightning",  "b": "tree",  "result": "wildfire"  },  # alt path
		{ "a": "tree",       "b": "fire",  "result": "charcoal"  },
		{ "a": "glass",      "b": "fire",  "result": "mirror"    },
		{ "a": "mountain",   "b": "water", "result": "glacier"   },
		{ "a": "oil",        "b": "fire",  "result": "explosion" },
		{ "a": "acid",       "b": "fire",  "result": "explosion" },  # alt path
		{ "a": "gem",        "b": "fire",  "result": "diamond"   },
		{ "a": "charcoal",   "b": "fire",  "result": "diamond"   },  # alt path
		{ "a": "earthquake", "b": "water", "result": "tsunami"   },
	]


# Returns the result element id, or "" if no recipe exists. Order-independent.
static func find_result(id_a: String, id_b: String) -> String:
	for recipe: Dictionary in all_recipes():
		var ra: String = recipe["a"]
		var rb: String = recipe["b"]
		if (ra == id_a and rb == id_b) or (ra == id_b and rb == id_a):
			return recipe["result"]
	return ""
