# the_special.gd
# BOSS 23: THE SPECIAL (05_BOSS_BIBLE)
# Theme: Manufactured Fame. "Manifestation of manufactured fame."
#
# A comedy special with no comedian in it: a floating screen-thing
# that runs LAUGH TRACKS (ground waves of canned "HA HA HA"), fires
# CLIP MONTAGES (aimed shots labeled like marketing), and RERUNS
# itself (teleports to your flank and plays the same bit again).
# Reward: the FINAL PERFECT JOKE FRAGMENT.

class_name TheSpecial
extends EnemyBase

signal boss_defeated

enum Attack { HOVER, LAUGH_TRACK, CLIP_TELL, CLIPS, RERUN, RECOVER }

@export var arena_left: float = 100.0
@export var arena_right: float = 1400.0

var phase: int = 1
var _attack: Attack = Attack.HOVER
var _timer: float = 1.0
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
		Attack.HOVER:
			facing = 1 if _player.global_position.x > global_position.x else -1
			var target := Vector2(
				clampf(_player.global_position.x - 220.0 * facing, arena_left + 80.0, arena_right - 80.0),
				430.0 + sin(Time.get_ticks_msec() * 0.002) * 18.0)
			velocity = (target - global_position).normalized() * minf(150.0, (target - global_position).length() * 2.0)
			if _timer <= 0.0:
				_pick()
		Attack.LAUGH_TRACK:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_fire_laugh_track()
		Attack.CLIP_TELL:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_fire_clips()
		Attack.CLIPS:
			if _timer <= 0.0:
				_set(Attack.RECOVER, 0.5)
		Attack.RERUN:
			if _timer <= 0.0:
				_do_rerun()
		Attack.RECOVER:
			velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
			if _timer <= 0.0:
				_set(Attack.HOVER, maxf(0.45, 1.1 - 0.22 * phase))


func _pick() -> void:
	var roll := randf()
	if roll < 0.4:
		_telegraph.visible = true
		_set(Attack.LAUGH_TRACK, 0.45)
	elif roll < 0.75:
		_telegraph.visible = true
		_set(Attack.CLIP_TELL, 0.4)
	else:
		Juice.float_text(global_position + Vector2(0, -120), "NOW STREAMING. AGAIN.", Color(1, 0.6, 0.6))
		_set(Attack.RERUN, 0.5)


func _fire_laugh_track() -> void:
	_telegraph.visible = false
	for dir in [-1, 1]:
		var wave := GenericProjectile.new()
		wave.speed = 300.0 + 55.0 * phase
		wave.damage = 9
		wave.box_size = Vector2(34, 46)
		wave.color = Color(1, 0.55, 0.55, 0.85)
		wave.label_text = "HA HA HA"
		wave.lifetime = 4.0
		wave.global_position = Vector2(global_position.x + 60.0 * dir, 624.0)
		get_tree().current_scene.add_child(wave)
		wave.launch(dir)
	_set(Attack.RECOVER, 0.55)


func _fire_clips() -> void:
	_telegraph.visible = false
	var labels := ["BEST OF", "VIRAL", "MUST SEE", "97% FRESH"]
	var count := 1 + phase
	for i in count:
		var clip := GenericProjectile.new()
		clip.speed = 380.0 + 40.0 * i
		clip.damage = 8
		clip.color = Color(0.95, 0.4, 0.45)
		clip.label_text = labels[i % labels.size()]
		clip.box_size = Vector2(28, 18)
		clip.lifetime = 3.5
		clip.global_position = global_position + Vector2(0, -10.0 + 22.0 * i)
		get_tree().current_scene.add_child(clip)
		var aim := (_player.global_position - clip.global_position).normalized()
		clip.launch_vector(aim * clip.speed)
	_set(Attack.CLIPS, 0.5)


func _do_rerun() -> void:
	# teleport to the player's flank and run the bit again
	var side := -1 if randf() < 0.5 else 1
	global_position = Vector2(
		clampf(_player.global_position.x + 240.0 * side, arena_left + 80.0, arena_right - 80.0),
		420.0)
	Juice.shake(3.0)
	_telegraph.visible = true
	_set(Attack.LAUGH_TRACK, 0.4)


func _set(attack: Attack, time: float) -> void:
	_attack = attack
	_timer = time


func _check_phase(_amount: int, current: int) -> void:
	var ratio := float(current) / float(health.max_health)
	if phase == 1 and ratio <= 0.66:
		phase = 2
		_phase_fx("EXTENDED CUT.")
	elif phase == 2 and ratio <= 0.33:
		phase = 3
		_phase_fx("DIRECTOR'S CUT. THE DIRECTOR IS NOBODY.")


func _phase_fx(line: String) -> void:
	Juice.hitstop(0.2, 0.02)
	Juice.shake(8.0)
	Juice.float_text(global_position + Vector2(0, -140), line, Color(1, 0.55, 0.55))
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
		{"speaker": "THE SPECIAL", "text": "FOUR QUADRANT APPEAL... AUDIENCE SCORE 97%... CERTIFIED..."},
		{"speaker": "DA'HERM", "text": "Nobody laughed. Not once. I was listening."},
		{"speaker": "THE SPECIAL", "text": "LAUGHTER... NOT FOUND IN METADATA... what... what was it for, then..."},
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
