class_name AugmentSystem

# The Augment seam (ADR 0016) — the universal mechanism shared by the Starting-Pick
# Keystone, Event Rewards, and (future) Trinkets. An Augment is an acquired source that
# carries scope-tagged effect ATOMS; this system owns the atom vocabulary and the FOUR
# scope apply functions. There is deliberately NO single apply() path: each scope is
# applied at its own site by the system that owns it —
#   run_state     → materialized here into discrete cache fields, read by
#                   PhaseSystem._scaled_player_hp and ShopSystem.reroll_cost
#   shop_gen      → ShopSystem reads shop_weights() when building the shop row
#   combat        → PhaseSystem.begin_combat calls apply_combat_start() AFTER
#                   AbilitySystem.resolve_combat_start (player side only)
#   round_result  → PhaseSystem.advance_round calls apply_round_result()
#
# Pure static functions over the GameState dict, mirroring the other systems: nothing
# here touches the SceneTree, and the public fns return a new dict (never mutate input).
#
# Augment shape:
#   { "id": String, "name": String,
#     "source_type": "keystone"|"event_reward"|"trinket",
#     "effects": Array[Dictionary] }      # each effect is an atom
# Atom shape — the SHARED unit with Abilities (see AbilitySystem.ATOM_SCHEMAS), plus a
# `scope` tag that routes it to its apply site:
#   { "kind": String, "scope": "run_state"|"shop_gen"|"combat"|"round_result", ...params }
#
# Combat-scope atoms ARE ability atoms (set_status_field, suppress, …) and reuse that
# vocabulary + validator. The other three scopes use this system's own atom kinds below.

const SCOPES: Array[String] = ["run_state", "shop_gen", "combat", "round_result"]

# scale_by prefixes (ADR 0016): a combat atom's per-unit `value`/`amount` may be
# multiplied by an integer board count so the bonus stays relevant late-game without
# percentages. Format "<kind>" or "<kind>:<family>". All integer × integer.
#   family_count:<t1>   → player board pieces descended from that Tier-1 Family
#   family_levels:<t1>  → sum of those pieces' Levels (rides the same curve combat scales on)
#   board_size          → occupied player slots
#   round               → the current round number
const SCALE_KINDS: Array[String] = ["family_count", "family_levels", "board_size", "round"]

# The non-combat atom kinds this system owns (combat atoms live in AbilitySystem):
#   run_state    → materialized into a discrete cache field:
#       bonus_hp             {amount:int}  → hp_bonus         (flat, added to round-scaled base)
#       bonus_hp_percent     {amount:int}  → hp_bonus_percent (scales the base, percent)
#       reroll_discount      {amount:int}  → reroll_discount  (subtracted from the reroll cost)
#   shop_gen     → a soft bias WITHIN the already-eligible shop pool (never bypasses
#                  tier gating, ADR 0007/0015):
#       shop_weight          {family:String, copies:int}  → extra copies of that Family
#   round_result → evaluated against the finished round's outcome:
#       bonus_gold_on_result {result:"win"|"loss"|"any", amount:int}  → gold after the round
const ATOM_SCHEMAS: Dictionary = {
	"bonus_hp":             { "scope": "run_state",    "required": ["amount"] },
	"bonus_hp_percent":     { "scope": "run_state",    "required": ["amount"] },
	"reroll_discount":      { "scope": "run_state",    "required": ["amount"] },
	"shop_weight":          { "scope": "shop_gen",     "required": ["family", "copies"] },
	"bonus_gold_on_result": { "scope": "round_result", "required": ["result", "amount"] },
}


# ── validation (mirrors AbilitySystem.validate_atom; locked by a data test) ─────

# Validates one Augment atom. Combat-scope atoms are delegated to the shared ability
# vocabulary (AbilitySystem.ATOM_SCHEMAS); every other scope uses this system's schema.
# Returns human-readable error strings (empty Array = valid).
static func validate_atom(atom: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var scope: String = atom.get("scope", "") as String
	if not SCOPES.has(scope):
		errors.append("atom missing/unknown scope: '%s'" % scope)
		return errors
	if scope == "combat":
		# Combat atoms are ability atoms — reuse their validator (kind + required fields),
		# then add the Augment-specific checks the shared validator doesn't cover.
		var combat_errors: Array[String] = AbilitySystem.validate_atom(atom)
		var combat_kind: String = atom.get("kind", "") as String
		if combat_kind == "set_status_field" and atom.has("status") and atom.has("field"):
			if not EffectRegistry.is_modifier_field(atom["status"] as String, atom["field"] as String):
				combat_errors.append("set_status_field %s.%s is not a registered modifier" % [atom["status"], atom["field"]])
		if combat_kind == "set_side_field" and atom.has("field"):
			var side_field: String = atom["field"] as String
			if not (EffectRegistry.SIDE_WIDE_FIELDS.has(side_field) and typeof(EffectRegistry.SIDE_WIDE_FIELDS[side_field]) == TYPE_INT):
				combat_errors.append("set_side_field '%s' is not a numeric side-wide field" % side_field)
		if atom.has("scale_by") and not _valid_scale_by(atom["scale_by"] as String):
			combat_errors.append("unknown scale_by: '%s'" % atom["scale_by"])
		return combat_errors
	var kind: String = atom.get("kind", "") as String
	if not ATOM_SCHEMAS.has(kind):
		errors.append("unknown %s atom kind: '%s'" % [scope, kind])
		return errors
	var schema: Dictionary = ATOM_SCHEMAS[kind] as Dictionary
	if (schema["scope"] as String) != scope:
		errors.append("atom '%s' is %s-scope but tagged '%s'" % [kind, schema["scope"], scope])
	for field: String in schema["required"] as Array:
		if not atom.has(field):
			errors.append("atom '%s' missing required field '%s'" % [kind, field])
	return errors


# Validates every atom in an Augment. Empty Array = valid.
static func validate_augment(augment: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for effect: Variant in augment.get("effects", []) as Array:
		errors.append_array(validate_atom(effect as Dictionary))
	return errors


# ── acquisition ────────────────────────────────────────────────────────────────

# Appends an Augment to the run's durable list and re-materializes the run_state cache.
# The single entry point every source (Keystone pick, Event Reward, Trinket draft)
# routes through, so the cache can never drift from the list. Pure — returns a new state.
static func add_augment(state: Dictionary, augment: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	var augments: Array = s["augments"] as Array
	# Deep-copy: KeystoneData.all() hands out shared roster dicts, so the run must own its
	# copy (mirrors the zero-copy-guard convention for ElementData.find).
	augments.append(augment.duplicate(true))
	s["augments"] = augments
	return materialize_run_state(s)


# ── run_state scope ──────────────────────────────────────────────────────────

# Recomputes the discrete run_state cache fields (hp_bonus, hp_bonus_percent,
# reroll_discount) from every run_state atom across all Augments. Idempotent: a full
# recompute from the list, so re-running never double-counts. Pure.
static func materialize_run_state(state: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	var hp_flat: int = 0
	var hp_percent: int = 0
	var reroll_discount: int = 0
	for augment: Variant in s.get("augments", []) as Array:
		for effect: Variant in (augment as Dictionary).get("effects", []) as Array:
			var atom: Dictionary = effect as Dictionary
			if (atom.get("scope", "") as String) != "run_state":
				continue
			var amount: int = atom.get("amount", 0) as int
			match atom.get("kind", "") as String:
				"bonus_hp":
					hp_flat += amount
				"bonus_hp_percent":
					hp_percent += amount
				"reroll_discount":
					reroll_discount += amount
	s["hp_bonus"] = hp_flat
	s["hp_bonus_percent"] = hp_percent
	s["reroll_discount"] = reroll_discount
	return s


# ── shop_gen scope ─────────────────────────────────────────────────────────────

# Accumulated shop-pool bias as { family_id: extra_copies }. ShopSystem duplicates that
# many extra copies of each matching-Family element into the eligible pool before
# spreading — a soft "appears more often" that never unlocks a tier or injects an
# ineligible element. Empty when no Augment shapes the shop. Pure (read-only).
static func shop_weights(state: Dictionary) -> Dictionary:
	var weights: Dictionary = {}
	for augment: Variant in state.get("augments", []) as Array:
		for effect: Variant in (augment as Dictionary).get("effects", []) as Array:
			var atom: Dictionary = effect as Dictionary
			if (atom.get("scope", "") as String) != "shop_gen":
				continue
			if (atom.get("kind", "") as String) != "shop_weight":
				continue
			var family: String = atom["family"] as String
			weights[family] = (weights.get(family, 0) as int) + (atom["copies"] as int)
	return weights


# ── combat scope ───────────────────────────────────────────────────────────────

# Applies the player's combat-scope atoms once, at combat start. Called by
# PhaseSystem.begin_combat AFTER AbilitySystem.resolve_combat_start, so Augment
# modifiers stack on top of the board's combat_start setup. Combat atoms are ability
# atoms applied from a virtual source (no slot → potency 1) on the player side;
# opponents (Ghosts) carry no Augments. Pure — returns a new state.
static func apply_combat_start(state: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	var atoms: Array = []
	for augment: Variant in s.get("augments", []) as Array:
		for effect: Variant in (augment as Dictionary).get("effects", []) as Array:
			var atom: Dictionary = effect as Dictionary
			if (atom.get("scope", "") as String) == "combat":
				atoms.append(_resolve_combat_atom(s, atom))
	if not atoms.is_empty():
		AbilitySystem.apply_external_effects(s, atoms, "player")
	return s


# Resolves an atom's optional `scale_by` into a concrete value. `value` (set_status_field)
# / `amount` (set_side_field) is the per-unit coefficient; this multiplies it by the
# board-derived integer count and drops `scale_by` so what flows downstream is a plain
# combat atom. No scale_by → returned unchanged.
static func _resolve_combat_atom(state: Dictionary, atom: Dictionary) -> Dictionary:
	var scale_by: String = atom.get("scale_by", "") as String
	if scale_by == "":
		return atom
	var multiplier: int = _scale_count(state, scale_by)
	var resolved: Dictionary = atom.duplicate(true)
	if resolved.has("value") and typeof(resolved["value"]) == TYPE_INT:
		resolved["value"] = (resolved["value"] as int) * multiplier
	if resolved.has("amount") and typeof(resolved["amount"]) == TYPE_INT:
		resolved["amount"] = (resolved["amount"] as int) * multiplier
	resolved.erase("scale_by")
	return resolved


# The integer count a scale_by resolves to, read off the player's board (battle_grid).
static func _scale_count(state: Dictionary, scale_by: String) -> int:
	var parts: PackedStringArray = scale_by.split(":")
	var kind: String = parts[0]
	var arg: String = parts[1] if parts.size() > 1 else ""
	match kind:
		"round":
			return maxi(0, state.get("round", 1) as int)
		"board_size":
			return _occupied_count(state)
		"family_count":
			return _family_count(state, arg)
		"family_levels":
			return _family_levels(state, arg)
	return 1


static func _valid_scale_by(scale_by: String) -> bool:
	return SCALE_KINDS.has(scale_by.split(":")[0])


static func _occupied_count(state: Dictionary) -> int:
	var n: int = 0
	for piece: Variant in state.get("battle_grid", []) as Array:
		if piece != null:
			n += 1
	return n


static func _family_count(state: Dictionary, family: String) -> int:
	var n: int = 0
	for piece: Variant in state.get("battle_grid", []) as Array:
		if piece != null and _in_family((piece as Dictionary).get("element_id", "") as String, family):
			n += 1
	return n


static func _family_levels(state: Dictionary, family: String) -> int:
	var total: int = 0
	for piece: Variant in state.get("battle_grid", []) as Array:
		if piece != null and _in_family((piece as Dictionary).get("element_id", "") as String, family):
			total += maxi(1, (piece as Dictionary).get("level", 1) as int)
	return total


# Family membership = the Tier-1 lineage. Recurse `ingredients_of` until base elements
# (no recipe) — those are the Tier-1 roots; the piece is in `family` if it descends from
# that Tier-1. Recipes climb tiers strictly, so the walk always terminates.
static func _in_family(element_id: String, family: String) -> bool:
	if element_id == "":
		return false
	var roots: Dictionary = {}
	var stack: Array[String] = [element_id]
	while not stack.is_empty():
		var current: String = stack.pop_back()
		var ingredients: Array[String] = RecipeData.ingredients_of(current)
		if ingredients.is_empty():
			roots[current] = true
		else:
			for ingredient: String in ingredients:
				stack.append(ingredient)
	return roots.has(family)


# ── round_result scope ─────────────────────────────────────────────────────────

# Applies round_result atoms against a finished round's outcome (the PhaseSystem
# resolve_round() dict). The v1 consumer is gold on a win/loss — a future Trinket; no
# Keystone uses this scope yet, so with no such atom this is a no-op. Pure.
static func apply_round_result(state: Dictionary, outcome: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	var is_win: bool = outcome.get("is_win", false) as bool
	var gold_gain: int = 0
	for augment: Variant in s.get("augments", []) as Array:
		for effect: Variant in (augment as Dictionary).get("effects", []) as Array:
			var atom: Dictionary = effect as Dictionary
			if (atom.get("scope", "") as String) != "round_result":
				continue
			if (atom.get("kind", "") as String) != "bonus_gold_on_result":
				continue
			var result: String = atom["result"] as String
			if result == "any" or (result == "win" and is_win) or (result == "loss" and not is_win):
				gold_gain += atom["amount"] as int
	if gold_gain != 0:
		s["gold"] = (s["gold"] as int) + gold_gain
	return s
