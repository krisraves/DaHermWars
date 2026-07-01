# flyer_enemy.gd
# Hovering enemy. Set gravity=0 in the scene; this script owns all
# motion: drift toward preferred range, sine bob, aimed shots.
# Configs: CAMERA DRONE (Hills) · ALGORITHM DRONE (HQ) ·
# BUFFER SPIRIT (HQ, slow, unarmed, body contact).

class_name FlyerEnemy
extends EnemyBase

@export var fly_speed: float = 130.0
@export var preferred_range: float = 240.0
@export var hover_height: float = 140.0    # above the player
@export var bob_amplitude: float = 14.0
@export var detection_range: float = 520.0
@export var fire_interval: float = 2.0     # <= 0 means unarmed
@export var proj_speed: float = 380.0
@export var proj_damage: int = 7
@export var proj_color: Color = Color(0.9, 0.9, 1.0)
@export var proj_label: String = ""

var _fire_timer: float = 1.2
var _bob_phase: float = 0.0


func _ready() -> void:
	super()
	_bob_phase = randf() * TAU


func _ai(delta: float) -> void:
	_bob_phase += delta * 3.0
	var player := _find_player()
	if player == null or global_position.distance_to(player.global_position) > detection_range:
		velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
		velocity.y += sin(_bob_phase) * bob_amplitude
		return

	facing = 1 if player.global_position.x > global_position.x else -1
	var target := player.global_position + Vector2(
		-signf(player.global_position.x - global_position.x) * preferred_range,
		-hover_height)
	var to_target := target - global_position
	velocity = to_target.normalized() * minf(fly_speed, to_target.length() * 2.0)
	velocity.y += sin(_bob_phase) * bob_amplitude

	if fire_interval > 0.0:
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_fire_timer = fire_interval
			var proj := GenericProjectile.new()
			proj.speed = proj_speed
			proj.damage = proj_damage
			proj.color = proj_color
			proj.label_text = proj_label
			proj.box_size = Vector2(20, 14)
			proj.lifetime = 3.0
			proj.global_position = global_position + Vector2(0, 16)
			get_tree().current_scene.add_child(proj)
			var aim := (player.global_position - global_position).normalized()
			proj.launch_vector(aim * proj_speed)


func _find_player() -> Player:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] as Player if not nodes.is_empty() else null
