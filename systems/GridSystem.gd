class_name GridSystem

# Grid-size-agnostic layout helpers. Slots are indexed row-major (index = row *
# width + column). The combat backend derives the grid shape from the slot count
# so the same code supports 2×2, 3×2, and 3×3 boards without hardcoding.


# Maps a slot count to a (width, height) board shape. Width is columns, height is
# rows. Falls back to a near-square layout for unlisted counts.
static func dimensions(slot_count: int) -> Vector2i:
	match slot_count:
		4: return Vector2i(2, 2)
		6: return Vector2i(3, 2)
		9: return Vector2i(3, 3)
	var width: int = int(ceil(sqrt(float(slot_count))))
	@warning_ignore("integer_division")
	var height: int = int(ceil(float(slot_count) / float(width)))
	return Vector2i(width, height)


# Orthogonal neighbors (up, left, right, down) of a slot, in ascending index
# order. No diagonals. Out-of-bounds directions are omitted.
static func neighbors(slot_index: int, width: int, height: int) -> Array[int]:
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
	return result
