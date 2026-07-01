# tentacle_strike.gd
# Pod Father mic-tentacle: a warning column rises from the floor at
# the target position, then the cable strikes. Telegraph -> punish.

class_name TentacleStrike
extends Node2D

@export var warn_time: float = 0.6
@export var active_time: float = 0.25
@export var column_height: float = 380.0

var _warn: ColorRect
var _column: ColorRect
var _hitbox: Hitbox


func _ready() -> void:
	_warn = ColorRect.new()
	_warn.size = Vector2(46, column_height)
	_warn.position = Vector2(-23, -column_height)
	_warn.color = Color(1, 0.2, 0.2, 0.22)
	add_child(_warn)

	_column = ColorRect.new()
	_column.size = Vector2(34, column_height)
	_column.position = Vector2(-17, -column_height)
	_column.color = Color(0.12, 0.12, 0.16)
	_column.visible = false
	add_child(_column)

	_hitbox = Hitbox.new()
	_hitbox.collision_layer = 32
	_hitbox.collision_mask = 64
	_hitbox.damage = 11
	_hitbox.knockback_strength = 300.0
	_hitbox.knockback_lift = -240.0
	_hitbox.monitoring = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(34, column_height)
	shape.position = Vector2(0, -column_height * 0.5)
	shape.shape = rect
	shape.disabled = true
	_hitbox.add_child(shape)
	add_child(_hitbox)

	_run()


func _run() -> void:
	var tween := create_tween()
	tween.tween_interval(warn_time)
	tween.tween_callback(_strike)
	tween.tween_interval(active_time)
	tween.tween_callback(queue_free)


func _strike() -> void:
	_warn.visible = false
	_column.visible = true
	_hitbox.set_deferred("monitoring", true)
	_hitbox.get_child(0).set_deferred("disabled", false)
	Juice.shake(4.0)
