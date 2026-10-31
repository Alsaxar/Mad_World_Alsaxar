class_name PoiSpawner
extends Node

const POI_SCENE := preload("res://scenes/poi.tscn")
const STATUS_UPDATE_RADIUS := 3000.0  # подписи обновляем только у ближних точек

const KINDS := {
	"mine": {"name": "Шахта", "color": Color(0.36, 0.4, 0.47)},
	"altar": {"name": "Алтарь света", "color": Color(1.0, 0.92, 0.6)},
	"camp": {"name": "Лагерь разбойников", "color": Color(1.0, 0.41, 0.0)},
}

@export_group("Зоны")
@export var level_count := MapMath.DEFAULT_LEVEL_COUNT

@export_group("Плотность (штук на 10 000 клеток площади зоны)")
@export var camp_density := 8.0
@export var altar_density := 2.0
@export var mine_density := 1.0
@export var min_per_level := 1

@export_group("Таймер и поведение")
@export var respawn_seconds := 300  # тестовое значение: 5 минут
@export var mines_relocate := false
@export var altars_relocate := true
@export var camps_relocate := true

@export_group("Служебное")
@export var regenerate_now := false:
	set(value):
		regenerate_now = false  # кнопка-«галочка»: сама возвращается в false
		if value and is_inside_tree():
			regenerate_world()

@onready var points: Node2D = get_node("../Points")

var _nodes := {}  # id точки -> узел Poi

func _ready() -> void:
	if GameState.map_pois.is_empty():
		_generate_all()
	_process_expired()  # догоняем таймеры, пока игрок был на базе
	_spawn_nodes()
	GameState.second_tick.connect(_on_second_tick)

# ─── Генерация ───
func _density_of(kind: String) -> float:
	match kind:
		"camp":
			return camp_density
		"altar":
			return altar_density
		"mine":
			return mine_density
	return 0.0

func _relocates(kind: String) -> bool:
	match kind:
		"camp":
			return camps_relocate
		"altar":
			return altars_relocate
		"mine":
			return mines_relocate
	return false

func _count_for(level: int, kind: String) -> int:
	var expected := MapMath.zone_area(level, level_count) / 10000.0 * _density_of(kind)
	return maxi(min_per_level, roundi(expected))

func _generate_all() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var now := GameState.unix_now()
	var counter := 0
	for level in range(1, level_count + 1):
		for kind: String in KINDS:
			for i in _count_for(level, kind):
				counter += 1
				GameState.map_pois["poi_%s_%04d" % [kind, counter]] = {
					"kind": kind,
					"level": level,
					"cell": _cell_array(MapMath.random_cell_in_zone(level, rng, level_count)),
					# таймеры размазаны, чтобы точки не обновлялись все разом
					"respawn_at": now + rng.randi_range(1, maxi(respawn_seconds, 2)),
				}

func regenerate_world() -> void:
	for child in points.get_children():
		child.queue_free()
	_nodes.clear()
	GameState.map_pois.clear()
	GameState.used_points.clear()
	_generate_all()
	_spawn_nodes()

# ─── Узлы на карте ───
func _spawn_nodes() -> void:
	for id in GameState.map_pois:
		_create_node(str(id))

func _create_node(id: String) -> void:
	var rec: Dictionary = GameState.map_pois[id]
	var kind := str(rec["kind"])
	var poi: Poi = POI_SCENE.instantiate()
	poi.instance_id = StringName(id)
	poi.kind = kind
	poi.level = int(rec["level"])
	poi.poi_name = str(KINDS[kind]["name"])
	poi.color = KINDS[kind]["color"]
	poi.position = MapMath.cell_to_world(_cell_of(rec))
	points.add_child(poi)  # _ready точки вызывается здесь
	_nodes[id] = poi
	_update_status(id, poi, GameState.unix_now())

# ─── Таймеры ───
func _on_second_tick() -> void:
	var now := GameState.unix_now()
	_process_expired(now)
	var cam := get_viewport().get_camera_2d()
	var center := cam.get_screen_center_position() if cam else Vector2.ZERO
	for id in _nodes:
		var poi: Poi = _nodes[id]
		if poi.position.distance_to(center) <= STATUS_UPDATE_RADIUS:
			_update_status(str(id), poi, now)

func _process_expired(now: int = -1) -> void:
	if now < 0:
		now = GameState.unix_now()
	var expired: Array = []
	for id in GameState.map_pois:
		if now >= int(GameState.map_pois[id]["respawn_at"]):
			expired.append(str(id))
	if expired.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for id in expired:
		_respawn(id, now, rng)

func _respawn(id: String, now: int, rng: RandomNumberGenerator) -> void:
	var rec: Dictionary = GameState.map_pois[id]
	if _relocates(str(rec["kind"])):
		rec["cell"] = _cell_array(MapMath.random_cell_in_zone(int(rec["level"]), rng, level_count))
	rec["respawn_at"] = now + respawn_seconds
	GameState.used_points.erase(id)  # точка снова «свежая»
	var poi: Poi = _nodes.get(id)
	if poi:
		poi.position = MapMath.cell_to_world(_cell_of(rec))
		poi.set_used(false)

func _update_status(id: String, poi: Poi, now: int) -> void:
	var rec: Dictionary = GameState.map_pois[id]
	poi.set_status(maxi(int(rec["respawn_at"]) - now, 0), _relocates(str(rec["kind"])))

# ─── Мелочи ───
func _cell_array(cell: Vector2i) -> Array:
	return [cell.x, cell.y]

func _cell_of(rec: Dictionary) -> Vector2i:
	var a: Array = rec["cell"]
	return Vector2i(int(a[0]), int(a[1]))
