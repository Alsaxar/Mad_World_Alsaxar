class_name MapMath
extends RefCounted

const CELL := 64
const MAP_CELLS := Vector2i(1000, 1000)
const DEFAULT_LEVEL_COUNT := 10

static func map_center() -> Vector2:
	return Vector2(MAP_CELLS) / 2.0

static func map_radius() -> float:
	return minf(MAP_CELLS.x, MAP_CELLS.y) / 2.0

# Уровень 1 = внешнее кольцо, level_count = центр. Всё за кругом считается уровнем 1.
static func level_at(cell: Vector2, level_count := DEFAULT_LEVEL_COUNT) -> int:
	var ring_width := map_radius() / level_count
	var ring_from_center := int(floor(cell.distance_to(map_center()) / ring_width))
	return clampi(level_count - ring_from_center, 1, level_count)

# x = внутренний радиус, y = внешний радиус (в клетках)
static func zone_radii(level: int, level_count := DEFAULT_LEVEL_COUNT) -> Vector2:
	var ring_width := map_radius() / level_count
	return Vector2((level_count - level) * ring_width, (level_count - level + 1) * ring_width)

static func zone_area(level: int, level_count := DEFAULT_LEVEL_COUNT) -> float:
	var r := zone_radii(level, level_count)
	return PI * (r.y * r.y - r.x * r.x)

static func random_cell_in_zone(level: int, rng: RandomNumberGenerator,
		level_count := DEFAULT_LEVEL_COUNT) -> Vector2i:
	var r := zone_radii(level, level_count)
	var radius := sqrt(rng.randf_range(r.x * r.x, r.y * r.y))
	var angle := rng.randf_range(0.0, TAU)
	var pos := map_center() + Vector2(cos(angle), sin(angle)) * radius
	return Vector2i(clampi(int(pos.x), 0, MAP_CELLS.x - 1), clampi(int(pos.y), 0, MAP_CELLS.y - 1))

static func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL + Vector2(CELL, CELL) / 2.0

static func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i((pos / CELL).floor())
