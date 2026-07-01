# disgraced_comedian.gd
# BOSS 01: THE DISGRACED COMEDIAN (05_BOSS_BIBLE, 13_VERTICAL_SLICE_SPEC)
# Archetype: Tragic Clown. Theme: Bitterness.
# "Still performing. Still blaming everyone else."
#
# PHASE 1 - BOMBING (100-66%): paces the stage, hurls notebooks,
#   swings the mic up close. He's doing his set AT you.
# PHASE 2 - DOUBLING DOWN (66-33%): faster; charges across the stage;
#   the room turns on everyone - BOOs rain from the dark.
# PHASE 3 - TRAGIC CLOWN (33-0%): slower, desaturated, desperate.
#   Big telegraphed slams, shockwaves down the floor. Briefly
#   sympathetic - per spec, "the boss realizes nobody is listening."
#
# Per Rule 16: the concept carries the fight. Per the Boss Bible,
# bosses have super-armor (flash + chip, no stagger) so phases play out.

class_name DisgracedComedian
extends EnemyBase

signal boss_defeated

const NOTEBOOK := preload("res://scenes/enemies/notebook_projectile.tscn")
const BooScript := preload("res://scripts/bosses/boo_projectile.gd")
const ShockwaveScript := preload("res://scripts/bosses/shockwave.gd")

enum Attack { PACE, THROW, WINDUP, SWING, CHARGE_TELL, CHARGE, SLAM_TELL, SLAM, RECOVER }

@export var arena_left: float = 100.0
@export var arena_right: float = 1700.0

var phase: int = 1
var _attack: Attack = Attack.PACE
var _timer: float = 0.6
var _charge_dir: int = 1
var _player: Player

@onready var _melee_hitbox: Hitbox = $MeleeHitbox
@onready var _melee_shape: CollisionShape2D = $MeleeHitbox/Shape
@onready var _telegraph: ColorRect = $Visual/Telegraph


func _ready() -> void:
	super()
	health.damaged.connect(_check_phase)
	_melee_hitbox.monitoring = false
	_melee_shape.disabled = true
	_telegraph.visible = false


# ------------------------------------------------------------------ ai

func _ai(delta: float) -> void:
	_player = _find_player()
	if _player == null:
		return
	_timer -= delta

	match _attack:
		Attack.PACE:
			_do_pace()
		Attack.THROW:
			if _timer <= 0.0:
				_release_notebooks()
		Attack.WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_begin_swing()
		Attack.SWING:
			velocity.x = 0.0
			if _timer <= 0.0:
				_end_swing()
		Attack.CHARGE_TELL:
			velocity.x = 0.0
			if _timer <= 0.0:
				_begin_charge()
		Attack.CHARGE:
			velocity.x = 560.0 * _charge_dir
			if _timer <= 0.0 or is_on_wall() \
					or global_position.x < arena_left or global_position.x > arena_right:
				_end_charge()
		Attack.SLAM_TELL:
			velocity.x = 0.0
			if _timer <= 0.0:
				_do_slam()
		Attack.SLAM:
			if _timer <= 0.0:
				_set_attack(Attack.RECOVER, 0.8)
		Attack.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
			if _timer <= 0.0:
				_set_attack(Attack.PACE, _pace_time())


func _do_pace() -> void:
	facing = 1 if _player.global_position.x > global_position.x else -1
	var dist: float = absf(_player.global_position.x - global_position.x)
	velocity.x = (140.0 if phase < 3 else 90.0) * facing

	if _timer > 0.0:
		return
	# pick the next attack by phase + distance
	if dist < 110.0:
		_set_attack(Attack.WINDUP, 0.4)
		_telegraph.visible = true
	elif phase >= 3:
		_set_attack(Attack.SLAM_TELL, 0.7)
		_telegraph.visible = true
	elif phase == 2 and randf() < 0.45:
		_charge_dir = facing
		_set_attack(Attack.CHARGE_TELL, 0.5)
		_telegraph.visible = true
	else:
		_set_attack(Attack.THROW, 0.35)
		_telegraph.visible = true


func _pace_time() -> float:
	return 1.1 if phase == 1 else (0.7 if phase == 2 else 1.0)


func _set_attack(attack: Attack, time: float) -> void:
	_attack = attack
	_timer = time


# ------------------------------------------------------------------ attacks

func _release_notebooks() -> void:
	_telegraph.visible = false
	var count := 2 if phase == 1 else 3
	for i in count:
		var notebook := NOTEBOOK.instantiate()
		notebook.global_position = global_position + Vector2(30.0 * facing, -40.0)
		notebook.throw_speed = 340.0 + 90.0 * i
		notebook.launch(facing)
		get_tree().current_scene.add_child(notebook)
	if phase == 2:
		_rain_boos()
	_set_attack(Attack.RECOVER, 0.6 if phase == 1 else 0.4)


func _rain_boos() -> void:
	for i in 4:
		var boo: BooProjectile = BooScript.new()
		boo.global_position = Vector2(
			_player.global_position.x + randf_range(-180.0, 180.0), -80.0)
		get_tree().current_scene.add_child(boo)


func _begin_swing() -> void:
	_telegraph.visible = false
	_melee_shape.position.x = absf(_melee_shape.position.x) * facing
	_melee_hitbox.monitoring_changed_rearm()
	_melee_hitbox.set_deferred("monitoring", true)
	_melee_shape.set_deferred("disabled", false)
	_set_attack(Attack.SWING, 0.18)


func _end_swing() -> void:
	_melee_hitbox.set_deferred("monitoring", false)
	_melee_shape.set_deferred("disabled", true)
	_set_attack(Attack.RECOVER, 0.55)


func _begin_charge() -> void:
	_telegraph.visible = false
	Juice.shake(3.0)
	_melee_shape.position.x = absf(_melee_shape.position.x) * _charge_dir
	_melee_hitbox.monitoring_changed_rearm()
	_melee_hitbox.set_deferred("monitoring", true)
	_melee_shape.set_deferred("disabled", false)
	facing = _charge_dir
	_set_attack(Attack.CHARGE, 1.0)


func _end_charge() -> void:
	_melee_hitbox.set_deferred("monitoring", false)
	_melee_shape.set_deferred("disabled", true)
	_set_attack(Attack.RECOVER, 0.7)


func _do_slam() -> void:
	_telegraph.visible = false
	Juice.shake(9.0)
	Juice.hitstop(0.05)
	for dir in [-1, 1]:
		var wave: Shockwave = ShockwaveScript.new()
		wave.direction = dir
		wave.global_position = global_position + Vector2(30.0 * dir, 38.0)
		get_tree().current_scene.add_child(wave)
	if randf() < 0.5:
		Juice.float_text(global_position + Vector2(0, -120),
			"...nobody's listening.", Color(0.7, 0.7, 0.75))
	_set_attack(Attack.SLAM, 0.3)


# ------------------------------------------------------------------ phases

func _check_phase(_amount: int, current: int) -> void:
	var ratio := float(current) / float(health.max_health)
	if phase == 1 and ratio <= 0.66:
		_enter_phase(2, "I'M NOT WRONG. THE ROOM IS WRONG.")
	elif phase == 2 and ratio <= 0.33:
		_enter_phase(3, "...")
		visual.modulate = Color(0.65, 0.65, 0.7)


func _enter_phase(p: int, line: String) -> void:
	phase = p
	Juice.hitstop(0.2, 0.02)
	Juice.shake(8.0)
	Juice.float_text(global_position + Vector2(0, -130), line, Color(1, 0.5, 0.4))
	_telegraph.visible = false
	_melee_hitbox.set_deferred("monitoring", false)
	_melee_shape.set_deferred("disabled", true)
	_set_attack(Attack.RECOVER, 0.8)


# ------------------------------------------------------------------ hits & defeat

func _on_hit_received(hitbox: Hitbox) -> void:
	# Boss super-armor: damage + flash, no stagger or knockback.
	if _is_dead:
		return
	health.take_damage(hitbox.damage)
	_flash()
	Juice.hitstop(0.03)
	Juice.shake(2.0)


func _on_died() -> void:
	_is_dead = true
	velocity = Vector2.ZERO
	_telegraph.visible = false
	_melee_hitbox.set_deferred("monitoring", false)
	_melee_shape.set_deferred("disabled", true)
	hurtbox.set_deferred("monitorable", false)
	visual.modulate = Color(0.6, 0.6, 0.65)

	died.emit(self)
	DialogueSystem.start([
		{"speaker": "DISGRACED COMEDIAN", "text": "...I used to kill in this room."},
		{"speaker": "DA'HERM", "text": "Rooms change."},
		{"speaker": "DISGRACED COMEDIAN", "text": "...so did I. Take the glove trick. I only ever used it to burn bridges."},
	])
	DialogueSystem.finished.connect(_finish_defeat, CONNECT_ONE_SHOT)


func _finish_defeat() -> void:
	boss_defeated.emit()
	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 1.2)
	tween.tween_callback(queue_free)


func _find_player() -> Player:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] as Player if not nodes.is_empty() else null
