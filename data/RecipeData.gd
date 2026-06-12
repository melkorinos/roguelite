class_name RecipeData

# 221 recipes across 4 tiers. Multiple recipes may share a result (alternate discovery paths).
# All combinations are order-independent: a+b == b+a. Self-combos (a==b) are valid.
# The recipe graph, built once at load and shared (zero-copy, read-only to callers).
const RECIPES: Array[Dictionary] = [
		# ══ Tier 2 — original 4 × original 4 ════════════════════════════════════
		{ "a": "water", "b": "fire",      "result": "steam"      },
		{ "a": "water", "b": "air",       "result": "rain"       },
		{ "a": "water", "b": "earth",     "result": "mud"        },
		{ "a": "fire",  "b": "air",       "result": "smoke"      },
		{ "a": "fire",  "b": "earth",     "result": "lava"       },
		{ "a": "air",   "b": "earth",     "result": "dust"       },
		# ══ Tier 2 — Lightning / Nature / Light / Dark / Metal / Fungus × original 4 ═══
		{ "a": "lightning", "b": "water",  "result": "surge"      },
		{ "a": "lightning", "b": "fire",   "result": "surge"        },
		{ "a": "lightning", "b": "air",    "result": "static"     },
		{ "a": "lightning", "b": "earth",  "result": "static"  },
		{ "a": "nature",    "b": "water",  "result": "root"      },
		{ "a": "nature",    "b": "fire",   "result": "ember"      },
		{ "a": "nature",    "b": "air",    "result": "pollen"     },
		{ "a": "nature",    "b": "earth",  "result": "root"       },
		{ "a": "light",     "b": "water",  "result": "crystal"      },
		{ "a": "light",     "b": "fire",   "result": "solar"      },
		{ "a": "light",     "b": "air",    "result": "solar"     },
		{ "a": "light",     "b": "earth",  "result": "crystal"    },
		{ "a": "dark",      "b": "water",  "result": "blight"      },
		{ "a": "dark",      "b": "fire",   "result": "blight"     },
		{ "a": "dark",      "b": "air",    "result": "shade"     },
		{ "a": "dark",      "b": "earth",  "result": "shade"      },
		{ "a": "metal",     "b": "water",  "result": "rust"       },
		{ "a": "metal",     "b": "fire",   "result": "molten"     },
		{ "a": "metal",     "b": "air",    "result": "rust"   },
		{ "a": "metal",     "b": "earth",  "result": "molten"      },
		{ "a": "fungus",    "b": "water",  "result": "sporeflow"  },
		{ "a": "fungus",    "b": "fire",   "result": "haze" },
		{ "a": "fungus",    "b": "air",    "result": "haze"       },
		{ "a": "fungus",    "b": "earth",  "result": "rootrot"    },
		# ══ Tier 2 — Blood × all ═════════════════════════════════════════════════
		{ "a": "blood", "b": "water",     "result": "pulse"       },
		{ "a": "blood", "b": "fire",      "result": "fever"       },
		{ "a": "blood", "b": "air",       "result": "pulse"    },
		{ "a": "blood", "b": "earth",     "result": "gore"   },
		{ "a": "blood", "b": "lightning", "result": "pulse"  },
		{ "a": "blood", "b": "nature",    "result": "pulse"  },
		{ "a": "blood", "b": "light",     "result": "fever"  },
		{ "a": "blood", "b": "dark",      "result": "nightveil"   },
		{ "a": "blood", "b": "metal",     "result": "gore"        },
		{ "a": "blood", "b": "fungus",    "result": "fever"  },
		{ "a": "blood", "b": "frost",     "result": "nightveil"   },
		# ══ Tier 2 — Frost × all ═════════════════════════════════════════════════
		{ "a": "frost", "b": "water",     "result": "blackice"    },
		{ "a": "frost", "b": "fire",      "result": "frostburn"   },
		{ "a": "frost", "b": "air",       "result": "hail"   },
		{ "a": "frost", "b": "earth",     "result": "permafrost"  },
		{ "a": "frost", "b": "lightning", "result": "hail"        },
		{ "a": "frost", "b": "nature",    "result": "wither"       },
		{ "a": "frost", "b": "light",     "result": "whiteout"    },
		{ "a": "frost", "b": "dark",      "result": "wither"      },
		{ "a": "frost", "b": "metal",     "result": "tempered"    },
		{ "a": "frost", "b": "fungus",    "result": "wither"  },
		# ══ Tier 2 — extended T1 × extended T1 ══════════════════════════════════
		{ "a": "dark",      "b": "fungus",    "result": "rot"            },
		{ "a": "lightning", "b": "fungus",    "result": "voltspore"       },
		{ "a": "nature",    "b": "light",     "result": "photosynthesis"  },
		{ "a": "nature",    "b": "metal",     "result": "ironwood"        },
		{ "a": "light",     "b": "metal",     "result": "lucent"          },
		{ "a": "light",     "b": "fungus",    "result": "lucent"          },
		{ "a": "dark",      "b": "metal",     "result": "hexcore"         },
		{ "a": "lightning", "b": "nature",    "result": "photosynthesis"      },
		{ "a": "lightning", "b": "light",     "result": "lucent"         },
		{ "a": "lightning", "b": "dark",      "result": "hexcore"       },
		{ "a": "lightning", "b": "metal",     "result": "hexcore"          },
		{ "a": "nature",    "b": "dark",      "result": "rot"             },
		{ "a": "nature",    "b": "fungus",    "result": "rot"         },
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
		{ "a": "rain",   "b": "solar",    "result": "rainbow"    },
		{ "a": "rain",   "b": "gust",     "result": "storm"      },
		{ "a": "rain",   "b": "root",     "result": "plant"      },
		{ "a": "mud",    "b": "blight",   "result": "swamp"      },
		{ "a": "mud",    "b": "blaze",    "result": "brick"      },
		{ "a": "smoke",  "b": "blaze",    "result": "ash"        },
		{ "a": "smoke",  "b": "blight",   "result": "acid"       },
		{ "a": "lava",   "b": "sea",      "result": "obsidian"   },
		{ "a": "lava",   "b": "boulder",  "result": "volcano"    },
		{ "a": "dust",   "b": "crystal",  "result": "sand"       },
		{ "a": "dust",   "b": "gust",     "result": "sandstorm"  },
		{ "a": "dust",   "b": "rain",     "result": "clay"       },
		# ══ Tier 3 — Frost cluster ════════════════════════════════════════════════
		{ "a": "freeze",     "b": "permafrost", "result": "glacier"      },
		{ "a": "blackice",   "b": "permafrost", "result": "glacier"      },
		{ "a": "sea",        "b": "freeze",     "result": "glacier"      },
		{ "a": "permafrost", "b": "wither",     "result": "tundra"       },
		{ "a": "boulder",    "b": "freeze",     "result": "tundra"       },
		# ══ Tier 3 — Nature cluster ═══════════════════════════════════════════════
		{ "a": "rain",       "b": "forest",     "result": "rainforest"   },
		{ "a": "forest",     "b": "shade",      "result": "ancientgrove" },
		{ "a": "root",       "b": "rot",        "result": "ancientgrove" },
		# ══ Tier 3 — Storm cluster ════════════════════════════════════════════════
		{ "a": "sea",        "b": "gust",       "result": "hurricane"    },
		{ "a": "surge",      "b": "gust",       "result": "hurricane"    },
		{ "a": "plasma",     "b": "static",     "result": "tempest"      },
		{ "a": "plasma",     "b": "hail",       "result": "tempest"      },
		# ══ Tier 3 — Earth cluster ════════════════════════════════════════════════
		{ "a": "sea",        "b": "boulder",    "result": "tsunami"      },
		# ══ Tier 3 — Light / Dark cluster ════════════════════════════════════════
		{ "a": "void",       "b": "radiance",   "result": "eclipse"      },
		{ "a": "umbra",      "b": "radiance",   "result": "eclipse"      },
		{ "a": "umbra",      "b": "solar",      "result": "eclipse"      },
		# ══ Tier 3 — Fungus cluster ═══════════════════════════════════════════════
		{ "a": "rootrot",    "b": "haze",       "result": "plague"       },
		{ "a": "moldsteel",  "b": "rootrot",    "result": "underrot"     },
		# ══ Tier 3 — Fire cluster ════════════════════════════════════════════════
		{ "a": "blaze",      "b": "blight",     "result": "inferno"      },
		{ "a": "blaze",      "b": "ember",      "result": "inferno"      },
		# ══ Tier 3 — Blood cluster ═══════════════════════════════════════════════
		{ "a": "ichor",      "b": "pulse",      "result": "hemorrhage"   },
		# ══ Tier 3 — Metal cluster ═══════════════════════════════════════════════
		{ "a": "steel",      "b": "void",       "result": "meteorite"    },
		{ "a": "molten",     "b": "plasma",     "result": "meteorite"    },
		# ══ Tier 4 — Frost cluster ════════════════════════════════════════════════
		{ "a": "glacier",    "b": "blizzard",   "result": "iceage"       },
		{ "a": "glacier",    "b": "tundra",     "result": "iceage"       },
		{ "a": "blizzard",   "b": "mountain",   "result": "iceage"       },
		# ══ Tier 4 — Storm cluster ════════════════════════════════════════════════
		{ "a": "storm",      "b": "tempest",    "result": "maelstrom"    },
		# ══ Tier 4 — Earth cluster ════════════════════════════════════════════════
		{ "a": "obsidian",   "b": "mountain",   "result": "tectonic"     },
		# ══ Tier 4 — Fire / Stellar cluster ══════════════════════════════════════
		{ "a": "inferno",    "b": "tempest",    "result": "supernova"    },
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
		{ "a": "underrot",   "b": "ancientgrove","result": "pandemic"    },
		# ══ Tier 4 — Blood / War cluster ═════════════════════════════════════════
		{ "a": "hemorrhage", "b": "carnage",    "result": "ragnarok"     },
		{ "a": "carnage",    "b": "inferno",    "result": "ragnarok"     },
		{ "a": "hemorrhage", "b": "plague",     "result": "ragnarok"     },
		# ══ Tier 4 — Genesis cluster ══════════════════════════════════════════════
		{ "a": "tsunami",    "b": "volcano",    "result": "primordial"   },
		{ "a": "volcano",    "b": "volcano",    "result": "primordial"   },
		# ══ Tier 4 — Transcendent cluster ════════════════════════════════════════
		{ "a": "eclipse",    "b": "meteorite",  "result": "aether"       },
		{ "a": "tempest",    "b": "voidrift",   "result": "aether"       },
		# ══ Dead-end elimination (ADR 0010) ═══════════════════════════════════════
		# Every former forward dead-end now feeds ≥1 higher recipe, routed up through
		# its cluster (the audit test test_no_non_apex_forward_dead_ends locks this).
		# T2 → T3
		{ "a": "sporeflow",      "b": "voltspore",  "result": "plague"       },
		{ "a": "rust",           "b": "hexcore",    "result": "meteorite"    },
		{ "a": "frostburn",      "b": "freeze",     "result": "glacier"      },
		{ "a": "photosynthesis", "b": "pollen",     "result": "rainforest"   },
		# T3 → T4
		{ "a": "cloud",          "b": "fog",        "result": "maelstrom"    },
		{ "a": "sandstorm",      "b": "hurricane",  "result": "maelstrom"    },
		{ "a": "geyser",         "b": "sand",       "result": "tectonic"     },
		{ "a": "clay",           "b": "brick",      "result": "tectonic"     },
		{ "a": "swamp",          "b": "tsunami",    "result": "primordial"   },
		{ "a": "acid",           "b": "plague",     "result": "pandemic"     },
		{ "a": "ash",            "b": "inferno",    "result": "supernova"    },
		{ "a": "rainbow",        "b": "eclipse",    "result": "aether"       },
		# ══ Tier 3 — second paths (recipe rebalance 2026-06-11): give every single-gated
		# original-cross T3 a 2nd discovery path; `arc+surge` rerouted here off Tempest.
		{ "a": "steam", "b": "smoke", "result": "cloud" },
		{ "a": "lava", "b": "steam", "result": "geyser" },
		{ "a": "smoke", "b": "haze", "result": "fog" },
		{ "a": "photosynthesis", "b": "root", "result": "plant" },
		{ "a": "mud", "b": "forest", "result": "swamp" },
		{ "a": "mud", "b": "steel", "result": "brick" },
		{ "a": "ember", "b": "lava", "result": "ash" },
		{ "a": "mud", "b": "sporeflow", "result": "acid" },
		{ "a": "molten", "b": "freeze", "result": "obsidian" },
		{ "a": "lava", "b": "lava", "result": "volcano" },
		{ "a": "dust", "b": "dust", "result": "sand" },
		{ "a": "dust", "b": "smoke", "result": "sandstorm" },
		{ "a": "dust", "b": "sea", "result": "clay" },
		# ══ Out-degree rebalance (2026-06-12): every T2/T3 now feeds ≥2 recipes ═══
		# New pairs combine previously single-use elements, cluster-themed; T3/T4
		# in-degree stays ≤4 (meteorite 5, structurally forced).
		# T2 → T3
		{ "a": "static",     "b": "voltspore",  "result": "tempest"      },
		{ "a": "tempered",   "b": "boulder",    "result": "mountain"     },
		{ "a": "rust",       "b": "moldsteel",  "result": "underrot"     },
		{ "a": "whiteout",   "b": "frostburn",  "result": "blizzard"     },
		{ "a": "pulse",      "b": "fever",      "result": "hemorrhage"   },
		# T3 → T4
		{ "a": "storm",      "b": "cloud",      "result": "maelstrom"    },
		{ "a": "fog",        "b": "ash",        "result": "singularity"  },
		{ "a": "sand",       "b": "sandstorm",  "result": "tectonic"     },
		# tectonic sits at 5 paths like meteorite: it is the only earth-family T4
		# sink for 7 earthy T3s, so the convergence is structurally forced.
		{ "a": "clay",       "b": "obsidian",   "result": "tectonic"     },
		{ "a": "brick",      "b": "tundra",     "result": "iceage"       },
		{ "a": "swamp",      "b": "geyser",     "result": "primordial"   },
		{ "a": "rainbow",    "b": "plant",      "result": "worldtree"    },
		{ "a": "obsidian",   "b": "carnage",    "result": "ragnarok"     },
		{ "a": "acid",       "b": "swamp",      "result": "pandemic"     },
		{ "a": "hurricane",  "b": "tempest",    "result": "aether"       },
		# ══ T2 consolidation re-floor (2026-06-12): replacement paths after the
		# 78→51 roster cut, keeping every T2/T3 out-degree ≥2 and T3 in-degree 2–4.
		{ "a": "steam",      "b": "whiteout",   "result": "fog"          },
		{ "a": "lucent",     "b": "haze",       "result": "fog"          },
		{ "a": "lucent",     "b": "rain",       "result": "rainbow"      },
		{ "a": "static",     "b": "gust",       "result": "storm"        },
		{ "a": "blackice",   "b": "hail",       "result": "blizzard"     },
		{ "a": "tempered",   "b": "blackice",   "result": "blizzard"     },
		{ "a": "wither",     "b": "blackice",   "result": "tundra"       },
		{ "a": "crystal",    "b": "permafrost", "result": "mountain"     },
		{ "a": "surge",      "b": "sea",        "result": "tsunami"      },
		{ "a": "void",       "b": "shade",      "result": "voidrift"     },
		{ "a": "void",       "b": "hexcore",    "result": "voidrift"     },
		{ "a": "nightveil",  "b": "void",       "result": "voidrift"     },
		{ "a": "gore",       "b": "fever",      "result": "carnage"      },
		{ "a": "gore",       "b": "nightveil",  "result": "carnage"      },
		{ "a": "ichor",      "b": "fever",      "result": "hemorrhage"   },
		{ "a": "mycelium",   "b": "rot",        "result": "plague"       },
		{ "a": "pollen",     "b": "haze",       "result": "plague"       },
		{ "a": "mycelium",   "b": "root",       "result": "plant"        },
		{ "a": "ironwood",   "b": "forest",     "result": "ancientgrove" },
		{ "a": "ironwood",   "b": "photosynthesis", "result": "ancientgrove" },
	]


static func all_recipes() -> Array[Dictionary]:
	return RECIPES


# ── lazy indices over the const RECIPES, built once on first lookup ────────────
# Returned arrays/dicts are SHARED (zero-copy); callers read them, never mutate.
static var _pair_to_result: Dictionary = {}     # "a|b" (sorted) → result id
static var _by_ingredient: Dictionary = {}      # ingredient id → Array[{partner,result}]
static var _by_result: Dictionary = {}          # result id → Array[{a,b}]
static var _ingredients_index: Dictionary = {}  # result id → Array[String] (deduped)


static func _ensure_indices() -> void:
	if not _pair_to_result.is_empty() or RECIPES.is_empty():
		return
	for recipe: Dictionary in RECIPES:
		var a: String = recipe["a"] as String
		var b: String = recipe["b"] as String
		var result: String = recipe["result"] as String
		_pair_to_result[_pair_key(a, b)] = result
		_add_partner(a, b, result)
		if b != a:  # a self-combo contributes a single forward entry, matching the old scan
			_add_partner(b, a, result)
		_add_result(a, b, result)


static func _pair_key(a: String, b: String) -> String:
	return (a + "|" + b) if a <= b else (b + "|" + a)


static func _add_partner(ingredient: String, partner: String, result: String) -> void:
	if not _by_ingredient.has(ingredient):
		_by_ingredient[ingredient] = [] as Array[Dictionary]
	(_by_ingredient[ingredient] as Array[Dictionary]).append({ "partner": partner, "result": result })


static func _add_result(a: String, b: String, result: String) -> void:
	if not _by_result.has(result):
		_by_result[result] = [] as Array[Dictionary]
	(_by_result[result] as Array[Dictionary]).append({ "a": a, "b": b })
	if not _ingredients_index.has(result):
		_ingredients_index[result] = [] as Array[String]
	var ingredients: Array[String] = _ingredients_index[result]
	if not ingredients.has(a):
		ingredients.append(a)
	if not ingredients.has(b):
		ingredients.append(b)


# Returns the result element id, or "" if no recipe exists. Order-independent.
static func find_result(id_a: String, id_b: String) -> String:
	_ensure_indices()
	return _pair_to_result.get(_pair_key(id_a, id_b), "") as String


# Every recipe the given ingredient participates in, as { "partner": id, "result": id }.
# The forward counterpart of ingredients_of (the reverse: what forges INTO X). For a
# self-combo (water + water → sea) the partner is the ingredient itself (one entry).
# Drives the Forge bench's "this forges with…" discoverability hint (ADR 0009).
static func recipes_with(ingredient_id: String) -> Array[Dictionary]:
	_ensure_indices()
	return _by_ingredient.get(ingredient_id, [] as Array[Dictionary]) as Array[Dictionary]


# Every recipe that PRODUCES the given element, as { "a": id, "b": id } ingredient
# pairs (alternate paths → multiple pairs). The pair-preserving counterpart of
# ingredients_of. Drives the "Made from" display on the Item Tooltip + Forge hint (ADR 0009).
static func recipes_for(result_id: String) -> Array[Dictionary]:
	_ensure_indices()
	return _by_result.get(result_id, [] as Array[Dictionary]) as Array[Dictionary]


# Resolves a recipe pair { a, b } of element ids into their full Element defs for
# display ("Made from" rows, Compendium recipe lines). The single place that turns
# a stored pair into renderable elements. Returns {} when either id is unknown.
static func describe_pair(pair: Dictionary) -> Dictionary:
	var a: Dictionary = ElementData.find(pair["a"] as String)
	var b: Dictionary = ElementData.find(pair["b"] as String)
	if a.is_empty() or b.is_empty():
		return {}
	return { "a": a, "b": b }


# The deduped set of ingredient ids that can forge `result_id` — the union across every
# recipe producing it. Used by the shop's family filter (ADR 0007).
static func ingredients_of(result_id: String) -> Array[String]:
	_ensure_indices()
	return _ingredients_index.get(result_id, [] as Array[String]) as Array[String]
