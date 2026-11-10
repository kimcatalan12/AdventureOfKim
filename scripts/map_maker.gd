class_name MapMaker
extends RefCounted
## Builds a new random map each time a stage starts.
## Tiles: "#" wall, "t" and "c" props, "P" Kim's start, "." floor.

const WIDTH := 30
const HEIGHT := 18
const WALL_PIECES := Vector2i(9, 13)
const PROPS := Vector2i(7, 10)
const START_CLEAR := 2
const MIN_OPEN := 330
const STEPS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]


static func make(rng: RandomNumberGenerator) -> PackedStringArray:
	while true:
		var grid := _empty()
		var start := _pick_start(rng)
		_scatter(grid, start, rng.randi_range(WALL_PIECES.x, WALL_PIECES.y), _wall_piece.bind(rng), func() -> String: return "#")
		_scatter(grid, start, rng.randi_range(PROPS.x, PROPS.y), _prop_piece.bind(rng), func() -> String: return "t" if rng.randf() < 0.5 else "c")
		if _open_count(grid) >= MIN_OPEN:
			grid[start.y][start.x] = "P"
			return _to_rows(grid)
	return PackedStringArray()


static func _empty() -> Array:
	var grid := []
	for y in HEIGHT:
		var row := []
		for x in WIDTH:
			var edge := x == 0 or y == 0 or x == WIDTH - 1 or y == HEIGHT - 1
			row.append("#" if edge else ".")
		grid.append(row)
	return grid


## Kim starts near one of the four corners.
static func _pick_start(rng: RandomNumberGenerator) -> Vector2i:
	var x := 2 if rng.randf() < 0.5 else WIDTH - 3
	var y := 2 if rng.randf() < 0.5 else HEIGHT - 3
	return Vector2i(x, y)


## Places up to `count` pieces. A piece is skipped when it would touch
## another piece, crowd the start, or cut off part of the map.
static func _scatter(grid: Array, start: Vector2i, count: int, make_piece: Callable, tile: Callable) -> void:
	var placed := 0
	var tries := 0
	while placed < count and tries < 300:
		tries += 1
		var cells: Array[Vector2i] = make_piece.call()
		if not _fits(grid, cells, start):
			continue
		var kind: String = tile.call()
		for cell in cells:
			grid[cell.y][cell.x] = kind
		if _all_connected(grid, start):
			placed += 1
		else:
			for cell in cells:
				grid[cell.y][cell.x] = "."


static func _wall_piece(rng: RandomNumberGenerator) -> Array[Vector2i]:
	var origin := Vector2i(rng.randi_range(1, WIDTH - 2), rng.randi_range(1, HEIGHT - 2))
	var cells: Array[Vector2i] = []
	match rng.randi_range(0, 3):
		0:  # straight, across
			for i in rng.randi_range(3, 7):
				cells.append(origin + Vector2i(i, 0))
		1:  # straight, down
			for i in rng.randi_range(3, 5):
				cells.append(origin + Vector2i(0, i))
		2:  # L shape
			var flip := -1 if rng.randf() < 0.5 else 1
			for i in rng.randi_range(3, 5):
				cells.append(origin + Vector2i(i, 0))
			for i in range(1, rng.randi_range(3, 4)):
				cells.append(origin + Vector2i(0, i * flip))
		_:  # block
			for i in 4:
				cells.append(origin + Vector2i(i % 2, i / 2))
	return cells


static func _prop_piece(rng: RandomNumberGenerator) -> Array[Vector2i]:
	var cells: Array[Vector2i] = [Vector2i(rng.randi_range(2, WIDTH - 3), rng.randi_range(2, HEIGHT - 3))]
	return cells


static func _fits(grid: Array, cells: Array[Vector2i], start: Vector2i) -> bool:
	for cell in cells:
		if cell.x < 1 or cell.y < 1 or cell.x > WIDTH - 2 or cell.y > HEIGHT - 2:
			return false
		if absi(cell.x - start.x) <= START_CLEAR and absi(cell.y - start.y) <= START_CLEAR:
			return false
		# Keep a gap of at least one tile from every other piece.
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var near := cell + Vector2i(dx, dy)
				if near in cells or _is_edge(near):
					continue
				if grid[near.y][near.x] != ".":
					return false
	return true


static func _is_edge(cell: Vector2i) -> bool:
	return cell.x <= 0 or cell.y <= 0 or cell.x >= WIDTH - 1 or cell.y >= HEIGHT - 1


static func _all_connected(grid: Array, start: Vector2i) -> bool:
	return _reachable(grid, start) == _open_count(grid)


static func _reachable(grid: Array, start: Vector2i) -> int:
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for step in STEPS:
			var next := cell + step
			if seen.has(next) or _is_edge(next) or grid[next.y][next.x] != ".":
				continue
			seen[next] = true
			queue.append(next)
	return seen.size()


static func _open_count(grid: Array) -> int:
	var count := 0
	for row: Array in grid:
		count += row.count(".") + row.count("P")
	return count


static func _to_rows(grid: Array) -> PackedStringArray:
	var rows := PackedStringArray()
	for row: Array in grid:
		rows.append("".join(row))
	return rows
