class_name Poi
extends Node2D

@export var instance_id: StringName = &""
@export var poi_name := "Точка"
@export var color := Color.GOLD
@export_enum("mine", "altar", "camp") var kind: String = "mine"

@onready var body: ColorRect = $Body
@onready var name_label: Label = $NameLabel

func _ready() -> void:
	body.color = color
	name_label.text = poi_name
	
	if instance_id == &"":
		push_warning("У объекта карты не назначен instance_id: " + str(name))

func set_used(used: bool) -> void:
	modulate.a = 0.4 if used else 1.0
