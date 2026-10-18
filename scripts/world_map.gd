extends Node2D

const CELL := 64
const MAP_CELLS := Vector2i(40, 40)
const STAMINA_PER_STEP := 5.0

const MINE_GOLD := 50
const MINE_ORE := 10
const ALTAR_STAMINA := 40.0

@onready var hero: Hero = $Hero
@onready var camera: Camera2D = $Hero/Camera2D
@onready var obstacles: Node2D = $Obstacles
@onready var points: Node2D = $Points
@onready var stamina_bar: ProgressBar = $UI/Top/StaminaBar
@onready var message_label: Label = $UI/Top/MessageLabel
@onready var base_button: Button = $UI/Base_Button  # замени путь на свой

@onready var path_preview: PathPreview = $PathPreview

var _has_preview := false
var _preview_cell := Vector2i.ZERO
var _preview_path := PackedVector2Array()

var grid := AStarGrid2D.new()
var _message_tween: Tween

func _ready() -> void:
	_build_grid()
	hero.position = _cell_to_world(GameState.hero_cell)
	camera.reset_smoothing()  # чтобы камера не «доезжала» от старой позиции
	
	
	for poi: Poi in points.get_children():
		if poi.instance_id == &"":
			push_error("У точки карты нет instance_id: " + str(poi.name))
			continue
			
			poi.set_used(GameState.used_points.has(String(poi.instance_id)))
	
	hero.step_finished.connect(_on_hero_step_finished)
	hero.path_finished.connect(_on_hero_path_finished)
	base_button.pressed.connect(_on_base_button_pressed)
	GameState.stamina_changed.connect(_update_stamina_bar)
	stamina_bar.max_value = GameState.MAX_STAMINA
	_update_stamina_bar()
	message_label.modulate.a = 0.0

func _build_grid() -> void:
	grid.region = Rect2i(Vector2i.ZERO, MAP_CELLS)
	grid.cell_size = Vector2(CELL, CELL)
	grid.offset = Vector2(CELL, CELL) / 2.0
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()

	for obstacle: ColorRect in obstacles.get_children():
		var rect := obstacle.get_global_rect()
		var first := _world_to_cell(rect.position)
		var last := _world_to_cell(rect.end - Vector2.ONE)
		for x in range(first.x, last.x + 1):
			for y in range(first.y, last.y + 1):
				grid.set_point_solid(Vector2i(x, y), true)

#func _unhandled_input(event: InputEvent) -> void:
	#if event is InputEventMouseButton and event.pressed \
			#and event.button_index == MOUSE_BUTTON_LEFT:
		#_move_hero_to(get_global_mouse_position())

#func _move_hero_to(world_pos: Vector2) -> void:
	#var target := _world_to_cell(world_pos)
	#var start := _world_to_cell(hero.position)
	#if not grid.is_in_boundsv(target) or grid.is_point_solid(target):
		#return
	#var path := grid.get_point_path(start, target)
	#if path.is_empty():
		#return
#
	#var affordable := int(GameState.stamina / STAMINA_PER_STEP)
	#if affordable == 0:
		#_show_message("Нет сил. Вернись в замок")
		#return
	#if path.size() - 1 > affordable:
		#path = path.slice(0, affordable + 1)
		#_show_message("Выносливость на исходе")
	#hero.follow_path(path)

func _on_hero_step_finished() -> void:
	GameState.spend_stamina(STAMINA_PER_STEP)
	GameState.hero_cell = _world_to_cell(hero.position)

func _on_hero_path_finished() -> void:
	var cell := _world_to_cell(hero.position)
	GameState.hero_cell = cell
	for poi: Poi in points.get_children():
		if _world_to_cell(poi.position) == cell:
			_interact(poi)
	SaveManager.save_game()

func _interact(poi: Poi) -> void:
	#var id := String(poi.name)
	var id := String(poi.instance_id)
	if GameState.used_points.has(id):
		_show_message("%s: сегодня здесь уже нечего делать" % poi.poi_name)
		return

	match poi.kind:
		"mine":
			GameState.add_resources(MINE_GOLD, 0, MINE_ORE)
			_mark_used(poi)
			_show_message("%s: +%d золота, +%d руды" % [poi.poi_name, MINE_GOLD, MINE_ORE])
		"altar":
			if GameState.stamina >= GameState.MAX_STAMINA:
				_show_message("%s: силы и так полны" % poi.poi_name)
				return
			GameState.add_stamina(ALTAR_STAMINA)
			_mark_used(poi)
			_show_message("%s: +%d выносливости" % [poi.poi_name, int(ALTAR_STAMINA)])
		"camp":
			GameState.battle_poi = id
			SceneManager.change_scene("res://scenes/battle.tscn")

func _mark_used(poi: Poi) -> void:
	#GameState.used_points[String(poi.name)] = true
	GameState.used_points[String(poi.instance_id)] = true
	poi.set_used(true)

func _on_base_button_pressed() -> void:
	hero.stop()
	GameState.end_day()  # новая строка: доход от зданий и новый день
	SceneManager.change_scene("res://scenes/base.tscn")

func _update_stamina_bar() -> void:
	stamina_bar.value = GameState.stamina

func _show_message(text: String) -> void:
	message_label.text = text
	message_label.modulate.a = 1.0
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_interval(2.0)
	_message_tween.tween_property(message_label, "modulate:a", 0.0, 0.5)

func _world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i((pos / CELL).floor())

func _cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL + Vector2(CELL, CELL) / 2.0

func _unhandled_input(event: InputEvent) -> void:
	if hero.is_moving():
		return  # во время движения касания по карте игнорируются
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_on_map_clicked(get_global_mouse_position())

func _on_map_clicked(world_pos: Vector2) -> void:
	var target := _world_to_cell(world_pos)
	if not grid.is_in_boundsv(target) or grid.is_point_solid(target):
		return
	if _has_preview and target == _preview_cell:
		_start_move()
	else:
		_show_preview(target)

func _affordable_steps(path: PackedVector2Array) -> int:
	return mini(path.size() - 1, int(GameState.stamina / STAMINA_PER_STEP))

func _show_preview(target: Vector2i) -> void:
	var start := _world_to_cell(hero.position)
	var path := grid.get_point_path(start, target)
	if path.is_empty():
		_show_message("Туда не пройти")
		return
	_has_preview = true
	_preview_cell = target
	_preview_path = path

	var total := path.size() - 1
	var steps := _affordable_steps(path)
	path_preview.show_path(path, steps)
	if steps < total:
		_show_message("Сил хватит на %d из %d шагов" % [steps, total])
	else:
		_show_message("Шагов: %d. Нажми ещё раз" % total)

func _start_move() -> void:
	var path := _preview_path
	var steps := _affordable_steps(path)
	_clear_preview()
	if path.size() > 1 and steps == 0:
		_show_message("Нет сил. Вернись в замок")
		return
	hero.follow_path(path.slice(0, steps + 1))

func _clear_preview() -> void:
	_has_preview = false
	path_preview.clear()
