# shockwave.gd
# Ground shockwave from the Tragic Clown slam. Travels along the
# floor; the counter-play is jumping - which the player has owned
# since minute one.

class_name Shockwave
extends Area2D

var direction: int = 1
@export var speed: float = 420.0
@export var lifetime: float = 1.3


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

	var flame := ColorRect.new()
	flame.size = Vector2(36, 42)
	flame.position = Vector2(-18, -42)
	flame.color = Color(1.0, 0.45, 0.1, 0.9)
	add_child(flame)

	var hitbox := Hitbox.new()
	hitbox.collision_layer = 32
	hitbox.collision_mask = 64
	hitbox.damage = 10
	hitbox.knockback_strength = 260.0
	hitbox.knockback_lift = -200.0
	var hshape := CollisionShape2D.new()
	var hrect := RectangleShape2D.new()
	hrect.size = Vector2(36, 42)
	hshape.position = Vector2(0, -21)
	hshape.shape = hrect
	hitbox.add_child(hshape)
	add_child(hitbox)


func _physics_process(delta: float) -> void:
	global_position.x += speed * direction * delta
