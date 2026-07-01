# netflicks.gd
# BOSS 12: NETFLICKS (05_BOSS_BIBLE)
# "A giant red squid-like executive creature." Tentacle streams,
# cancellation attacks, special offers. Reward: STREAMING PASS.

class_name Netflicks
extends EnemyBase

signal boss_defeated

enum Attack { LOOM, TENTACLES, CANCEL_TELL, CANCEL, OFFER, RECOVER }

@export var arena_left: float = 100.0
@export var arena_right: float = 1500.0
@export var floor_y: float = 660.0

var phase: int = 1
var _attack: Attack = Attack.LOOM
var _timer: float = 1.3
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
		Attack.LOOM:
			# it doesn't chase. it looms. you came to IT.
			global_position.y = 360.0 + sin(Time.get_ticks_msec() * 0.0018) * 20.0
			facing = 1 if _player.global_position.x > global_position.x else -1
			if _timer <= 0.0:
				_pick()
		Attack.CANCEL_TELL:
			if _timer <= 0.0:
				_cancellation()
		Attack.TENTACLES, Attack.CANCEL, Attack.OFFER:
			if _timer <= 0.0:
				_set(Attack.RECOVER, 0.5)
		Attack.RECOVER:
			if _timer <= 0.0:
				_set(Attack.LOOM, maxf(0.45, 1.2 - 0.25 * phase))


func _pick() -> void:
	var roll := randf()
	if roll < 0.45:
		_tentacle_stream()
	elif roll < 0.8:
		_telegraph.visible = true
		Juice.float_text(global_position + Vector2(0, -150), "PERFORMANCE REVIEW", Color(0.95, 0.2, 0.25))
		_set(Attack.CANCEL_TELL, 0.55)
	else:
		_special_offer()


func _tentacle_stream() -> void:
	# tentacles erupt in a marching line toward the player
	var start_x := global_position.x
	var dir := signf(_player.global_position.x - start_x)
	var count := 3 + phase
	for i in count:
		var tentacle := TentacleStrike.new()
		tentacle.warn_time = 0.4 + 0.13 * i
		tentacle.active_time = 0.22
		tentacle.column_height = 380.0
		tentacle.position = Vector2(
			clampf(start_x + dir * (160.0 + 150.0 * i), arena_left + 40.0, arena_right - 40.0),
			floor_y)
		get_tree().current_scene.add_child(tentacle)
	_set(Attack.TENTACLES, 0.9)


func _cancellation() -> void:
	# beloved things, ended mid-season: a fast wide beam at your row
	_telegraph.visible = false
	var beam := GenericProjectile.new()
	beam.speed = 520.0 + 60.0 * phase
	beam.damage = 12
	beam.box_size = Vector2(120, 26)
	beam.color = Color(0.95, 0.15, 0.2)
	beam.label_text = "CANCELLED"
	beam.lifetime = 3.0
	beam.global_position = Vector2(global_position.x, clampf(_player.global_position.y, 200.0, floor_y - 40.0))
	get_tree().current_scene.add_child(beam)
	beam.launch(1 if _player.global_position.x > global_position.x else -1)
	_set(Attack.CANCEL, 0.5)


func _special_offer() -> void:
	# slow, weirdly tempting, hard to refuse: drifting offer orbs
	for i in 2 + phase:
		var offer := GenericProjectile.new()
		offer.speed = 150.0 + 30.0 * i
		offer.damage = 9
		offer.box_size = Vector2(58, 24)
		offer.color = Color(0.9, 0.3, 0.35)
		offer.label_text = ["30 DAYS FREE*", "ONLY 19.99", "PRICE INCREASE", "WITH ADS NOW"][i % 4]
		offer.lifetime = 6.0
		offer.global_position = global_position + Vector2(0, -30.0 + 26.0 * i)
		get_tree().current_scene.add_child(offer)
		var aim := (_player.global_position - offer.global_position).normalized()
		offer.launch_vector(aim.rotated(randf_range(-0.3, 0.3)) * offer.speed)
	_set(Attack.OFFER, 0.6)


func _set(attack: Attack, time: float) -> void:
	_attack = attack
	_timer = time


func _check_phase(_amount: int, current: int) -> void:
	var ratio := float(current) / float(health.max_health)
	if phase == 1 and ratio <= 0.66:
		phase = 2
		_phase_fx("YOUR ENGAGEMENT IS DOWN. WE'RE MAKING CHANGES.")
	elif phase == 2 and ratio <= 0.33:
		phase = 3
		_phase_fx("(every tentacle is holding a different exclusive)")


func _phase_fx(line: String) -> void:
	Juice.hitstop(0.2, 0.02)
	Juice.shake(8.0)
	Juice.float_text(global_position + Vector2(0, -160), line, Color(0.95, 0.25, 0.3))
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
		{"speaker": "NETFLICKS", "text": "WAIT. BEFORE YOU GO. ARE YOU STILL WATCHING?"},
		{"speaker": "DA'HERM", "text": "Nobody was ever watching. That was the Algorithm talking."},
		{"speaker": "NETFLICKS", "text": "(deflating) ...cancelled. after one season. like all the good ones."},
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
