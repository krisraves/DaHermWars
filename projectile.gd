# former_winner.gd
# BOSS 15: THE FORMER WINNER (05_BOSS_BIBLE / REG_009)
# Theme: Empty Success. "Past Chuckle Yucks champion. Got everything.
# Still miserable."
#
# Design rule: NO summons. Every other boss calls for backup -
# drones, HR, interns, an audience. He has nobody. He fights alone
# in a house full of trophies, and his phase lines degrade from
# boast to question. Reward: PERFECT JOKE FRAGMENT.

class_name FormerWinner
extends EnemyBase

signal boss_defeated

enum Attack { PACE, TROPHY_TELL, TROPHY, CHANDELIER_TELL, CHANDELIER, RUSH, RECOVER }

@export var arena_left: float = 80.0
@export var arena_right: float = 1400.0
@export var floor_y: float = 660.0

var phase: int = 1
var _attack: Attack = Attack.PACE
var _timer: float = 1.0
var _rush_dir: int = 1
var _markers: Array = []
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
		Attack.PACE:
			facing = 1 if _player.global_position.x > global_position.x else -1
			velocity.x = 120.0 * facing
			if _timer <= 0.0:
				_pick()
		Attack.TROPHY_TELL:
			velocity.x = 0.0
			if _timer <= 0.0:
				_throw_trophies()
		Attack.TROPHY:
			if _timer <= 0.0:
				_set(Attack.RECOVER, 0.5)
		Attack.CHANDELIER_TELL:
			velocity.x = 0.0
			if _timer <= 0.0:
				_drop_chandeliers()
		Attack.CHANDELIER:
			if _timer <= 0.0:
				_set(Attack.RECOVER, 0.6)
		Attack.RUSH:
			velocity.x = (500.0 + 40.0 * phase) * _rush_dir
			if _timer <= 0.0 or is_on_wall() \
					or global_position.x < arena_left or global_position.x > arena_right:
				_set_body_hitbox(false)
				_set(Attack.RECOVER, 0.7)
		Attack.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
			if _timer <= 0.0:
				_set(Attack.PACE, maxf(0.5, 1.2 - 0.22 * phase))


func _pick() -> void:
	var roll := randf()
	if roll < 0.4:
		_telegraph.visible = true
		_set(Attack.TROPHY_TELL, 0.4)
	elif roll < 0.7 and phase >= 2:
		_telegraph.visible = true
		_set(Attack.CHANDELIER_TELL, 0.45)
	else:
		_rush_dir = 1 if _player.global_position.x > global_position.x else -1
		facing = _rush_dir
		_set_body_hitbox(true)
		_say_phase_line()
		_set(Attack.RUSH, 0.85)


func _say_phase_line() -> void:
	if randf() > 0.45:
		return
	var line := "I WON, YOU KNOW."
	if phase == 2:
		line = "THEY CHEERED FOR A YEAR."
	elif phase == 3:
		line = "WHY DIDN'T IT WORK?"
	Juice.float_text(global_position + Vector2(0, -150), line, Color(0.9, 0.82, 0.55))


func _throw_trophies() -> void:
	_telegraph.visible = false
	var count := 1 + phase
	for i in count:
		var trophy := GenericProjectile.new()
		trophy.gravity = 1200.0
		trophy.lift = -300.0 - 80.0 * i
		trophy.speed = 300.0 + 70.0 * i
		trophy.damage = 11
		trophy.color = Color(0.92, 0.78, 0.25)
		trophy.label_text = "1ST"
		trophy.box_size = Vector2(26, 30)
		trophy.global_position = global_position + Vector2(30.0 * facing, -56.0)
		get_tree().current_scene.add_child(trophy)
		trophy.launch(facing)
	_set(Attack.TROPHY, 0.5)


func _drop_chandeliers() -> void:
	_telegraph.visible = false
	var count := phase
	_markers.clear()
	for i in count:
		var x := clampf(_player.global_position.x + randf_range(-180.0, 180.0),
				arena_left + 50.0, arena_right - 50.0)
		var marker := ColorRect.new()
		marker.size = Vector2(80, 8)
		marker.position = Vector2(x - 40.0, floor_y - 12.0)
		marker.color = Color(1, 0.3, 0.2, 0.85)
		get_tree().current_scene.add_child(marker)
		_markers.append(marker)
		var crystal := GenericProjectile.new()
		crystal.speed = 0.0
		crystal.gravity = 2000.0
		crystal.damage = 12
		crystal.color = Color(0.95, 0.92, 0.8)
		crystal.label_text = "(crystal)"
		crystal.box_size = Vector2(50, 40)
		crystal.lifetime = 3.0
		crystal.global_position = Vector2(x, floor_y - 660.0)
		get_tree().current_scene.add_child(crystal)
		crystal.launch_vector(Vector2.ZERO)
		get_tree().create_timer(1.1).timeout.connect(marker.queue_free)
	_set(Attack.CHANDELIER, 0.7)


func _set(attack: Attack, time: float) -> void:
	_attack = attack
	_timer = time


func _set_body_hitbox(active: bool) -> void:
	var hitbox: Hitbox = $BodyHitbox
	var shape: CollisionShape2D = $BodyHitbox/Shape
	if active:
		hitbox.monitoring_changed_rearm()
	hitbox.set_deferred("monitoring", active)
	shape.set_deferred("disabled", not active)


func _check_phase(_amount: int, current: int) -> void:
	var ratio := float(current) / float(health.max_health)
	if phase == 1 and ratio <= 0.66:
		phase = 2
		_phase_fx("THEY CHEERED FOR A YEAR.")
	elif phase == 2 and ratio <= 0.33:
		phase = 3
		_phase_fx("WHY DIDN'T IT WORK?")


func _phase_fx(line: String) -> void:
	Juice.hitstop(0.2, 0.02)
	Juice.shake(8.0)
	Juice.float_text(global_position + Vector2(0, -160), line, Color(0.9, 0.82, 0.55))
	_set_body_hitbox(false)
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
	_set_body_hitbox(false)
	hurtbox.set_deferred("monitorable", false)
	for marker in _markers:
		if is_instance_valid(marker):
			marker.queue_free()
	died.emit(self)
	DialogueSystem.start([
		{"speaker": "FORMER WINNER", "text": "I did everything right. I won."},
		{"speaker": "DA'HERM", "text": "And?"},
		{"speaker": "FORMER WINNER", "text": "And then it was Tuesday."},
		{"speaker": "FORMER WINNER", "text": "There's a fragment in the trophy case. It's the only thing in this house I never understood. Maybe that's why it's the only thing I kept looking at."},
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
