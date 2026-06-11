extends GutTest


# ── dimensions ────────────────────────────────────────────────────────────────

func test_dimensions_four_slots_is_2x2() -> void:
	assert_eq(GridSystem.dimensions(4), Vector2i(2, 2))


func test_dimensions_five_slots_is_3x2_ragged() -> void:
	assert_eq(GridSystem.dimensions(5), Vector2i(3, 2))


func test_dimensions_six_slots_is_3x2() -> void:
	assert_eq(GridSystem.dimensions(6), Vector2i(3, 2))


func test_dimensions_seven_slots_is_4x2_ragged() -> void:
	assert_eq(GridSystem.dimensions(7), Vector2i(4, 2))


func test_dimensions_eight_slots_is_4x2() -> void:
	assert_eq(GridSystem.dimensions(8), Vector2i(4, 2))


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


# ── neighbors — ragged-board guard (slot_count < width*height) ────────────────

func test_neighbors_ragged_5_drops_out_of_range_right() -> void:
	# 5-slot board laid out 3×2 (indices 0,1,2 / 3,4). Slot 4's geometric right is
	# index 5, which does not exist — the slot_count guard must drop it.
	assert_eq(GridSystem.neighbors(4, 3, 2, 5), [1, 3])


func test_neighbors_ragged_7_drops_out_of_range_neighbor() -> void:
	# 7-slot board laid out 4×2 (0,1,2,3 / 4,5,6). Slot 6's geometric right is 7
	# (gone); down is out anyway. Up 2, left 5 remain.
	assert_eq(GridSystem.neighbors(6, 4, 2, 7), [2, 5])


func test_neighbors_full_board_unaffected_by_default_guard() -> void:
	# When slot_count is omitted the guard is width*height (no-op) — back-compat.
	assert_eq(GridSystem.neighbors(4, 3, 2), [1, 3, 5])
