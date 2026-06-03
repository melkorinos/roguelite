extends GutTest


# ── dimensions ────────────────────────────────────────────────────────────────

func test_dimensions_four_slots_is_2x2() -> void:
	assert_eq(GridSystem.dimensions(4), Vector2i(2, 2))


func test_dimensions_six_slots_is_3x2() -> void:
	assert_eq(GridSystem.dimensions(6), Vector2i(3, 2))


func test_dimensions_nine_slots_is_3x3() -> void:
	assert_eq(GridSystem.dimensions(9), Vector2i(3, 3))


# ── neighbors — orthogonal only ───────────────────────────────────────────────

func test_neighbors_2x2_top_left_has_right_and_down() -> void:
	assert_eq(GridSystem.neighbors(0, 2, 2), [1, 2])


func test_neighbors_2x2_bottom_right_has_up_and_left() -> void:
	assert_eq(GridSystem.neighbors(3, 2, 2), [1, 2])


func test_neighbors_3x3_center_has_four() -> void:
	assert_eq(GridSystem.neighbors(4, 3, 3), [1, 3, 5, 7])


func test_neighbors_3x3_corner_has_two() -> void:
	assert_eq(GridSystem.neighbors(0, 3, 3), [1, 3])


func test_neighbors_3x3_edge_has_three() -> void:
	assert_eq(GridSystem.neighbors(1, 3, 3), [0, 2, 4])


func test_neighbors_no_diagonals_in_3x3() -> void:
	# slot 0's diagonal is slot 4 — must NOT be a neighbor
	assert_false(GridSystem.neighbors(0, 3, 3).has(4))


func test_neighbors_3x2_middle_bottom_has_three() -> void:
	# width 3, height 2; slot 4 = row 1 col 1 → up 1, left 3, right 5
	assert_eq(GridSystem.neighbors(4, 3, 2), [1, 3, 5])
