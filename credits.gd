# health.gd
# Reusable health component. Player, enemies, bosses, and (eventually)
# breakable props all use this same node. Per TECHNICAL_ARCHITECTURE:
# build reusable systems, never one-off logic.

class_name Health
extends Node

signal damaged(amount: int, current: int)
signal healed(amount: int, current: int)
signal died

@export var max_health: int = 100

var current: int

var is_dead: bool:
	get:
		return current <= 0


func _ready() -> void:
	current = max_health


func take_damage(amount: int) -> void:
	if is_dead:
		return
	current = maxi(0, current - amount)
	damaged.emit(amount, current)
	if current == 0:
		died.emit()


func heal(amount: int) -> void:
	if is_dead:
		return
	current = mini(max_health, current + amount)
	healed.emit(amount, current)


func heal_full() -> void:
	current = max_health
	healed.emit(max_health, current)
