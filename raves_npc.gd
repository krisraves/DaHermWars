# notebook_projectile.gd
# The Open Mic Comic's notebook. Five years of material, weaponized.
# Arcs through the air, spins, despawns on world contact or timeout.

extends Area2D

@export var throw_speed: float = 380.0
@export var throw_lift: float = -220.0
@export var gravity: float = 1400.0
@export var lifetime: float = 2.5
@export var spin_speed: float = 12.0

var _velocity: Vector2 = Vector2.ZERO
var _hitbox: Hitbox


func _ready() -> void:
	_hitbox = $Hitbox
	body_entered.connect(_on_body_entered)
	_hitbox.hit_landed.connect(func(_h): queue_free())
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func launch(direction: int) -> void:
	_velocity = Vector2(throw_speed * direction, throw_lift)


func _physics_process(delta: float) -> void:
	_velocity.y += gravity * delta
	global_position += _velocity * delta
	rotation += spin_speed * delta * signf(_velocity.x)


func _on_body_entered(_body: Node2D) -> void:
	# hit the world geometry
	queue_free()
