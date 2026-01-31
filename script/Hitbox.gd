class_name Hitbox
extends Area2D

@export var damage: float = 5

signal hit(hurtbox: Hurtbox)

func _init() -> void:
	area_entered.connect(_on_area_enterd)

func _on_area_enterd(hurtbox: Hurtbox) -> void:
	print("[HIT] %s => %s" % [owner.name, hurtbox.owner.name])
	hit.emit(hurtbox)
	hurtbox.hurt.emit(self)
