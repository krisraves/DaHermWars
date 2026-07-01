# paparazzi_swarm.gd
# BOSS 14: THE PAPARAZZI SWARM (05_BOSS_BIBLE)
# "Thousands of photographers." Mechanics: flash blindness, camera
# drones, crowd pressure. Reward: STEALTH UPGRADE.
#
# One hovering mass of lenses and elbows. FLASH STORM whites the
# screen edge and rakes aimed shots; CROWD PRESSURE sends slow,
# tall walls of bodies across the floor ("THIS WAY! ONE MORE!");
# drones peel off the mass to chase you personally.

class_name PaparazziSwarm
extends EnemyBase

signal boss_defeated

const DRONE := preload("res://scenes/enemies/camera_drone.tscn")

enum Attack { DRIFT, FLASH_TELL, FLASH, PRESSURE, SPAWN, RECOVER }

@export var arena_left: float = 100.0
@export var arena_right: float = 1700.0
@export var floor_y: float = 660.0

var phase: int = 1
var _attack: Attack = Attack.DRIFT
var _timer: float = 1.2
var _adds_alive: int = 0
var _player: Player

@onready var _telegraph: ColorRect = $Visual/Telegraph


func _ready() -> void:
	super()
	health.damaged.connect(_check_phase)
	_telegraph.visible = false


func _ai(delta: float) -> void:
	_player = _find_player()
	if _player == null:
		return
	_timer -= delta
	match _attack:
		Attack.DRIFT:
			facing = 1 if _player.global_position.x > global_position.x else -1
			var target := Vector2(
				clampf(_player.global_position.x - 200.0 * facing, arena_left + 90.0, arena_right - 90.0),
				400.0 + sin(Time.get_ticks_msec() * 0.0025) * 26.0)
			velocity = (target - global_position).normalized() * minf(170.0, (target - global_position).length() * 2.0)
			if _timer <= 0.0:
				_pick()
		Attack.FLASH_TELL:
			velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
			if _timer <= 0.0:
				_flash_storm()
		Attack.FLASH, Attack.PRESSURE, Attack.SPAWN:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_set(Attack.RECOVER, 0.5)
		Attack.RECOVER:
			velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
			if _timer <= 0.0:
				_set(Attack.DRIFT, maxf(0.4, 1.1 - 0.25 * phase))


func _pick() -> void:
	var roll := randf()
	if roll < 0.4:
		_telegraph.visible = true
		_set(Attack.FLASH_TELL, 0.5)
	elif roll < 0.75 or _adds_alive >= 2:
		_crowd_pressure()
	else:
		_spawn_drone()


func _flash_storm() -> void:
	_telegraph.visible = false
	# the blindness: a brief white wash over the whole arena
	var wash := ColorRect.new()
	wash.size = Vector2(arena_right - arena_left + 400.0, 1200.0)
	wash.position = Vector2(arena_left - 200.0, floor_y - 1100.0)
	wash.color = Color(1, 1, 1, 0.18 if Settings.reduced_flash else 0.55)
	wash.z_index = 50
	get_tree().current_scene.add_child(wash)
	var tween := wash.create_tween()
	tween.tween_property(wash, "color:a", 0.0, 0.7)
	tween.tween_callback(wash.queue_free)
	Juice.shake(4.0)
	for i in 2 + phase:
		var shot := GenericProjectile.new()
		shot.speed = 380.0 + 55.0 * i
		shot.damage = 8
		shot.color = Color(1, 1, 0.9)
		shot.label_text = "FLASH!"
		shot.box_size = Vector2(18, 18)
		shot.lifetime = 2.8
		shot.global_position = global_position + Vector2(randf_range(-60.0, 60.0), randf_range(-40.0, 20.0))
		get_tree().current_scene.add_child(shot)
		var aim := (_player.global_position - shot.global_position).normalized()
		shot.launch_vector(aim.rotated(randf_range(-0.25, 0.25)) * shot.speed)
	_set(Attack.FLASH, 0.55)


func _crowd_pressure() -> void:
	var labels := ["THIS WAY!", "ONE MORE!", "OVER HERE!", "WHO ARE YOU WEARING?!"]
	var dirs: Array = [-1, 1] if phase >= 2 else [1 if _player.global_position.x < global_position.x else -1]
	for dir: int in dirs:
		var wall := GenericProjectile.new()
		wall.speed = 170.0 + 25.0 * phase
		wall.damage = 10
		wall.box_size = Vector2(46, 110)
		wall.color = Color(0.2, 0.2, 0.26, 0.95)
		wall.label_text = labels.pick_random()
		wall.lifetime = 7.0
		wall.global_position = Vector2(
			arena_right - 60.0 if dir < 0 else arena_left + 60.0, floor_y - 70.0)
		get_tree().current_scene.add_child(wall)
		wall.launch(dir)
	Juice.float_text(global_position + Vector2(0, -130), "(the crowd surges)", Color(0.9, 0.9, 0.95))
	_set(Attack.PRESSURE, 0.6)


func _spawn_drone() -> void:
	var drone := DRONE.instantiate()
	drone.position = global_position + Vector2(randf_range(-80.0, 80.0), -60.0)
	get_tree().current_scene.add_child(drone)
	_adds_alive += 1
	drone.died.connect(func(_e): _adds_alive -= 1)
	Juice.float_text(drone.position + Vector2(0, -50), "(one peels off the mass)", Color(0.85, 0.85, 0.9))
	_set(Attack.SPAWN, 0.5)


func _set(attack: Attack, time: float) -> void:
	_attack = attack
	_timer = time


func _check_phase(_amount: int, current: int) -> void:
	var ratio := float(current) / float(health.max_health)
	if phase == 1 and ratio <= 0.66:
		phase = 2
		_phase_fx("(the swarm doubles. where do they keep COMING from)")
	elif phase == 2 and ratio <= 0.33:
		phase = 3
		_phase_fx("(they're not even taking pictures anymore. just flashing.)")


func _phase_fx(line: String) -> void:
	Juice.hitstop(0.2, 0.02)
	Juice.shake(8.0)
	Juice.float_text(global_position + Vector2(0, -150), line, Color(1, 1, 0.9))
	_telegraph.visible = false
	_set(Attack.RECOVER, 0.9)


func _on_hit_received(hitbox: Hitbox) -> void:
	if _is_dead:
		return
	health.take_damage(hitbox.damage)
	_flash()
	Juice.hitstop(0.03)
	Juice.shake(2.0)


func _on_died() -> void:
	_is_dead = true
	velocity = Vector2.ZERO
	hurtbox.set_deferred("monitorable", false)
	died.emit(self)
	DialogueSystem.start([
		{"speaker": "PAPARAZZI", "text": "(scattering) HE'S NOT EVEN FAMOUS! WHY DID WE— WHO ASSIGNED THIS?!"},
		{"speaker": "DA'HERM", "text": "Yeah. Hold that thought forever."},
	])
	DialogueSystem.finished.connect(_finish, CONNECT_ONE_SHOT)


func _finish() -> void:
	boss_defeated.emit()
	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)


func _find_player() -> Player:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] as Player if not nodes.is_empty() else null
