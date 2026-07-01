# the_crowd.gd
# BOSS 18: THE CROWD (05_BOSS_BIBLE)
# Theme: Group Psychology. "Audience itself becomes boss."
#
# The game's first boss that violence barely touches:
#   - Direct attacks deal 1 damage and trigger BACKLASH ("BOO.")
#   - The STAGE MIC in the arena is the real weapon: grab it, do a
#     bit, and the room softens (-45 "TOUGH ROOM" meter) and goes
#     quiet for a moment.
# Between bits: thrown bottles and boo-waves. Winning them over IS
# the fight. Reward: EMPATHY FRAGMENT (required for the True Ending).

class_name TheCrowd
extends EnemyBase

signal boss_defeated

const BIT_DAMAGE := 45
const PACIFY_TIME := 3.0

enum Mood { HOSTILE, PACIFIED }

@export var arena_left: float = 100.0
@export var arena_right: float = 1300.0

var phase: int = 1
var _mood: Mood = Mood.HOSTILE
var _mood_timer: float = 0.0
var _attack_timer: float = 1.5
var _player: Player


func _ready() -> void:
	super()
	health.damaged.connect(_check_phase)


func _ai(delta: float) -> void:
	velocity = Vector2.ZERO  # the crowd is the room; the room doesn't move
	_player = _find_player()
	if _player == null:
		return
	if _mood == Mood.PACIFIED:
		_mood_timer -= delta
		if _mood_timer <= 0.0:
			_mood = Mood.HOSTILE
			Juice.float_text(global_position + Vector2(0, -120), "(they're getting restless)", Color(0.8, 0.8, 0.85))
		return
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = maxf(0.9, 2.2 - 0.4 * phase)
		if randf() < 0.55:
			_throw_bottles()
		else:
			_boo_wave()


func _throw_bottles() -> void:
	var count := 1 + phase
	for i in count:
		var bottle := GenericProjectile.new()
		bottle.speed = 0.0
		bottle.gravity = 1500.0
		bottle.damage = 8
		bottle.color = Color(0.4, 0.6, 0.35)
		bottle.label_text = "(bottle)"
		bottle.box_size = Vector2(14, 28)
		bottle.lifetime = 3.0
		bottle.global_position = Vector2(
			clampf(_player.global_position.x + randf_range(-160.0, 160.0),
				arena_left, arena_right), 60.0)
		get_tree().current_scene.add_child(bottle)
		bottle.launch_vector(Vector2(randf_range(-40.0, 40.0), 60.0))


func _boo_wave() -> void:
	for dir in [-1, 1]:
		var wave := GenericProjectile.new()
		wave.speed = 280.0 + 50.0 * phase
		wave.damage = 7
		wave.box_size = Vector2(30, 44)
		wave.color = Color(0.75, 0.3, 0.3, 0.85)
		wave.label_text = "BOOOO"
		wave.lifetime = 4.0
		wave.global_position = Vector2(global_position.x + 80.0 * dir, 624.0)
		get_tree().current_scene.add_child(wave)
		wave.launch(dir)


# ------------------------------------------------------------------ the mic

func on_performed(bit_line: String) -> void:
	# the stage mic calls this: a real set, real damage
	Juice.float_text(_player.global_position + Vector2(0, -90) if _player != null \
			else global_position, bit_line, Color(1, 0.85, 0.4))
	health.take_damage(BIT_DAMAGE)
	_flash()
	Juice.hitstop(0.1, 0.05)
	Juice.shake(4.0)
	Juice.float_text(global_position + Vector2(0, -130), "(...laughter. actual laughter.)", Color(1, 0.9, 0.6))
	_mood = Mood.PACIFIED
	_mood_timer = PACIFY_TIME


func _on_hit_received(hitbox: Hitbox) -> void:
	# punching an audience has never once worked
	if _is_dead:
		return
	health.take_damage(1)
	_flash()
	Juice.float_text(global_position + Vector2(0, -130), "BOO.", Color(0.85, 0.4, 0.4))
	if _mood == Mood.HOSTILE:
		_throw_bottles()  # backlash


func _check_phase(_amount: int, current: int) -> void:
	var ratio := float(current) / float(health.max_health)
	if phase == 1 and ratio <= 0.66:
		phase = 2
		Juice.float_text(global_position + Vector2(0, -150), "(a few of them are leaning in)", Color(0.9, 0.9, 0.95))
	elif phase == 2 and ratio <= 0.33:
		phase = 3
		Juice.float_text(global_position + Vector2(0, -150), "(somebody just shushed a heckler)", Color(0.9, 0.9, 0.95))


func _on_died() -> void:
	_is_dead = true
	hurtbox.set_deferred("monitorable", false)
	died.emit(self)
	DialogueSystem.start([
		{"speaker": "THE CROWD", "text": "...one more! ONE MORE!"},
		{"speaker": "DA'HERM", "text": "That's the first time that word didn't scare me."},
		{"speaker": "", "text": "(They're not clapping because they're supposed to. That's the whole difference.)"},
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
