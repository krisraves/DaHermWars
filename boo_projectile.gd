# ravager_prime.gd
# FINAL BOSS: SUPREME BEING: RAVAGER PRIME (05_BOSS_BIBLE)
# Theme: What Da'Herm Could Have Become.
# RULE 7: Raves is never pure evil. Sympathetic. Understandable.
# Design rule: the player should leave thinking
# "That could have been Da'Herm."
#
# PHASE 1 - RAVES SUPREME: human-scale, fast, charismatic. Dash
#   combos, thrown mics, "TRUST ME."
# PHASE 2 - RAVES ASCENDANT: the follower halo ignites - radial orb
#   volleys, FAN CAM summons, applause waves, spotlights.
# PHASE 3 - SUPREME BEING: sponsor logos orbit his body; spotlights
#   hunt; and the audience claps IN RHYTHM (12_AUDIO_BIBLE: "the
#   clapping becomes percussion") - an arena-wide floor slam on a
#   metronome. Not physically monstrous. Spiritually monstrous.

class_name RavagerPrime
extends EnemyBase

signal boss_defeated
signal phase_three

const FAN_CAM := preload("res://scenes/enemies/camera_drone.tscn")

const LINES_P1 := ["TRUST ME.", "WE'RE GONNA BE RICH— I'M gonna be rich.", "THIS IS MY ROOM NOW, D."]
const LINES_P2 := ["THEY ALL FOLLOWED ME.", "CAN YOU HEAR IT? THEY LOVE ME.", "(you should've come with me)"]
const LINES_P3 := ["I AM THE HEADLINER.", "APPLAUSE IS FOREVER.", "(it's so loud up here, man)"]

enum Attack { PACE, RUSH_TELL, RUSH, MIC_TELL, MICS, HALO, BEAMS, SUMMON, WAVE_TELL, WAVE, RECOVER }

@export var arena_left: float = 120.0
@export var arena_right: float = 1900.0
@export var floor_y: float = 660.0

var phase: int = 1
var _attack: Attack = Attack.PACE
var _timer: float = 1.4
var _rush_dir: int = 1
var _adds_alive: int = 0
var _player: Player

# the applause metronome (phase 3)
const CLAP_PERIOD := 3.2
const CLAP_WARN := 0.8
var _clap_timer: float = CLAP_PERIOD
var _clap_warned: bool = false

# orbiting sponsor logos (phase 3)
var _logos: Array[Node2D] = []
var _logo_angle: float = 0.0

@onready var _telegraph: ColorRect = $Visual/Telegraph
@onready var _halo: ColorRect = $Visual/Halo


func _ready() -> void:
	super()
	health.damaged.connect(_check_phase)
	_telegraph.visible = false
	_halo.visible = false


func _ai(delta: float) -> void:
	_player = _find_player()
	if _player == null:
		return
	_timer -= delta
	if phase >= 3:
		_run_applause_metronome(delta)
		_spin_logos(delta)
	match _attack:
		Attack.PACE:
			facing = 1 if _player.global_position.x > global_position.x else -1
			velocity.x = (170.0 + 45.0 * phase) * facing
			if _timer <= 0.0:
				_pick()
		Attack.RUSH_TELL, Attack.MIC_TELL, Attack.WAVE_TELL:
			velocity.x = 0.0
			if _timer <= 0.0:
				match _attack:
					Attack.RUSH_TELL: _do_rush()
					Attack.MIC_TELL: _throw_mics()
					Attack.WAVE_TELL: _applause_wave()
		Attack.RUSH:
			velocity.x = (600.0 + 40.0 * phase) * _rush_dir
			if _timer <= 0.0 or is_on_wall() \
					or global_position.x < arena_left or global_position.x > arena_right:
				_set_body_hitbox(false)
				_set(Attack.RECOVER, 0.55)
		Attack.MICS, Attack.HALO, Attack.BEAMS, Attack.SUMMON, Attack.WAVE:
			velocity.x = 0.0
			if _timer <= 0.0:
				_set(Attack.RECOVER, 0.45)
		Attack.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
			if _timer <= 0.0:
				_set(Attack.PACE, maxf(0.3, 1.0 - 0.22 * phase))


func _pick() -> void:
	_say_line()
	var roll := randf()
	if phase >= 2 and roll < 0.28:
		_halo_volley()
		return
	if phase >= 2 and roll < 0.45 and _adds_alive < 2:
		_summon_fan_cam()
		return
	if phase >= 2 and roll < 0.62:
		_spotlights()
		return
	if roll < 0.5:
		_telegraph.visible = true
		_set(Attack.RUSH_TELL, 0.35)
	elif roll < 0.8:
		_telegraph.visible = true
		_set(Attack.MIC_TELL, 0.4)
	else:
		_telegraph.visible = true
		_set(Attack.WAVE_TELL, 0.4)


func _say_line() -> void:
	if randf() > 0.35:
		return
	var pool := LINES_P1
	if phase == 2:
		pool = LINES_P2
	elif phase == 3:
		pool = LINES_P3
	Juice.float_text(global_position + Vector2(0, -170), pool.pick_random(), Color(0.6, 0.9, 1))


# ------------------------------------------------------------- attacks

func _do_rush() -> void:
	_telegraph.visible = false
	_rush_dir = 1 if _player.global_position.x > global_position.x else -1
	facing = _rush_dir
	_set_body_hitbox(true)
	_set(Attack.RUSH, 0.7)


func _throw_mics() -> void:
	_telegraph.visible = false
	var count := 2 + phase
	for i in count:
		var mic := GenericProjectile.new()
		mic.gravity = 1100.0
		mic.lift = -260.0 - 80.0 * i
		mic.speed = 330.0 + 65.0 * i
		mic.damage = 10
		mic.color = Color(0.3, 0.7, 1)
		mic.label_text = "MIC"
		mic.box_size = Vector2(20, 24)
		mic.global_position = global_position + Vector2(30.0 * facing, -70.0)
		get_tree().current_scene.add_child(mic)
		mic.launch(facing)
	_set(Attack.MICS, 0.5)


func _halo_volley() -> void:
	# the follower halo fires outward in a ring - gaps to dodge through
	var count := 8
	for i in count:
		var angle := TAU * float(i) / float(count) + (0.4 if phase >= 3 else 0.0)
		var orb := GenericProjectile.new()
		orb.speed = 270.0 + 30.0 * phase
		orb.damage = 9
		orb.color = Color(0.55, 0.85, 1)
		orb.label_text = "+1"
		orb.box_size = Vector2(18, 18)
		orb.lifetime = 3.0
		orb.global_position = global_position + Vector2(0, -60)
		get_tree().current_scene.add_child(orb)
		orb.launch_vector(Vector2(cos(angle), sin(angle)) * orb.speed)
	Juice.float_text(global_position + Vector2(0, -150), "(the halo flares)", Color(0.7, 0.9, 1))
	_set(Attack.HALO, 0.7)


func _spotlights() -> void:
	var count := 1 + phase
	for i in count:
		var beam := TentacleStrike.new()
		beam.warn_time = 0.5 + 0.14 * i
		beam.active_time = 0.2
		beam.column_height = 480.0
		beam.position = Vector2(
			clampf(_player.global_position.x + _player.velocity.x * 0.3 * i,
				arena_left + 40.0, arena_right - 40.0), floor_y)
		get_tree().current_scene.add_child(beam)
	_set(Attack.BEAMS, 0.85)


func _summon_fan_cam() -> void:
	var cam := FAN_CAM.instantiate()
	cam.position = global_position + Vector2(-200.0 * facing, -180.0)
	get_tree().current_scene.add_child(cam)
	_adds_alive += 1
	cam.died.connect(func(_e): _adds_alive -= 1)
	Juice.float_text(cam.position + Vector2(0, -60), "FAN CAM", Color(0.6, 0.9, 1))
	_set(Attack.SUMMON, 0.5)


func _applause_wave() -> void:
	_telegraph.visible = false
	for dir in [-1, 1]:
		var wave := GenericProjectile.new()
		wave.speed = 340.0 + 45.0 * phase
		wave.damage = 9
		wave.box_size = Vector2(30, 48)
		wave.color = Color(0.7, 0.85, 1, 0.85)
		wave.label_text = "(applause)"
		wave.lifetime = 4.5
		wave.global_position = Vector2(global_position.x + 55.0 * dir, floor_y - 38.0)
		get_tree().current_scene.add_child(wave)
		wave.launch(dir)
	_set(Attack.WAVE, 0.5)


# --------------------------------------------- phase 3: the percussion

func _run_applause_metronome(delta: float) -> void:
	_clap_timer -= delta
	if not _clap_warned and _clap_timer <= CLAP_WARN:
		_clap_warned = true
		Juice.float_text(Vector2((arena_left + arena_right) * 0.5, floor_y - 320.0),
				"C L A P", Color(1, 0.95, 0.7))
		Juice.shake(2.0)
	if _clap_timer <= 0.0:
		_clap_timer = CLAP_PERIOD
		_clap_warned = false
		_arena_clap()


func _arena_clap() -> void:
	# arena-wide floor slam. Be airborne on the beat or take the hit.
	Juice.shake(7.0)
	var slam := Hitbox.new()
	slam.collision_layer = 32
	slam.collision_mask = 64
	slam.damage = 11
	slam.knockback_strength = 260.0
	slam.knockback_lift = -420.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(arena_right - arena_left, 64)
	shape.shape = rect
	slam.add_child(shape)
	slam.position = Vector2((arena_left + arena_right) * 0.5, floor_y - 32.0)
	get_tree().current_scene.add_child(slam)
	var burst := ColorRect.new()
	burst.size = Vector2(arena_right - arena_left, 56)
	burst.position = Vector2(arena_left, floor_y - 56.0)
	burst.color = Color(1, 0.95, 0.7, 0.5)
	get_tree().current_scene.add_child(burst)
	get_tree().create_timer(0.16).timeout.connect(func():
		slam.queue_free()
		burst.queue_free())


func _spin_logos(delta: float) -> void:
	_logo_angle += delta * 2.2
	for i in _logos.size():
		var node := _logos[i]
		var angle := _logo_angle + TAU * float(i) / float(_logos.size())
		node.position = Vector2(cos(angle), sin(angle)) * 140.0 + Vector2(0, -50)


func _ignite_logos() -> void:
	for i in 3:
		var logo := Node2D.new()
		var face := ColorRect.new()
		face.size = Vector2(34, 34)
		face.position = Vector2(-17, -17)
		face.color = Color(0.9, 0.85, 0.8)
		logo.add_child(face)
		var mark := Label.new()
		mark.text = "®"
		mark.position = Vector2(-8, -14)
		mark.add_theme_font_size_override("font_size", 18)
		mark.add_theme_color_override("font_color", Color(0.1, 0.1, 0.12))
		logo.add_child(mark)
		var hitbox := Hitbox.new()
		hitbox.collision_layer = 32
		hitbox.collision_mask = 64
		hitbox.damage = 8
		hitbox.knockback_strength = 280.0
		hitbox.knockback_lift = -200.0
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(38, 38)
		shape.shape = rect
		hitbox.add_child(shape)
		logo.add_child(hitbox)
		add_child(logo)
		_logos.append(logo)


# ------------------------------------------------------------- phases

func _check_phase(_amount: int, current: int) -> void:
	var ratio := float(current) / float(health.max_health)
	if phase == 1 and ratio <= 0.66:
		phase = 2
		_halo.visible = true
		_phase_fx("(the halo ignites - a crown of everyone who ever followed him)")
	elif phase == 2 and ratio <= 0.33:
		phase = 3
		_ignite_logos()
		visual.modulate = Color(1.1, 1.15, 1.3)
		_phase_fx("")
		phase_three.emit()  # the arena handles the mid-fight scene


func _phase_fx(line: String) -> void:
	Juice.hitstop(0.25, 0.02)
	Juice.shake(10.0)
	if line != "":
		Juice.float_text(global_position + Vector2(0, -180), line, Color(0.7, 0.9, 1))
	_set_body_hitbox(false)
	_telegraph.visible = false
	_set(Attack.RECOVER, 1.1)


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
	for logo in _logos:
		logo.queue_free()
	_logos.clear()
	_halo.visible = false
	visual.modulate = Color(1, 1, 1)  # human again
	died.emit(self)
	DialogueSystem.start([
		{"speaker": "RAVES", "text": "(the halo gutters out) ...the room's so quiet."},
		{"speaker": "DA'HERM", "text": "First honest crowd you've ever had."},
		{"speaker": "RAVES", "text": "I just wanted to be somebody, man."},
		{"speaker": "DA'HERM", "text": "You were. You were my guy. That was already somebody."},
		{"speaker": "RAVES", "text": "...That's a terrible closer."},
		{"speaker": "DA'HERM", "text": "Yeah. You want to fix it? Takes about thirty years of open mics."},
		{"speaker": "RAVES", "text": "(a weak laugh - a real one) ...one more set."},
	])
	DialogueSystem.finished.connect(_finish, CONNECT_ONE_SHOT)


func _finish() -> void:
	boss_defeated.emit()
	# Raves doesn't dissolve. He sits down at the edge of the stage,
	# human-sized, and stays there. (RULE 7. He lives.)
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y + 8.0, 0.8)


func _find_player() -> Player:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] as Player if not nodes.is_empty() else null
