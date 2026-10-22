extends Control

const PLAYER_UNIT_HP := 10
const PLAYER_UNIT_DAMAGE := 3
const ENEMY_COUNT := 12
const ENEMY_UNIT_HP := 8
const ENEMY_UNIT_DAMAGE := 2
const REWARD_GOLD := 100

@onready var enemy_label: Label = $Margin/Layout/EnemyLabel
@onready var enemy_bar: ProgressBar = $Margin/Layout/EnemyBar
@onready var log_label: Label = $Margin/Layout/LogLabel
@onready var player_label: Label = $Margin/Layout/PlayerLabel
@onready var player_bar: ProgressBar = $Margin/Layout/PlayerBar
@onready var action_button: Button = $Margin/Layout/ActionButton

var player_hp := 0  # общее здоровье отряда игрока
var enemy_hp := 0   # общее здоровье отряда разбойников
var player_start := 0
var finished := false
var won := false

# Вызывается Godot при добавлении узла в сцену. Получает ссылки на узлы и подключает сигналы; подготовленные данные используются обработчиками и интерфейсом.
func _ready() -> void:
	player_start = GameState.army
	player_hp = player_start * PLAYER_UNIT_HP
	enemy_hp = ENEMY_COUNT * ENEMY_UNIT_HP
	player_bar.max_value = player_hp
	enemy_bar.max_value = enemy_hp
	action_button.pressed.connect(_on_action_pressed)
	log_label.text = "Разбойники преграждают путь!"
	_update_ui()

# Рассчитывает число юнитов по общему и индивидуальному здоровью. Значение используется в расчётах и отображении боя.
func _count(total_hp: int, unit_hp: int) -> int:
	# сколько бойцов ещё живо при таком общем здоровье
	return ceili(float(total_hp) / unit_hp)

# Вызывает обработчик выбранного действия. Изменённое состояние отображается при обновлении слота.
func _on_action_pressed() -> void:
	if finished:
		_leave()
	else:
		_play_round()

# Рассчитывает раунд по текущим отрядам и характеристикам. Изменённые здоровье и численность используются интерфейсом и проверкой победы.
func _play_round() -> void:
	var damage := _count(player_hp, PLAYER_UNIT_HP) * PLAYER_UNIT_DAMAGE
	enemy_hp = maxi(enemy_hp - damage, 0)
	var text := "Твой отряд наносит %d урона." % damage

	if enemy_hp > 0:
		var counter := _count(enemy_hp, ENEMY_UNIT_HP) * ENEMY_UNIT_DAMAGE
		player_hp = maxi(player_hp - counter, 0)
		text += "\nРазбойники отвечают: %d урона." % counter

	log_label.text = text
	_update_ui()

	if enemy_hp == 0:
		_finish(true)
	elif player_hp == 0:
		_finish(false)

# Берёт текущее состояние боя и выводит здоровье, численность и доступные действия в интерфейс.
func _update_ui() -> void:
	enemy_label.text = "Разбойники: %d" % _count(enemy_hp, ENEMY_UNIT_HP)
	player_label.text = "Твой отряд: %d" % _count(player_hp, PLAYER_UNIT_HP)
	enemy_bar.value = enemy_hp
	player_bar.value = player_hp

#func _finish(victory: bool) -> void:
	#finished = true
	#won = victory
	#action_button.text = "Продолжить"
	#if victory:
		#GameState.army = _count(player_hp, PLAYER_UNIT_HP)
		#GameState.used_points[GameState.battle_poi] = true
		#GameState.add_resources(REWARD_GOLD)
		#log_label.text += "\n\nПобеда! Добыча: %d золота." % REWARD_GOLD
	#else:
		#GameState.army = maxi(roundi(player_start / 2.0), 1)
		#log_label.text += "\n\nПоражение. Отряд отступает в замок, половина бойцов потеряна."

# Завершает бой с учётом результата. Обновлённое состояние используется для показа итога.
func _finish(victory: bool) -> void:
	finished = true
	won = victory
	action_button.text = "Продолжить"
	if victory:
		GameState.army = _count(player_hp, PLAYER_UNIT_HP)
		GameState.used_points[GameState.battle_poi] = true
		GameState.add_resources(REWARD_GOLD)
		log_label.text += "\n\nПобеда! Добыча: %d золота." % REWARD_GOLD
	else:
		GameState.army = maxi(roundi(player_start / 2.0), 1)
		log_label.text += "\n\nПоражение. Отряд отступает в замок."

	var hurt := GameState.register_casualties(player_start - GameState.army)
	if hurt > 0:
		log_label.text += "\nРаненых отправлено в лазарет: %d." % hurt

# Обрабатывает выход из боя и передаёт SceneManager путь следующей сцены.
func _leave() -> void:
	if won:
		SceneManager.change_scene("res://scenes/world_map.tscn")
	else:
		GameState.end_day()  # новая строка: отступление тоже возвращает домой
		SceneManager.change_scene("res://scenes/base.tscn")
