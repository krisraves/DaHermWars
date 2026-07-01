# oil_slick.gd
# Tuff Tiddy phase 3: living baby oil. A lingering floor pool that
# bites every 0.8s while you stand in it, then evaporates.

class_name OilSlick
extends Node2D

@export var lifetime: float = 5.0
@export var width: float = 130.0

var _hitbox: Hitbox


func _ready() -> void:
	add_to_group("oil_slick")
	if get_tree().get_nodes_in_group("oil_slick").size() > 6:
		queue_free()  # balance cap: the floor must stay dodgeable
		return
	var pool := ColorRect.new()
	pool.size = Vector2(width, 14)
	pool.position = Vector2(-width * 0.5, -14)
	pool.color = Color(0.1, 0.08, 0.12, 0.95)
	add_child(pool)
	var sheen := ColorRect.new()
	sheen.size = Vector2(width * 0.5, 4)
	sheen.position = Vector2(-width * 0.25, -12)
	sheen.color = Color(0.5, 0.4, 0.6, 0.6)
	add_child(sheen)

	_hitbox = Hitbox.new()
	_hitbox.collision_layer = 32
	_hitbox.collision_mask = 64
	_hitbox.damage = 6
	_hitbox.knockback_strength = 120.0
	_hitbox.knockback_lift = -160.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, 26)
	shape.position = Vector2(0, -13)
	shape.shape = rect
	_hitbox.add_child(shape)
	add_child(_hitbox)

	var rearm := Timer.new()
	rearm.wait_time = 0.8
	rearm.autostart = true
	rearm.timeout.connect(_hitbox.monitoring_changed_rearm)
	add_child(rearm)

	get_tree().create_timer(lifetime).timeout.connect(queue_free)
