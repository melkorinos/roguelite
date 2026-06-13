extends GutTest

# Locks the Keystone roster (ADR 0016): every card is a valid Augment, ids are unique,
# axis_kind is recognized, and the roster can satisfy the Starting-Pick variety guarantee.


func test_every_keystone_atom_is_valid() -> void:
	for keystone: Dictionary in KeystoneData.all():
		var errors: Array[String] = AugmentSystem.validate_augment(keystone)
		assert_eq(errors.size(), 0, "%s: %s" % [keystone["id"], ", ".join(errors)])


func test_keystones_are_source_type_keystone() -> void:
	for keystone: Dictionary in KeystoneData.all():
		assert_eq(keystone["source_type"] as String, "keystone")


func test_keystone_ids_are_unique() -> void:
	var seen: Dictionary = {}
	for keystone: Dictionary in KeystoneData.all():
		var id: String = keystone["id"] as String
		assert_false(seen.has(id), "duplicate id: " + id)
		seen[id] = true


func test_keystone_axis_kinds_are_recognized() -> void:
	for keystone: Dictionary in KeystoneData.all():
		assert_true((keystone["axis_kind"] as String) in ["family", "status", "neutral"],
			"%s has unknown axis_kind %s" % [keystone["id"], keystone["axis_kind"]])


func test_keystone_cards_carry_presentation_fields() -> void:
	for keystone: Dictionary in KeystoneData.all():
		assert_true(keystone.has("name"), "%s missing name" % keystone["id"])
		assert_true(keystone.has("description"), "%s missing description" % keystone["id"])
		assert_true(keystone.has("tags"), "%s missing tags" % keystone["id"])


func test_roster_has_both_family_and_status_cards() -> void:
	var kinds: Dictionary = {}
	for keystone: Dictionary in KeystoneData.all():
		kinds[keystone["axis_kind"] as String] = true
	assert_true(kinds.has("family"))
	assert_true(kinds.has("status"))


func test_find_returns_keystone_by_id() -> void:
	assert_eq(KeystoneData.find("plague_pact")["name"] as String, "Plague Pact")


func test_find_unknown_returns_empty() -> void:
	assert_true(KeystoneData.find("nope").is_empty())
