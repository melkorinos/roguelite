class_name GridSystem

# Grid-size-agnostic layout helpers. Slots are indexed row-major (index = row *
# width + column). The combat backend derives the grid shape from the slot count
# so the same code supports 2×2, 3×2, and 3×3 boards without hardcoding.


# Maps a slot count to a (width, height) board shape. Width is columns, height is
# rows. The Grid Growth ladder (ADR 0014) stays two rows tall up to the hard cap
# of 8 — 5/7 are ragged (the last row is short). Falls back to a near-square
# layout for any unlisted count.
static func dimensions(slot_count: int) -> Vector2i:
	match slot_count:
		4: return Vector2i(2, 2)
		5: return Vector2i(3, 2)
		6: return Vector2i(3, 2)
		7: return Vector2i(4, 2)
		8: return Vector2i(4, 2)
	var width: int = int(ceil(sqrt(float(slot_count))))
	@warning_ignore("integer_division")
	var height: int = int(ceil(float(slot_count) / float(width)))
	return Vector2i(width, height)


# Orthogonal neighbors (up, left, right, down) of a slot, in ascending index
# order. No diagonals. Out-of-bounds directions are omitted. `slot_count` guards
# ragged boards (e.g. 5 slots in a 3×2 layout): any neighbor index >= slot_count
# is a hole in the short last row and is dropped. Defaults to width*height (the
# full rectangle), so passing it is only needed for ragged boards.
static func neighbors(slot_index: int, width: int, height: int, slot_count: int = -1) -> Array[int]:
	var limit: int = slot_count if slot_count >= 0 else width * height
	@warning_ignore("integer_division")
	var row: int = slot_index / width
	var column: int = slot_index % width
	var result: Array[int] = []
	if row > 0:
		result.append(slot_index - width)
	if column > 0:
		result.append(slot_index - 1)
	if column < width - 1:
		result.append(slot_index + 1)
	if row < height - 1:
		result.append(slot_index + width)
	var guarded: Array[int] = []
	for n: int in result:
		if n < limit:
			guarded.append(n)
	return guarded
