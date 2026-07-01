# charger_enemy.gd
# BALL HOG (06_ENEMY_BIBLE): "Never passes."
# Sees you, lowers a shoulder, dribble-charges the full length of the
# lane. Hits a wall -> called for traveling -> long punish window.
# The counter-play is a sidestep the player has owned since M1.

class_name ChargerEnemy
extends EnemyBase

@export var patrol_speed: float = 80.0
@export var charge_speed: float = 540.0
@export var faction: String = ""
@export var detection_range: float = 460.0
@export var telegraph_time: float = 0.5
@export var charge_time: float = 1.1
@export var stun_time: float = 1.3

enum AI { PATROL, TELEGRAPH, CHARGE, STUNNED }

var _ai_state: AI = AI.PATROL
var _timer: float = 0.0
var _charge_dir: int = 1
var _telegraph: ColorRect
var _edge_ray: RayCast2D

@onready var _charge_hitbox: Hitbox = $ChargeHitbox
@onready var _charge_shape: CollisionShape2D = $ChargeHitbox/Shape


func _ready() -> void:
	super()
	_telegraph = ColorRect.new()
	_telegraph.size = Vector2(18, 18)
	_telegraph.position = Vector2(-9, -66)
	_telegraph.color = Color(1, 0.2, 0.15)
	_telegraph.visible = false
	visual.add_child(_telegraph)

	_edge_ray = RayCast2D.new()
	_edge_ray.target_position = Vector2(0, 64)
	_edge_ray.enabled = true
	add_child(_edge_ray)

	_charge_hitbox.monitoring = false
	_charge_shape.disabled = true


func _ai(delta: float) -> void:
	_timer -= delta
	match _ai_state:
		AI.PATROL:
			velocity.x = patrol_speed * facing
			_edge_ray.position.x = 28.0 * facing
			if is_on_wall() or (is_on_floor() and not _edge_ray.is_colliding()):
				facing = -facing
			var player := _find_player()
			if player != null and global_position.distance_to(player.global_position) < _effective_range():
				facing = 1 if player.global_position.x > global_position.x else -1
				_charge_dir = facing
				_ai_state = AI.TELEGRAPH
				_timer = telegraph_time
				_telegraph.visible = true
		AI.TELEGRAPH:
			velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
			if _timer <= 0.0:
				_begin_charge()
		AI.CHARGE:
			velocity.x = charge_speed * _charge_dir
			if is_on_wall():
				_bonk()
			elif _timer <= 0.0:
				_end_charge(AI.PATROL, 0.0)
		AI.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
			if _timer <= 0.0:
				_ai_state = AI.PATROL


func _begin_charge() -> void:
	_telegraph.visible = false
	_ai_state = AI.CHARGE
	_timer = charge_time
	_charge_shape.position.x = absf(_charge_shape.position.x) * _charge_dir
	_charge_hitbox.monitoring_changed_rearm()
	_charge_hitbox.set_deferred("monitoring", true)
	_charge_shape.set_deferred("disabled", false)


func _bonk() -> void:
	Juice.shake(4.0)
	Juice.float_text(global_position + Vector2(0, -90), "TRAVELING?!", Color(1, 0.8, 0.3))
	velocity.x = -180.0 * _charge_dir
	_end_charge(AI.STUNNED, stun_time)


func _end_charge(next: AI, time: float) -> void:
	_charge_hitbox.set_deferred("monitoring", false)
	_charge_shape.set_deferred("disabled", true)
	_ai_state = next
	_timer = time


func _find_player() -> Player:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] as Player if not nodes.is_empty() else null


func _effective_range() -> float:
	# CORPORATE CLEAN (08_COSTUMES): you look like you belong here.
	if faction == "corporate" and GameState.costume == &"corporate_clean":
		return detection_range * 0.25
	if faction == "cult" and GameState.costume == &"illuminepstein_initiate":
		return detection_range * 0.25
	if GameState.has_relic(&"stealth_upgrade"):
		return detection_range * 0.65  # PAPARAZZI SWARM reward
	return detection_range
