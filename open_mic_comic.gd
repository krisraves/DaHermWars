# the_algorithm.gd
# BOSS 11: THE ALGORITHM (05_BOSS_BIBLE)
# Theme: Artificial Success. "An AI that determines success."
#
# Design: its attack POOL is randomized (canon: "randomized attack
# patterns") and grows each phase, so the fight resists muscle memory:
#   PULSE     - ground soundwaves both directions
#   BEAM      - predictive strike columns: it aims where you're GOING
#               (position + velocity lead), not where you are
#   SUPPRESS  - "VISIBILITY LIMITED": your damage halved for 3s
#   SWARM     - Buffer Spirits drift in (phase 3)
# Stationary monolith. It has never needed to move. Content comes to it.

class_name TheAlgorithm
extends EnemyBase

signal boss_defeated

const BUFFER := preload("res://scenes/enemies/buffer_spirit.tscn")

enum Attack { THINK, PULSE, BEAM_TELL, SUPPRESS, SWARM, RECOVER }

var phase: int = 1
var _attack: Attack = Attack.THINK
var _timer: float = 1.2
var _player: Player

@onready var _telegraph: ColorRect = $Visual/Telegraph


func _ready() -> void:
	super()
	health.damaged.connect(_check_phase)
	_telegraph.visible = false


func _ai(delta: float) -> void:
	velocity = Vector2.ZERO
	_player = _find_player()
	if _player == null:
		return
	_timer -= delta
	match _attack:
		Attack.THINK:
			if _timer <= 0.0:
				_pick()
		Attack.PULSE:
			if _timer <= 0.0:
				_fire_pulse()
		Attack.BEAM_TELL:
			if _timer <= 0.0:
				_set(Attack.RECOVER, 0.8)
		Attack.SUPPRESS:
			if _timer <= 0.0:
				_set(Attack.RECOVER, 0.4)
		Attack.SWARM:
			if _timer <= 0.0:
				_set(Attack.RECOVER, 0.5)
		Attack.RECOVER:
			if _timer <= 0.0:
				_set(Attack.THINK, maxf(0.35, 1.0 - 0.22 * phase))


func _pick() -> void:
	var pool: Array = ["pulse", "beam"]
	if phase >= 2:
		pool.append("suppress")
	if phase >= 3:
		pool.append("swarm")
		pool.append("beam")  # weight beams up late
	match pool.pick_random():
		"pulse":
			_telegraph.visible = true
			_set(Attack.PULSE, 0.4)
		"beam":
			_fire_beams()
		"suppress":
			_do_suppress()
		"swarm":
			_do_swarm()


func _fire_pulse() -> void:
	_telegraph.visible = false
	for dir in [-1, 1]:
		var wave := GenericProjectile.new()
		wave.speed = 320.0 + 60.0 * phase
		wave.damage = 8
		wave.box_size = Vector2(28, 44)
		wave.color = Color(0.3, 1.0, 0.75, 0.85)
		wave.label_text = "TRENDING"
		wave.lifetime = 4.0
		wave.global_position = global_position + Vector2(60.0 * dir, 540.0 - global_position.y + 96.0)
		wave.global_position.y = 624.0
		get_tree().current_scene.add_child(wave)
		wave.launch(dir)
	_set(Attack.RECOVER, 0.5)


func _fire_beams() -> void:
	# PREDICTIVE: strike where the player WILL be. Standing still
	# becomes the counter-play - the one thing the feed can't model.
	var count := 1 if phase == 1 else 2
	for i in count:
		var strike := TentacleStrike.new()
		strike.warn_time = 0.55 + 0.15 * i
		strike.active_time = 0.22
		strike.column_height = 420.0
		var predicted_x := _player.global_position.x + _player.velocity.x * (0.42 + 0.1 * i)
		strike.position = Vector2(predicted_x, 660.0)
		get_tree().current_scene.add_child(strike)
	Juice.float_text(global_position + Vector2(0, -180), "YOU WILL ENJOY THIS NEXT.", Color(0.4, 1, 0.8))
	_set(Attack.BEAM_TELL, 0.9)


func _do_suppress() -> void:
	if _player != null:
		_player.apply_suppression(3.0)
	Juice.float_text(global_position + Vector2(0, -180), "REACH: LIMITED.", Color(0.4, 1, 0.8))
	_set(Attack.SUPPRESS, 0.5)


func _do_swarm() -> void:
	for i in 2:
		var spirit := BUFFER.instantiate()
		spirit.position = global_position + Vector2(-220.0 + 440.0 * i, -160.0)
		get_tree().current_scene.add_child(spirit)
	Juice.float_text(global_position + Vector2(0, -180), "BUFFERING...", Color(0.6, 0.7, 0.9))
	_set(Attack.SWARM, 0.6)


func _set(attack: Attack, time: float) -> void:
	_attack = attack
	_timer = time


func _check_phase(_amount: int, current: int) -> void:
	var ratio := float(current) / float(health.max_health)
	if phase == 1 and ratio <= 0.66:
		phase = 2
		_phase_fx("ENGAGEMENT DETECTED. ADJUSTING WEIGHTS.")
	elif phase == 2 and ratio <= 0.33:
		phase = 3
		_phase_fx("YOU ARE THE TREND NOW.")


func _phase_fx(line: String) -> void:
	Juice.hitstop(0.2, 0.02)
	Juice.shake(8.0)
	Juice.float_text(global_position + Vector2(0, -190), line, Color(0.3, 1, 0.75))
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
	hurtbox.set_deferred("monitorable", false)
	died.emit(self)
	DialogueSystem.start([
		{"speaker": "THE ALGORITHM", "text": "RECALCULATING... RECALCULATING... AUDIENCE NOT FOUND."},
		{"speaker": "DA'HERM", "text": "Recommend THAT."},
		{"speaker": "THE ALGORITHM", "text": "FINAL OUTPUT: ...you were never going to trend. You were going to matter. ERROR: CATEGORY UNKNOWN."},
	])
	DialogueSystem.finished.connect(_finish, CONNECT_ONE_SHOT)


func _finish() -> void:
	boss_defeated.emit()
	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 1.2)
	tween.tween_callback(queue_free)


func _find_player() -> Player:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] as Player if not nodes.is_empty() else null
