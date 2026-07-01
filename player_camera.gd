# silent_guard.gd
# INNER CIRCLE GUARD (06_ENEMY_BIBLE: "Elite protector."
# BESTIARY, Da'Herm's note: "This one actually scares me.")
#
# The only enemy permitted below the estates - and the only enemy in
# the game with NO flavor text, NO quips, NO float-text anything
# (RULE 19: no gag enemies, no comic relief). It patrols. It notices.
# It swings. It drops nothing - followers down here would be obscene
# (follower_drop = 0 set in the scene).
#
# Tuning encourages AVOIDANCE: high health, heavy hit, slow recovery.
# Fighting one is possible. Fighting all of them is a choice.

class_name SilentGuard
extends EnemyBase

@export var patrol_speed: float = 60.0
@export var chase_speed: float = 210.0
@export var detection_range: float = 380.0
@export var swing_range: float = 84.0
@export var swing_telegraph: float = 0.45
@export var swing_recover: float = 0.9

enum AI { PATROL, CHASE, TELEGRAPH, SWING, RECOVER }

var _ai_state: AI = AI.PATROL
var _timer: float = 0.0
var _telegraph: ColorRect
var _edge_ray: RayCast2D

@onready var _swing_hitbox: Hitbox = $SwingHitbox
@onready var _swing_shape: CollisionShape2D = $SwingHitbox/Shape


func _ready() -> void:
	super()
	# the telegraph is dim. it does not announce. it prepares.
	_telegraph = ColorRect.new()
	_telegraph.size = Vector2(14, 14)
	_telegraph.position = Vector2(-7, -78)
	_telegraph.color = Color(0.55, 0.5, 0.6)
	_telegraph.visible = false
	visual.add_child(_telegraph)

	_edge_ray = RayCast2D.new()
	_edge_ray.target_position = Vector2(0, 70)
	_edge_ray.enabled = true
	add_child(_edge_ray)

	_swing_hitbox.monitoring = false
	_swing_shape.disabled = true


func _ai(delta: float) -> void:
	_timer -= delta
	var player := _find_player()
	match _ai_state:
		AI.PATROL:
			velocity.x = patrol_speed * facing
			_edge_ray.position.x = 30.0 * facing
			if is_on_wall() or (is_on_floor() and not _edge_ray.is_colliding()):
				facing = -facing
			if player != null and global_position.distance_to(player.global_position) < detection_range:
				_ai_state = AI.CHASE
		AI.CHASE:
			if player == null:
				_ai_state = AI.PATROL
				return
			var dx := player.global_position.x - global_position.x
			facing = 1 if dx > 0.0 else -1
			_edge_ray.position.x = 30.0 * facing
			if is_on_floor() and not _edge_ray.is_colliding():
				velocity.x = 0.0  # it does not fall for that
			else:
				velocity.x = chase_speed * facing
			if global_position.distance_to(player.global_position) > detection_range * 1.6:
				_ai_state = AI.PATROL
			elif absf(dx) < swing_range and is_on_floor():
				_ai_state = AI.TELEGRAPH
				_timer = swing_telegraph
				_telegraph.visible = true
		AI.TELEGRAPH:
			velocity.x = 0.0
			if _timer <= 0.0:
				_swing()
		AI.SWING:
			velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
			if _timer <= 0.0:
				_end_swing()
		AI.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
			if _timer <= 0.0:
				_ai_state = AI.CHASE


func _swing() -> void:
	_telegraph.visible = false
	_ai_state = AI.SWING
	_timer = 0.22
	_swing_shape.position.x = absf(_swing_shape.position.x) * facing
	_swing_hitbox.monitoring_changed_rearm()
	_swing_hitbox.set_deferred("monitoring", true)
	_swing_shape.set_deferred("disabled", false)


func _end_swing() -> void:
	_swing_hitbox.set_deferred("monitoring", false)
	_swing_shape.set_deferred("disabled", true)
	_ai_state = AI.RECOVER
	_timer = swing_recover


func _find_player() -> Player:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] as Player if not nodes.is_empty() else null
