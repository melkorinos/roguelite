extends GutTest


func test_known_keyword_has_definition() -> void:
	assert_ne(StatusGlossary.get_definition("shock"), "")


func test_lookup_is_case_insensitive() -> void:
	assert_eq(StatusGlossary.get_definition("Shock"), StatusGlossary.get_definition("shock"))


func test_unknown_keyword_returns_empty() -> void:
	assert_eq(StatusGlossary.get_definition("nonsense"), "")


func test_has_keyword() -> void:
	assert_true(StatusGlossary.has_keyword("curse"))
	assert_false(StatusGlossary.has_keyword("nonsense"))


func test_every_keyword_has_a_nonempty_definition() -> void:
	for keyword: Variant in StatusGlossary.keywords():
		assert_ne(StatusGlossary.get_definition(keyword as String), "", "empty def for " + (keyword as String))


func test_covers_core_statuses() -> void:
	for keyword: String in ["burn", "poison", "shock", "weaken", "armor", "plating", "blind", "curse", "leech", "freeze", "multicast"]:
		assert_true(StatusGlossary.has_keyword(keyword), "glossary missing: " + keyword)
