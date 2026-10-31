class_name Poi
extends Node2D

@export var instance_id: StringName = &""
@export var poi_name := "Точка"
@export var color := Color.GOLD
@export_enum("mine", "altar", "camp") var kind: String = "mine"
@export var level := 1

@onready var body: ColorRect = $Body
@onready var name_label: Label = $NameLabel
@onready var status_label: Label = $StatusLabel

# Вызывается Godot при добавлении узла в сцену. Получает ссылки на узлы и подключает сигналы; подготовленные данные используются обработчиками и интерфейсом.
func _ready() -> void:
	body.color = color
	#name_label.text = poi_name
	name_label.text = "%s\nур. %d" % [poi_name, level]
	if instance_id == &"":
		push_warning("У объекта карты не назначен instance_id: " + str(name))

# Устанавливает признак использования точки интереса, влияющий на отображение и дальнейшее взаимодействие.
func set_used(used: bool) -> void:
	modulate.a = 0.4 if used else 1.0

# Показывает таймер обновления и что случится с точкой: останется на месте или переедет
func set_status(seconds_left: int, relocates: bool) -> void:
	var prefix := "Новое место" if relocates else "На месте"
	status_label.text = "%s · %s" % [prefix, BuildingDB.format_time(seconds_left)]
	status_label.modulate = Color(1.0, 0.6, 0.2) if relocates else Color(0.5, 1.0, 0.5)
