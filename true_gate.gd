# ranged_enemy.gd
# Configurable keep-distance shooter. One behavior, three cultures:
#   PODCAST BRO   - straight "audio blast" ("ACTUALLY—")
#   COMMENT TROLL - lobbed toxic blobs ("ratio'd")
#   SNEAKERHEAD   - thrown collectible footwear (it pains him)
# Exports define the projectile; the satire lives in the config.

class_name RangedEnemy
extends EnemyBase

@export_group("Behavior")
@export var move_speed: float = 110.0
@export var faction: String = ""
@export var detection_range: float = 480.0
@export var preferred_range: float = 300.0
@export var retreat_range: float = 160.0
@export var fire_interval: float = 1.8
@export var telegraph_time: float = 0.35

@export_group("Projectile")
@export var proj_speed: float = 360.0
@export var proj_gravity: float = 0.0
@export var proj_lift: float = 0.0
@export var proj_damage: int = 8
@export var proj_color: Color = Color(0.4, 0.8, 1.0)
@export var proj_label: String = ""
@export var proj_size: Vector2 = Vector2(22, 22)

var _fire_timer: float = 1.0
var _telegraphing: bool = false
var _telegraph: ColorRect
var _edge_ray: RayCast2D


func _ready() -> void:
	super()
	_telegraph = ColorRect.new()
	_telegraph.size = Vector2(16, 16)
	_telegraph.position = Vector2(-8, -body_height() * 0.5 - 24.0)
	_telegraph.color = Color(1, 0.2, 0.15)
	_telegraph.visible = false
	visual.add_child(_telegraph)

	_edge_ray = RayCast2D.new()
	_edge_ray.target_position = Vector2(0, 64)
	_edge_ray.enabled = true
	add_child(_edge_ray)


func body_height() -> float:
	return 76.0


func _ai(delta: float) -> void:
	var player := _find_player()
	if player == null:
		velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
		return
	var dist := global_position.distance_to(player.global_position)
	if dist > _effective_range():
		velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
		_telegraph.visible = false
		_telegraphing = false
		return

	facing = 1 if player.global_position.x > global_position.x else -1

	# spacing: too close -> back up; too far -> close in; else hold
	var move_dir := 0
	if dist < retreat_range:
		move_dir = -facing
	elif dist > preferred_range + 60.0:
		move_dir = facing
	_edge_ray.position.x = 26.0 * move_dir
	if move_dir != 0 and is_on_floor() and _edge_ray.is_colliding():
		velocity.x = move_speed * move_dir
	else:
		velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)

	# firing
	_fire_timer -= delta
	if _fire_timer <= 0.0 and not _telegraphing:
		_telegraphing = true
		_telegraph.visible = true
		_fire_timer = telegraph_time
	elif _fire_timer <= 0.0 and _telegraphing:
		_fire(player)
		_telegraphing = false
		_telegraph.visible = false
		_fire_timer = fire_interval


func _fire(_player: Player) -> void:
	var proj := GenericProjectile.new()
	proj.speed = proj_speed
	proj.gravity = proj_gravity
	proj.lift = proj_lift
	proj.damage = proj_damage
	proj.color = proj_color
	proj.label_text = proj_label
	proj.box_size = proj_size
	proj.global_position = global_position + Vector2(26.0 * facing, -14.0)
	get_tree().current_scene.add_child(proj)
	proj.launch(facing)


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
