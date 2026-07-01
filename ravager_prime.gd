# tuff_tiddy.gd
# BOSS 24: TUFF TIDDY (05_BOSS_BIBLE / MASTER_CANON)
# Theme: Power Without Authenticity.
# RULE 8: he must be funny. Dangerous, ancient, AND ridiculous -
# he genuinely believes he is hilarious, including while dissolving.
#
# PHASE 1 - THE PRODUCER: golden mic volleys, summons initiates
#   ("GET MY GUY SOME NOTES"), self-congratulation.
# PHASE 2 - ENTERTAINMENT EMPEROR: spotlight crown (predicting
#   beams), golden rushes, applause waves.
# PHASE 3 - LIVING BABY OIL DEMON: the suit was the disguise. Oil
#   geysers, lingering slicks, faster everything. Still pitching.
# Reward: the GOOD ENDING.

class_name TuffTiddy
extends EnemyBase

signal boss_defeated

const INITIATE := preload("res://scenes/enemies/illuminepstein_initiate.tscn")
const OIL := preload("res://scripts/bosses/oil_slick.gd")

const LINES_P1 := ["NOW THAT IS COMEDY!", "WRITE THAT DOWN. THAT'S GOLD.", "PEOPLE ASK ME HOW I STAY THIS FUNNY."]
const LINES_P2 := ["I PRODUCED LAUGHTER ITSELF.", "THIS ARENA? NAMED AFTER ME. TWICE."]
const LINES_P3 := ["STILL HANDSOME, BY THE WAY.", "I'M THE FUNNIEST ENTITY ALIVE.", "THIS IS A GREAT EPISODE."]

enum Attack { PACE, MIC_TELL, MICS, RUSH, BEAMS, WAVE_TELL, WAVE, SUMMON, GEYSER, RECOVER }

@export var arena_left: float = 80.0
@export var arena_right: float = 1600.0
@export var floor_y: float = 660.0

var phase: int = 1
var _attack: Attack = Attack.PACE
var _timer: float = 1.2
var _rush_dir: int = 1
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
		Attack.PACE:
			facing = 1 if _player.global_position.x > global_position.x else -1
			velocity.x = (130.0 + 35.0 * phase) * facing
			if _timer <= 0.0:
				_pick()
		Attack.MIC_TELL:
			velocity.x = 0.0
			if _timer <= 0.0:
				_throw_mics()
		Attack.MICS, Attack.BEAMS, Attack.SUMMON, Attack.GEYSER:
			velocity.x = 0.0
			if _timer <= 0.0:
				_set(Attack.RECOVER, 0.5)
		Attack.RUSH:
			velocity.x = (520.0 + 50.0 * phase) * _rush_dir
			if phase >= 3 and randf() < 0.12:
				_drop_slick()
			if _timer <= 0.0 or is_on_wall() \
					or global_position.x < arena_left or global_position.x > arena_right:
				_set_body_hitbox(false)
				_set(Attack.RECOVER, 0.6)
		Attack.WAVE_TELL:
			velocity.x = 0.0
			if _timer <= 0.0:
				_applause_wave()
		Attack.WAVE:
			if _timer <= 0.0:
				_set(Attack.RECOVER, 0.5)
		Attack.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
			if _timer <= 0.0:
				_set(Attack.PACE, maxf(0.35, 1.1 - 0.25 * phase))


func _pick() -> void:
	_say_line()
	var roll := randf()
	if phase >= 3 and roll < 0.3:
		_oil_geysers()
		return
	if phase >= 2 and roll < 0.5:
		_spotlight_crown()
		return
	if roll < 0.65:
		_telegraph.visible = true
		_set(Attack.MIC_TELL, 0.4)
	elif roll < 0.85 or _adds_alive >= 2:
		if phase >= 2:
			_telegraph.visible = true
			_set(Attack.WAVE_TELL, 0.4)
		else:
			_rush()
	else:
		_summon()


func _say_line() -> void:
	if randf() > 0.4:
		return
	var pool := LINES_P1
	if phase == 2:
		pool = LINES_P2
	elif phase == 3:
		pool = LINES_P3
	Juice.float_text(global_position + Vector2(0, -160), pool.pick_random(), Color(1, 0.8, 0.3))


func _throw_mics() -> void:
	_telegraph.visible = false
	var count := 1 + phase
	for i in count:
		var mic := GenericProjectile.new()
		mic.gravity = 1150.0
		mic.lift = -280.0 - 70.0 * i
		mic.speed = 310.0 + 70.0 * i
		mic.damage = 10
		mic.color = Color(0.95, 0.8, 0.25)
		mic.label_text = "GOLD"
		mic.box_size = Vector2(22, 26)
		mic.global_position = global_position + Vector2(34.0 * facing, -60.0)
		get_tree().current_scene.add_child(mic)
		mic.launch(facing)
	_set(Attack.MICS, 0.5)


func _rush() -> void:
	_rush_dir = 1 if _player.global_position.x > global_position.x else -1
	facing = _rush_dir
	_set_body_hitbox(true)
	_set(Attack.RUSH, 0.85)


func _spotlight_crown() -> void:
	var count := phase
	for i in count:
		var beam := TentacleStrike.new()
		beam.warn_time = 0.55 + 0.15 * i
		beam.active_time = 0.2
		beam.column_height = 460.0
		beam.position = Vector2(
			clampf(_player.global_position.x + _player.velocity.x * 0.35 * i,
				arena_left + 40.0, arena_right - 40.0), floor_y)
		get_tree().current_scene.add_child(beam)
	_set(Attack.BEAMS, 0.9)


func _applause_wave() -> void:
	_telegraph.visible = false
	for dir in [-1, 1]:
		var wave := GenericProjectile.new()
		wave.speed = 320.0 + 50.0 * phase
		wave.damage = 9
		wave.box_size = Vector2(32, 46)
		wave.color = Color(1, 0.85, 0.4, 0.85)
		wave.label_text = "(applause)"
		wave.lifetime = 4.0
		wave.global_position = Vector2(global_position.x + 60.0 * dir, floor_y - 36.0)
		get_tree().current_scene.add_child(wave)
		wave.launch(dir)
	_set(Attack.WAVE, 0.5)


func _summon() -> void:
	var initiate := INITIATE.instantiate()
	initiate.position = global_position + Vector2(-220.0 * facing, -40.0)
	get_tree().current_scene.add_child(initiate)
	_adds_alive += 1
	initiate.died.connect(func(_e): _adds_alive -= 1)
	Juice.float_text(global_position + Vector2(0, -160), "GET MY GUY SOME NOTES.", Color(1, 0.8, 0.3))
	_set(Attack.SUMMON, 0.6)


func _oil_geysers() -> void:
	var count := 2
	for i in count:
		var geyser := TentacleStrike.new()
		geyser.warn_time = 0.5 + 0.15 * i
		geyser.active_time = 0.25
		geyser.column_height = 420.0
		var x := clampf(_player.global_position.x + randf_range(-140.0, 140.0),
				arena_left + 50.0, arena_right - 50.0)
		geyser.position = Vector2(x, floor_y)
		get_tree().current_scene.add_child(geyser)
		# the geyser leaves a slick
		get_tree().create_timer(geyser.warn_time + 0.3).timeout.connect(
			_leave_slick.bind(Vector2(x, floor_y)))
	_set(Attack.GEYSER, 0.9)


func _leave_slick(at: Vector2) -> void:
	if _is_dead:
		return
	var slick: Node2D = OIL.new()
	slick.position = at
	get_tree().current_scene.add_child(slick)


func _drop_slick() -> void:
	var slick: Node2D = OIL.new()
	slick.width = 90.0
	slick.position = Vector2(global_position.x, floor_y)
	get_tree().current_scene.add_child(slick)


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


# ------------------------------------------------------------------ phases

func _check_phase(_amount: int, current: int) -> void:
	var ratio := float(current) / float(health.max_health)
	if phase == 1 and ratio <= 0.66:
		phase = 2
		_phase_fx("PHASE TWO. I INVENTED PHASE TWO.", Color(1, 0.85, 0.3))
		_tint(Color(1.15, 1.05, 0.85))
	elif phase == 2 and ratio <= 0.33:
		phase = 3
		_phase_fx("FINE. YOU WANT THE REAL ME? (the suit was the disguise)", Color(0.8, 0.6, 1))
		_tint(Color(0.55, 0.45, 0.65))  # the oil shows through


func _tint(color: Color) -> void:
	visual.modulate = color


func _phase_fx(line: String, color: Color) -> void:
	Juice.hitstop(0.25, 0.02)
	Juice.shake(10.0)
	Juice.float_text(global_position + Vector2(0, -170), line, color)
	_set_body_hitbox(false)
	_telegraph.visible = false
	_set(Attack.RECOVER, 1.0)


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
	died.emit(self)
	DialogueSystem.start([
		{"speaker": "TUFF TIDDY", "text": "You don't GET it. I MADE this industry. Every laugh for thirty years had my fingerprints on it."},
		{"speaker": "DA'HERM", "text": "That's why none of them were real."},
		{"speaker": "TUFF TIDDY", "text": "(dissolving) ...one question. Be honest. Comic to comic."},
		{"speaker": "TUFF TIDDY", "text": "...Was I ever funny?"},
		{"speaker": "DA'HERM", "text": "No. But you were ridiculous. That's almost something."},
	])
	DialogueSystem.finished.connect(_finish, CONNECT_ONE_SHOT)


func _finish() -> void:
	boss_defeated.emit()
	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 1.6)
	tween.tween_callback(queue_free)


func _find_player() -> Player:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] as Player if not nodes.is_empty() else null
