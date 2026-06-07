class_name RecipeData

# 169 recipes across 4 tiers. Multiple recipes may share a result (alternate discovery paths).
# All combinations are order-independent: a+b == b+a. Self-combos (a==b) are valid.
static func all_recipes() -> Array[Dictionary]:
	return [
		# ══ Tier 2 — original 4 × original 4 ════════════════════════════════════
		{ "a": "water", "b": "fire",      "result": "steam"      },
		{ "a": "water", "b": "air",       "result": "rain"       },
		{ "a": "water", "b": "earth",     "result": "mud"        },
		{ "a": "fire",  "b": "air",       "result": "smoke"      },
		{ "a": "fire",  "b": "earth",     "result": "lava"       },
		{ "a": "air",   "b": "earth",     "result": "dust"       },
		# ══ Tier 2 — Lightning / Nature / Light / Dark / Metal / Fungus × original 4 ═══
		{ "a": "lightning", "b": "water",  "result": "surge"      },
		{ "a": "lightning", "b": "fire",   "result": "arc"        },
		{ "a": "lightning", "b": "air",    "result": "static"     },
		{ "a": "lightning", "b": "earth",  "result": "lodestone"  },
		{ "a": "nature",    "b": "water",  "result": "bloom"      },
		{ "a": "nature",    "b": "fire",   "result": "ember"      },
		{ "a": "nature",    "b": "air",    "result": "pollen"     },
		{ "a": "nature",    "b": "earth",  "result": "root"       },
		{ "a": "light",     "b": "water",  "result": "prism"      },
		{ "a": "light",     "b": "fire",   "result": "solar"      },
		{ "a": "light",     "b": "air",    "result": "aurora"     },
		{ "a": "light",     "b": "earth",  "result": "crystal"    },
		{ "a": "dark",      "b": "water",  "result": "abyss"      },
		{ "a": "dark",      "b": "fire",   "result": "blight"     },
		{ "a": "dark",      "b": "air",    "result": "miasma"     },
		{ "a": "dark",      "b": "earth",  "result": "shade"      },
		{ "a": "metal",     "b": "water",  "result": "rust"       },
		{ "a": "metal",     "b": "fire",   "result": "molten"     },
		{ "a": "metal",     "b": "air",    "result": "shrapnel"   },
		{ "a": "metal",     "b": "earth",  "result": "flint"      },
		{ "a": "fungus",    "b": "water",  "result": "sporeflow"  },
		{ "a": "fungus",    "b": "fire",   "result": "fireshroom" },
		{ "a": "fungus",    "b": "air",    "result": "haze"       },
		{ "a": "fungus",    "b": "earth",  "result": "rootrot"    },
		# ══ Tier 2 — Blood × all ═════════════════════════════════════════════════
		{ "a": "blood", "b": "water",     "result": "pulse"       },
		{ "a": "blood", "b": "fire",      "result": "fever"       },
		{ "a": "blood", "b": "air",       "result": "hemowind"    },
		{ "a": "blood", "b": "earth",     "result": "ironblood"   },
		{ "a": "blood", "b": "lightning", "result": "sparkblood"  },
		{ "a": "blood", "b": "nature",    "result": "lifebloom"  },
		{ "a": "blood", "b": "light",     "result": "hemogoblin"  },
		{ "a": "blood", "b": "dark",      "result": "nightveil"   },
		{ "a": "blood", "b": "metal",     "result": "gore"        },
		{ "a": "blood", "b": "fungus",    "result": "hemospore"  },
		{ "a": "blood", "b": "frost",     "result": "frostbite"   },
		# ══ Tier 2 — Frost × all ═════════════════════════════════════════════════
		{ "a": "frost", "b": "water",     "result": "blackice"    },
		{ "a": "frost", "b": "fire",      "result": "frostburn"   },
		{ "a": "frost", "b": "air",       "result": "razorwind"   },
		{ "a": "frost", "b": "earth",     "result": "permafrost"  },
		{ "a": "frost", "b": "lightning", "result": "hail"        },
		{ "a": "frost", "b": "nature",    "result": "chill"       },
		{ "a": "frost", "b": "light",     "result": "whiteout"    },
		{ "a": "frost", "b": "dark",      "result": "wither"      },
		{ "a": "frost", "b": "metal",     "result": "tempered"    },
		{ "a": "frost", "b": "fungus",    "result": "cryptbloom"  },
		# ══ Tier 2 — extended T1 × extended T1 ══════════════════════════════════
		{ "a": "dark",      "b": "fungus",    "result": "murk"            },
		{ "a": "lightning", "b": "fungus",    "result": "voltspore"       },
		{ "a": "nature",    "b": "light",     "result": "photosynthesis"  },
		{ "a": "nature",    "b": "metal",     "result": "ironwood"        },
		{ "a": "light",     "b": "metal",     "result": "beacon"          },
		{ "a": "light",     "b": "fungus",    "result": "lucent"          },
		{ "a": "dark",      "b": "metal",     "result": "hexcore"         },
		{ "a": "lightning", "b": "nature",    "result": "bloomspark"      },
		{ "a": "lightning", "b": "light",     "result": "arcbeam"         },
		{ "a": "lightning", "b": "dark",      "result": "voidspark"       },
		{ "a": "lightning", "b": "metal",     "result": "magnet"          },
		{ "a": "nature",    "b": "dark",      "result": "rot"             },
		{ "a": "nature",    "b": "fungus",    "result": "wildrot"         },
		{ "a": "light",     "b": "dark",      "result": "umbra"           },
		{ "a": "metal",     "b": "fungus",    "result": "moldsteel"       },
		# ══ Tier 2 — self-combos ═════════════════════════════════════════════════
		{ "a": "water",     "b": "water",     "result": "sea"        },
		{ "a": "fire",      "b": "fire",      "result": "blaze"      },
		{ "a": "air",       "b": "air",       "result": "gust"       },
		{ "a": "earth",     "b": "earth",     "result": "boulder"    },
		{ "a": "lightning", "b": "lightning", "result": "plasma"     },
		{ "a": "nature",    "b": "nature",    "result": "forest"     },
		{ "a": "light",     "b": "light",     "result": "radiance"   },
		{ "a": "dark",      "b": "dark",      "result": "void"       },
		{ "a": "metal",     "b": "metal",     "result": "steel"      },
		{ "a": "fungus",    "b": "fungus",    "result": "mycelium"   },
		{ "a": "frost",     "b": "frost",     "result": "freeze"     },
		{ "a": "blood",     "b": "blood",     "result": "ichor"      },
		# ══ Tier 3 — original T2 cross (all T2 + T2) ════════════════════════════
		{ "a": "steam",  "b": "gust",     "result": "cloud"      },
		{ "a": "steam",  "b": "boulder",  "result": "geyser"     },
		{ "a": "steam",  "b": "rain",     "result": "fog"        },
		{ "a": "rain",   "b": "solar",    "result": "rainbow"    },
		{ "a": "rain",   "b": "gust",     "result": "storm"      },
		{ "a": "rain",   "b": "root",     "result": "plant"      },
		{ "a": "mud",    "b": "rain",     "result": "swamp"      },
		{ "a": "mud",    "b": "blaze",    "result": "brick"      },
		{ "a": "smoke",  "b": "blaze",    "result": "ash"        },
		{ "a": "smoke",  "b": "rain",     "result": "acid"       },
		{ "a": "lava",   "b": "sea",      "result": "obsidian"   },
		{ "a": "lava",   "b": "boulder",  "result": "volcano"    },
		{ "a": "dust",   "b": "boulder",  "result": "sand"       },
		{ "a": "dust",   "b": "gust",     "result": "sandstorm"  },
		{ "a": "dust",   "b": "rain",     "result": "clay"       },
		# ══ Tier 3 — Frost cluster ════════════════════════════════════════════════
		{ "a": "freeze",     "b": "permafrost", "result": "glacier"      },
		{ "a": "blackice",   "b": "permafrost", "result": "glacier"      },
		{ "a": "sea",        "b": "freeze",     "result": "glacier"      },
		{ "a": "blackice",   "b": "razorwind",  "result": "blizzard"     },
		{ "a": "hail",       "b": "razorwind",  "result": "blizzard"     },
		{ "a": "gust",       "b": "hail",       "result": "blizzard"     },
		{ "a": "permafrost", "b": "chill",      "result": "tundra"       },
		{ "a": "permafrost", "b": "wither",     "result": "tundra"       },
		{ "a": "boulder",    "b": "freeze",     "result": "tundra"       },
		# ══ Tier 3 — Nature cluster ═══════════════════════════════════════════════
		{ "a": "bloom",      "b": "root",       "result": "rainforest"   },
		{ "a": "forest",     "b": "bloom",      "result": "rainforest"   },
		{ "a": "rain",       "b": "forest",     "result": "rainforest"   },
		{ "a": "forest",     "b": "shade",      "result": "ancientgrove" },
		{ "a": "ironwood",   "b": "wildrot",    "result": "ancientgrove" },
		{ "a": "root",       "b": "rot",        "result": "ancientgrove" },
		# ══ Tier 3 — Storm cluster ════════════════════════════════════════════════
		{ "a": "sea",        "b": "gust",       "result": "hurricane"    },
		{ "a": "surge",      "b": "gust",       "result": "hurricane"    },
		{ "a": "plasma",     "b": "static",     "result": "tempest"      },
		{ "a": "arc",        "b": "surge",      "result": "tempest"      },
		{ "a": "plasma",     "b": "hail",       "result": "tempest"      },
		# ══ Tier 3 — Earth cluster ════════════════════════════════════════════════
		{ "a": "boulder",    "b": "flint",      "result": "mountain"     },
		{ "a": "boulder",    "b": "permafrost", "result": "mountain"     },
		{ "a": "sea",        "b": "boulder",    "result": "tsunami"      },
		{ "a": "sea",        "b": "permafrost", "result": "tsunami"      },
		# ══ Tier 3 — Light / Dark cluster ════════════════════════════════════════
		{ "a": "void",       "b": "radiance",   "result": "eclipse"      },
		{ "a": "umbra",      "b": "radiance",   "result": "eclipse"      },
		{ "a": "umbra",      "b": "solar",      "result": "eclipse"      },
		{ "a": "void",       "b": "abyss",      "result": "voidrift"     },
		{ "a": "void",       "b": "miasma",     "result": "voidrift"     },
		{ "a": "voidspark",  "b": "void",       "result": "voidrift"     },
		# ══ Tier 3 — Fungus cluster ═══════════════════════════════════════════════
		{ "a": "mycelium",   "b": "murk",       "result": "plague"       },
		{ "a": "cryptbloom", "b": "murk",       "result": "plague"       },
		{ "a": "rootrot",    "b": "haze",       "result": "plague"       },
		{ "a": "rootrot",    "b": "wildrot",    "result": "underrot"     },
		{ "a": "moldsteel",  "b": "rootrot",    "result": "underrot"     },
		# ══ Tier 3 — Fire cluster ════════════════════════════════════════════════
		{ "a": "blaze",      "b": "blight",     "result": "inferno"      },
		{ "a": "blaze",      "b": "ember",      "result": "inferno"      },
		{ "a": "arc",        "b": "blaze",      "result": "inferno"      },
		# ══ Tier 3 — Blood cluster ═══════════════════════════════════════════════
		{ "a": "ichor",      "b": "pulse",      "result": "hemorrhage"   },
		{ "a": "ichor",      "b": "lifebloom",  "result": "hemorrhage"   },
		{ "a": "fever",      "b": "hemowind",   "result": "hemorrhage"   },
		{ "a": "gore",       "b": "ironblood",  "result": "carnage"      },
		{ "a": "gore",       "b": "sparkblood", "result": "carnage"      },
		# ══ Tier 3 — Metal cluster ═══════════════════════════════════════════════
		{ "a": "steel",      "b": "void",       "result": "meteorite"    },
		{ "a": "steel",      "b": "radiance",   "result": "meteorite"    },
		{ "a": "molten",     "b": "plasma",     "result": "meteorite"    },
		# ══ Tier 4 — Frost cluster ════════════════════════════════════════════════
		{ "a": "glacier",    "b": "blizzard",   "result": "iceage"       },
		{ "a": "glacier",    "b": "tundra",     "result": "iceage"       },
		{ "a": "blizzard",   "b": "mountain",   "result": "iceage"       },
		# ══ Tier 4 — Storm cluster ════════════════════════════════════════════════
		{ "a": "hurricane",  "b": "tempest",    "result": "maelstrom"    },
		{ "a": "hurricane",  "b": "blizzard",   "result": "maelstrom"    },
		{ "a": "storm",      "b": "tempest",    "result": "maelstrom"    },
		# ══ Tier 4 — Earth cluster ════════════════════════════════════════════════
		{ "a": "mountain",   "b": "tsunami",    "result": "tectonic"     },
		{ "a": "mountain",   "b": "volcano",    "result": "tectonic"     },
		{ "a": "obsidian",   "b": "mountain",   "result": "tectonic"     },
		# ══ Tier 4 — Fire / Stellar cluster ══════════════════════════════════════
		{ "a": "inferno",    "b": "tempest",    "result": "supernova"    },
		{ "a": "inferno",    "b": "meteorite",  "result": "supernova"    },
		{ "a": "inferno",    "b": "volcano",    "result": "supernova"    },
		# ══ Tier 4 — Void cluster ════════════════════════════════════════════════
		{ "a": "voidrift",   "b": "eclipse",    "result": "singularity"  },
		{ "a": "voidrift",   "b": "meteorite",  "result": "singularity"  },
		{ "a": "eclipse",    "b": "eclipse",    "result": "singularity"  },
		# ══ Tier 4 — Nature cluster ═══════════════════════════════════════════════
		{ "a": "rainforest", "b": "ancientgrove","result": "worldtree"   },
		{ "a": "rainforest", "b": "plant",      "result": "worldtree"    },
		{ "a": "ancientgrove","b": "plant",     "result": "worldtree"    },
		# ══ Tier 4 — Fungus cluster ═══════════════════════════════════════════════
		{ "a": "plague",     "b": "underrot",   "result": "pandemic"     },
		{ "a": "plague",     "b": "carnage",    "result": "pandemic"     },
		{ "a": "underrot",   "b": "ancientgrove","result": "pandemic"    },
		# ══ Tier 4 — Blood / War cluster ═════════════════════════════════════════
		{ "a": "hemorrhage", "b": "carnage",    "result": "ragnarok"     },
		{ "a": "carnage",    "b": "inferno",    "result": "ragnarok"     },
		{ "a": "hemorrhage", "b": "plague",     "result": "ragnarok"     },
		# ══ Tier 4 — Genesis cluster ══════════════════════════════════════════════
		{ "a": "tsunami",    "b": "volcano",    "result": "primordial"   },
		{ "a": "inferno",    "b": "tsunami",    "result": "primordial"   },
		{ "a": "volcano",    "b": "volcano",    "result": "primordial"   },
		# ══ Tier 4 — Transcendent cluster ════════════════════════════════════════
		{ "a": "eclipse",    "b": "meteorite",  "result": "aether"       },
		{ "a": "eclipse",    "b": "rainforest", "result": "aether"       },
		{ "a": "tempest",    "b": "voidrift",   "result": "aether"       },
	]


# Returns the result element id, or "" if no recipe exists. Order-independent.
static func find_result(id_a: String, id_b: String) -> String:
	for recipe: Dictionary in all_recipes():
		var ra: String = recipe["a"]
		var rb: String = recipe["b"]
		if (ra == id_a and rb == id_b) or (ra == id_b and rb == id_a):
			return recipe["result"]
	return ""


# The set of ingredient ids that can forge `result_id` — the union across every
# recipe producing it (a result may have alternate paths). Used by the shop's
# family filter to know which "families" a discovered element belongs to.
static func ingredients_of(result_id: String) -> Array[String]:
	var ingredients: Dictionary = {}
	for recipe: Dictionary in all_recipes():
		if (recipe["result"] as String) == result_id:
			ingredients[recipe["a"] as String] = true
			ingredients[recipe["b"] as String] = true
	var result: Array[String] = []
	for id: String in ingredients:
		result.append(id)
	return result
