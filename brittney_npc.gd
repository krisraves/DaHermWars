# projectile.gd
# Generic projectile. One script, every flavor:
#   gravity=0          -> straight shot (audio blast, soundwave)
#   gravity>0          -> arc (thrown shoe, toxic blob)
#   bouncing=true      -> bounces along the ground (basketball)
# Visuals built from exports so enemies/bosses just configure and fire.

class_name GenericProjectile
extends Area2D

@export var speed: float = 380.0
@export var gravity: float = 0.0
@export var lift: float = 0.0
@export var damage: int = 8
@export var knockback: float = 220.0
@export var box_size: Vector2 = Vector2(22, 22)
@export var color: Color = Color(0.4, 0.8, 1.0)
@export var label_text: String = ""
@export var lifetime: float = 3.5
@export var bouncing: bool = false
@export var max_bounces: int = 5

var _velocity: Vector2 = Vector2.ZERO
var _bounces: int = 0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_world_hit)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = box_size
	shape.shape = rect
	add_child(shape)

	var visual := ColorRect.new()
	visual.size = box_size
	visual.position = -box_size * 0.5
	visual.color = color
	add_child(visual)

	if label_text != "":
		var label := Label.new()
		label.text = label_text
		label.position = Vector2(-box_size.x * 0.5, -box_size.y * 0.5 - 24.0)
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", color.lightened(0.4))
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 3)
		add_child(label)

	var hitbox := Hitbox.new()
	hitbox.collision_layer = 32
	hitbox.collision_mask = 64
	hitbox.damage = damage
	hitbox.knockback_strength = knockback
	hitbox.knockback_lift = -140.0
	var hshape := CollisionShape2D.new()
	var hrect := RectangleShape2D.new()
	hrect.size = box_size
	hshape.shape = hrect
	hitbox.add_child(hshape)
	add_child(hitbox)
	hitbox.hit_landed.connect(func(_h): queue_free())


func launch(direction: int) -> void:
	_velocity = Vector2(speed * direction, lift)


func launch_vector(vel: Vector2) -> void:
	_velocity = vel


func _physics_process(delta: float) -> void:
	_velocity.y += gravity * delta
	global_position += _velocity * delta
	if gravity > 0.0 and not bouncing:
		rotation += 8.0 * delta * signf(_velocity.x)


func _on_world_hit(_body: Node2D) -> void:
	if bouncing and _velocity.y > 60.0 and _bounces < max_bounces:
		_bounces += 1
		_velocity.y = -absf(_velocity.y) * 0.92
		global_position.y -= 4.0  # unstick from the floor
		return
	queue_free()
