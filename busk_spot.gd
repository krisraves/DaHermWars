# enemy_base.gd
# Base class for all enemies. Per CLAUDE_BUILD_EXECUTION_PROMPT:
# every enemy inherits from EnemyBase. Handles the universal stuff -
# gravity, taking hits, hit stun, knockback, flashing, death.
# Children implement _ai(delta) for behavior and personality.
#
# Per 06_ENEMY_BIBLE: enemies are exaggerated cultural ideas,
# never generic monsters. The base class is generic so the
# children don't have to be.

class_name EnemyBase
extends CharacterBody2D

signal died(enemy: EnemyBase)

@export var gravity: float = 2400.0
@export var max_fall_speed: float = 1100.0
@export var hurt_stun_time: float = 0.22
@export var ground_friction: float = 1600.0
@export var invulnerable: bool = false   # training dummies etc.

var facing: int = -1
var _hurt_timer: float = 0.0
var _is_dead: bool = false

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var visual: Node2D = $Visual


func _ready() -> void:
	hurtbox.hit_received.connect(_on_hit_received)
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	# gravity
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)

	if _hurt_timer > 0.0:
		# hit stun: no AI, knockback bleeds off through friction
		_hurt_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
	else:
		_ai(delta)

	move_and_slide()
	visual.scale.x = float(facing)


# ------------------------------------------------------------ overridables

func _ai(_delta: float) -> void:
	pass  # children implement behavior


func _on_death() -> void:
	pass  # children can add death personality


# ------------------------------------------------------------ hit handling

func _on_hit_received(hitbox: Hitbox) -> void:
	if _is_dead:
		return
	if not invulnerable:
		health.take_damage(hitbox.damage)
	velocity = hitbox.knockback_from(hitbox.global_position, global_position)
	_hurt_timer = hurt_stun_time
	_flash()
	Juice.hitstop(0.04)
	Juice.shake(3.0)


func _flash() -> void:
	visual.modulate = Color(8.0, 8.0, 8.0)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, 0.15)


const FollowerOrbScript := preload("res://scripts/items/follower_orb.gd")

@export var follower_drop: int = 12


func _on_died() -> void:
	_is_dead = true
	died.emit(self)
	_drop_followers()
	_on_death()
	hurtbox.set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 1)  # still lands on the floor while flopping
	Juice.shake(5.0)
	# Death flop: tip over, fade out, leave.
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual, "rotation_degrees", 90.0 * facing, 0.35)
	tween.tween_property(visual, "modulate:a", 0.0, 0.7)
	tween.chain().tween_callback(queue_free)


func _drop_followers() -> void:
	if follower_drop <= 0:
		return
	var per_orb := maxi(1, follower_drop / 3)
	for i in 3:
		var orb: FollowerOrb = FollowerOrbScript.new()
		orb.value = per_orb
		orb.position = global_position + Vector2(randf_range(-40.0, 40.0), randf_range(-30.0, 0.0))
		get_tree().current_scene.call_deferred("add_child", orb)
