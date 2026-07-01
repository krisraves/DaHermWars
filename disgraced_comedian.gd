# headliner_x.gd
# BOSS 19: HEADLINER X (05_BOSS_BIBLE)
# Theme: Forgotten Greatness. "The ghost of a comic who almost made it."
#
# A ghost fight: he FADES (intangible, untouchable, drifting) and
# MANIFESTS (solid, attackable, dangerous). The spotlight that never
# found him in life hunts the player instead - sweeping light columns.
# His echoes are bits nobody remembers ("...and THAT'S marriage!").
# Reward: PERFECT JOKE FRAGMENT - and a line of its mythology.

class_name HeadlinerX
extends EnemyBase

signal boss_defeated

enum Attack { MANIFEST, ECHOES, FADE_OUT, DRIFT, SPOTLIGHTS, FADE_IN, RECOVER }

@export var arena_left: float = 120.0
@export var arena_right: float = 1500.0

var phase: int = 1
var _attack: Attack = Attack.MANIFEST
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
		Attack.MANIFEST:
			facing = 1 if _player.global_position.x > global_position.x else -1
			velocity.x = 100.0 * facing
			if _timer <= 0.0:
				if randf() < 0.55:
					_telegraph.visible = true
					_set(Attack.ECHOES, 0.4)
				else:
					_start_fade()
		Attack.ECHOES:
			velocity.x = 0.0
			if _timer <= 0.0:
				_throw_echoes()
		Attack.FADE_OUT:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_set(Attack.DRIFT, 1.0)
		Attack.DRIFT:
			# intangible: drift through the air toward a new mark
			var target := _player.global_position + Vector2(randf_range(-260.0, 260.0), -160.0)
			global_position = global_position.move_toward(target, 240.0 * delta)
			if _timer <= 0.0:
				_cast_spotlights()
		Attack.SPOTLIGHTS:
			if _timer <= 0.0:
				_end_fade()
		Attack.FADE_IN:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_set(Attack.RECOVER, 0.4)
		Attack.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
			if _timer <= 0.0:
				_set(Attack.MANIFEST, maxf(0.5, 1.2 - 0.22 * phase))


func _throw_echoes() -> void:
	_telegraph.visible = false
	var lines := ["...AND THAT'S MARRIAGE!", "AIRLINE FOOD, AM I RIGHT", "(polite applause)", "TIP YOUR WAITSTAFF"]
	var count := 1 + phase
	for i in count:
		var echo := GenericProjectile.new()
		echo.speed = 340.0 + 50.0 * i
		echo.damage = 9
		echo.color = Color(0.7, 0.75, 0.9, 0.8)
		echo.label_text = lines.pick_random()
		echo.box_size = Vector2(26, 20)
		echo.lifetime = 3.5
		echo.global_position = global_position + Vector2(26.0 * facing, -40.0 + 26.0 * i)
		get_tree().current_scene.add_child(echo)
		var aim := (_player.global_position - echo.global_position).normalized()
		echo.launch_vector(aim * echo.speed)
	_set(Attack.RECOVER, 0.55)


func _start_fade() -> void:
	# intangible: can't be hit, can't hit you - but the lights can
	hurtbox.set_deferred("monitorable", false)
	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 0.35, 0.4)
	Juice.float_text(global_position + Vector2(0, -150), "(he was here a second ago)", Color(0.7, 0.75, 0.9))
	_set(Attack.FADE_OUT, 0.45)


func _cast_spotlights() -> void:
	# the spotlight that never found him: it hunts you instead
	var count := phase
	for i in count:
		var beam := TentacleStrike.new()
		beam.warn_time = 0.6 + 0.18 * i
		beam.active_time = 0.22
		beam.column_height = 460.0
		beam.position = Vector2(
			clampf(_player.global_position.x + _player.velocity.x * 0.3 * i,
				arena_left, arena_right), 660.0)
		get_tree().current_scene.add_child(beam)
	_set(Attack.SPOTLIGHTS, 0.8 + 0.2 * count)


func _end_fade() -> void:
	hurtbox.set_deferred("monitorable", true)
	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 1.0, 0.35)
	_set(Attack.FADE_IN, 0.4)


func _set(attack: Attack, time: float) -> void:
	_attack = attack
	_timer = time


func _check_phase(_amount: int, current: int) -> void:
	var ratio := float(current) / float(health.max_health)
	if phase == 1 and ratio <= 0.66:
		phase = 2
		_phase_fx("YOU SHOULD'VE SEEN THE '94 SET.")
	elif phase == 2 and ratio <= 0.33:
		phase = 3
		_phase_fx("ONE MORE. I JUST NEED ONE MORE.")


func _phase_fx(line: String) -> void:
	Juice.hitstop(0.2, 0.02)
	Juice.shake(8.0)
	Juice.float_text(global_position + Vector2(0, -160), line, Color(0.7, 0.75, 0.9))
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
		{"speaker": "HEADLINER X", "text": "One more set. I was one set away."},
		{"speaker": "DA'HERM", "text": "From what?"},
		{"speaker": "HEADLINER X", "text": "...I don't remember anymore. Maybe that was the joke."},
		{"speaker": "HEADLINER X", "text": "There's a piece of something under the stage. I held onto it for forty years and never once understood it. It's yours. Understand it for me."},
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
