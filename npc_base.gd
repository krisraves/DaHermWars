# open_mic_comic.gd
# THE OPEN MIC COMIC (06_ENEMY_BIBLE)
# "The most common life form in Out East."
# Core belief: "I'm one set away."
#
# Kit (per Enemy Bible): Mic Swing (melee) + Notebook Throw (ranged).
# Behavior reads as a comic who thinks the player is stealing
# their stage time:
#   PATROL  - pacing like they're rehearsing
#   CHASE   - spotted you; here comes the confrontation
#   WINDUP  - big telegraphed pull-back (readable = fair, per
#             Combat Philosophy: easy to learn, hard to master)
#   SWING   - mic swing, short active window
#   THROW   - hurls the notebook at mid-range
#   RECOVER - vulnerable; this is the player's opening

class_name OpenMicComic
extends EnemyBase

const NOTEBOOK := preload("res://scenes/enemies/notebook_projectile.tscn")

@export var patrol_speed: float = 90.0
@export var chase_speed: float = 175.0
@export var detection_range: float = 420.0
@export var melee_range: float = 78.0
@export var throw_range_min: float = 180.0
@export var throw_range_max: float = 380.0
@export var windup_time: float = 0.38
@export var swing_time: float = 0.16
@export var recover_time: float = 0.5
@export var throw_cooldown: float = 2.2

enum AI { PATROL, CHASE, WINDUP, SWING, THROW, RECOVER }

var _ai_state: AI = AI.PATROL
var _state_timer: float = 0.0
var _throw_cd: float = 0.0
var _player: Player = null

@onready var _edge_ray: RayCast2D = $EdgeRay
@onready var _melee_hitbox: Hitbox = $MeleeHitbox
@onready var _melee_shape: CollisionShape2D = $MeleeHitbox/Shape
@onready var _telegraph: ColorRect = $Visual/Telegraph


func _ready() -> void:
	super()
	_melee_hitbox.monitoring = false
	_melee_shape.disabled = true
	_telegraph.visible = false


func _ai(delta: float) -> void:
	_throw_cd = maxf(0.0, _throw_cd - delta)
	_state_timer = maxf(0.0, _state_timer - delta)
	_player = _find_player()

	match _ai_state:
		AI.PATROL:
			_do_patrol()
		AI.CHASE:
			_do_chase()
		AI.WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
			if _state_timer <= 0.0:
				_enter_swing()
		AI.SWING:
			velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
			if _state_timer <= 0.0:
				_end_swing()
		AI.THROW:
			velocity.x = 0.0
			if _state_timer <= 0.0:
				_release_notebook()
		AI.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
			if _state_timer <= 0.0:
				_ai_state = AI.CHASE


func _do_patrol() -> void:
	velocity.x = patrol_speed * facing
	# Turn at ledges and walls - nobody bombs off the stage by accident.
	_edge_ray.position.x = 26.0 * facing
	if is_on_wall() or (is_on_floor() and not _edge_ray.is_colliding()):
		facing = -facing
	if _player and _distance_to_player() < detection_range:
		_ai_state = AI.CHASE


func _do_chase() -> void:
	if _player == null:
		_ai_state = AI.PATROL
		return
	var dist := _distance_to_player()
	if dist > detection_range * 1.4:
		_ai_state = AI.PATROL
		return

	facing = 1 if _player.global_position.x > global_position.x else -1

	if dist <= melee_range:
		_enter_windup()
	elif dist >= throw_range_min and dist <= throw_range_max and _throw_cd <= 0.0:
		_enter_throw()
	else:
		velocity.x = chase_speed * facing
		# Don't chase off ledges.
		_edge_ray.position.x = 26.0 * facing
		if is_on_floor() and not _edge_ray.is_colliding():
			velocity.x = 0.0


func _enter_windup() -> void:
	_ai_state = AI.WINDUP
	_state_timer = windup_time
	_telegraph.visible = true  # readable tell


func _enter_swing() -> void:
	_ai_state = AI.SWING
	_state_timer = swing_time
	_telegraph.visible = false
	_melee_shape.position.x = absf(_melee_shape.position.x) * facing
	_melee_hitbox.monitoring_changed_rearm()
	_melee_hitbox.monitoring = true
	_melee_shape.disabled = false


func _end_swing() -> void:
	_melee_hitbox.monitoring = false
	_melee_shape.disabled = true
	_ai_state = AI.RECOVER
	_state_timer = recover_time


func _enter_throw() -> void:
	_ai_state = AI.THROW
	_state_timer = 0.3
	_telegraph.visible = true


func _release_notebook() -> void:
	_telegraph.visible = false
	_throw_cd = throw_cooldown
	var notebook := NOTEBOOK.instantiate()
	notebook.global_position = global_position + Vector2(24.0 * facing, -20.0)
	notebook.launch(facing)
	get_tree().current_scene.add_child(notebook)
	_ai_state = AI.RECOVER
	_state_timer = recover_time * 0.7


func _find_player() -> Player:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] as Player if not nodes.is_empty() else null


func _distance_to_player() -> float:
	return global_position.distance_to(_player.global_position)
