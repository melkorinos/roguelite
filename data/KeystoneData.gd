class_name KeystoneData

# The Starting-Pick Keystone roster (ADR 0016). Each entry is an Augment (source_type
# "keystone") plus presentation metadata (emoji, axis, tags, description). Its effect
# atoms are validated by AugmentSystem.validate_atom (locked by test_keystone_data).
# Per-unit magnitudes live in TuningData.KEYSTONE_* — all FLAT integers; scaling Keystones
# multiply them by a board count via `scale_by` (no percentages — integer combat model).
#
# This is the v1 PROOF slice (~10), chosen for FUNCTIONALITY coverage rather than element
# variety (per the design call): each card exercises a DISTINCT mechanic so the seam is
# proven end-to-end and extending later is mostly swapping in elements/Families.
#   flat-amplify · scaling-by-count · scaling-by-levels · suppress-pact · flat-damage-pact
#   · cooldown-pact · shop-weight · shop+amplify combo · run-state HP · run-state economy.
#
# axis_kind ∈ {"family","status","neutral"} drives the Starting-Pick variety guarantee
# (StartSystem.starting_options ensures ≥1 Family- and ≥1 Status-axis card per offer).
#
# Built lazily (it references TuningData) and cached, mirroring ElementData/AbilityData.

static var _roster: Array[Dictionary] = []
static var _by_id: Dictionary = {}


static func all() -> Array[Dictionary]:
	if _roster.is_empty():
		_roster = _build()
		for keystone: Dictionary in _roster:
			_by_id[keystone["id"] as String] = keystone
	return _roster


static func find(id: String) -> Dictionary:
	all()
	return _by_id.get(id, {}) as Dictionary


static func _build() -> Array[Dictionary]:
	return [
		{
			"id": "ashen_affinity", "name": "Ashen Affinity", "emoji": "🔥",
			"axis_kind": "family", "axis": "fire", "source_type": "keystone",
			"tags": ["Fire Family", "flat", "amplify"],
			"description": "Your burns tick harder.",
			"effects": [
				{ "kind": "set_status_field", "scope": "combat", "status": "burn", "field": "tick_damage_bonus", "value": TuningData.KEYSTONE_BURN_TICK_BONUS, "target": "opponent" },
			],
		},
		{
			"id": "emberswarm", "name": "Emberswarm", "emoji": "🔥",
			"axis_kind": "family", "axis": "fire", "source_type": "keystone",
			"tags": ["Fire Family", "scaling", "amplify"],
			"description": "Your burns tick harder for every Fire element you field — scales as you lean in.",
			"effects": [
				{ "kind": "set_status_field", "scope": "combat", "status": "burn", "field": "tick_damage_bonus", "value": TuningData.KEYSTONE_BURN_TICK_BONUS, "scale_by": "family_count:fire", "target": "opponent" },
			],
		},
		{
			"id": "bulwark_oath", "name": "Bulwark Oath", "emoji": "🛡️",
			"axis_kind": "status", "axis": "armor", "source_type": "keystone",
			"tags": ["Armor", "flat", "pact"],
			"description": "Hold a permanent Armor floor.",
			"pact": "Your direct hits deal less damage.",
			"effects": [
				{ "kind": "set_status_field", "scope": "combat", "status": "armor", "field": "floor", "value": TuningData.KEYSTONE_ARMOR_FLOOR, "target": "own" },
				{ "kind": "set_side_field", "scope": "combat", "field": "outgoing_damage_flat", "amount": TuningData.KEYSTONE_OUTGOING_DAMAGE_PENALTY, "target": "own" },
			],
		},
		{
			"id": "stormcallers_mark", "name": "Stormcaller's Mark", "emoji": "⚡",
			"axis_kind": "family", "axis": "lightning", "source_type": "keystone",
			"tags": ["Lightning Family", "shop", "amplify"],
			"description": "Lightning appears more often in your shop, and your Shock slows harder.",
			"effects": [
				{ "kind": "shop_weight", "scope": "shop_gen", "family": "lightning", "copies": TuningData.KEYSTONE_SHOP_WEIGHT_COPIES },
				{ "kind": "set_status_field", "scope": "combat", "status": "shock", "field": "effective_stack_bonus", "value": TuningData.KEYSTONE_SHOCK_STACK_BONUS, "target": "opponent" },
			],
		},
		{
			"id": "plague_pact", "name": "Plague Pact", "emoji": "🧪",
			"axis_kind": "status", "axis": "poison", "source_type": "keystone",
			"tags": ["Poison", "flat", "pact"],
			"description": "Your poison bites harder.",
			"pact": "You cannot heal or cleanse.",
			"effects": [
				{ "kind": "set_status_field", "scope": "combat", "status": "poison", "field": "tick_damage_bonus", "value": TuningData.KEYSTONE_POISON_TICK_BONUS, "target": "opponent" },
				{ "kind": "suppress", "scope": "combat", "status": "heal", "target": "own" },
				{ "kind": "suppress", "scope": "combat", "status": "cleanse", "target": "own" },
			],
		},
		{
			"id": "deepfreeze_doctrine", "name": "Deepfreeze Doctrine", "emoji": "🌨️",
			"axis_kind": "family", "axis": "frost", "source_type": "keystone",
			"tags": ["Frost Family", "scaling", "pact"],
			"description": "Weaken lingers longer the more Frost levels you stack.",
			"pact": "Your elements fire slower.",
			"effects": [
				{ "kind": "set_status_field", "scope": "combat", "status": "weaken", "field": "duration_bonus", "value": TuningData.KEYSTONE_WEAKEN_DURATION_PER_LEVEL, "scale_by": "family_levels:frost", "target": "opponent" },
				{ "kind": "set_side_field", "scope": "combat", "field": "cooldown_modifier_deciseconds", "amount": TuningData.KEYSTONE_COOLDOWN_PENALTY_DECISECONDS, "target": "own" },
			],
		},
		{
			"id": "tectonic_ward", "name": "Tectonic Ward", "emoji": "🌍",
			"axis_kind": "family", "axis": "earth", "source_type": "keystone",
			"tags": ["Earth Family", "scaling", "amplify"],
			"description": "Your Armor floor grows with every Earth level you field.",
			"effects": [
				{ "kind": "set_status_field", "scope": "combat", "status": "armor", "field": "floor", "value": TuningData.KEYSTONE_ARMOR_FLOOR_PER_LEVEL, "scale_by": "family_levels:earth", "target": "own" },
			],
		},
		{
			"id": "twin_catalyst", "name": "Twin Catalyst", "emoji": "🔥",
			"axis_kind": "family", "axis": "fire", "source_type": "keystone",
			"tags": ["Fire Family", "shop", "amplify"],
			"description": "Fire appears more often in your shop, and your burns tick harder.",
			"effects": [
				{ "kind": "shop_weight", "scope": "shop_gen", "family": "fire", "copies": TuningData.KEYSTONE_SHOP_WEIGHT_COPIES },
				{ "kind": "set_status_field", "scope": "combat", "status": "burn", "field": "tick_damage_bonus", "value": TuningData.KEYSTONE_BURN_TICK_BONUS, "target": "opponent" },
			],
		},
		{
			"id": "verdant_vigor", "name": "Verdant Vigor", "emoji": "🌿",
			"axis_kind": "family", "axis": "nature", "source_type": "keystone",
			"tags": ["Nature Family", "flat", "run"],
			"description": "Gain bonus max HP in every battle this run.",
			"effects": [
				{ "kind": "bonus_hp", "scope": "run_state", "amount": TuningData.KEYSTONE_BONUS_HP },
			],
		},
		{
			"id": "prospectors_eye", "name": "Prospector's Eye", "emoji": "💰",
			"axis_kind": "neutral", "axis": "economy", "source_type": "keystone",
			"tags": ["Economy", "flat", "run"],
			"description": "Shop rerolls cost less for the rest of the run.",
			"effects": [
				{ "kind": "reroll_discount", "scope": "run_state", "amount": TuningData.KEYSTONE_REROLL_DISCOUNT },
			],
		},
	]
