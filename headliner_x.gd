# hack_master_general.gd
# BOSS 17: HACK MASTER GENERAL (05_BOSS_BIBLE)
# Theme: Stolen Material. "Collector of stolen jokes."
#
# The concept IS the mechanic: he steals.
#   - His attack pool is built from YOUR weapons_owned at fight start
#     (chair arcs if you found the chair, a mic rush if you took the
#     Pod Mic, chicken chaos if you grabbed the chicken).
#   - His catchphrases are other bosses' lines, delivered wrong:
#     "BALL DON'T LIE." "CAN WE CLIP THAT?" "GOLDEN HOUR, PEOPLE."
#     He has never said an original thing in his life.
# Reward: THE HACK costume.

class_name HackMasterGeneral
extends EnemyBase

signal boss_defeated

const STOLEN_LINES := [
	"BALL DON'T LIE.",          # the King's
	"CAN WE CLIP THAT?",        # Carl's
	"GOLDEN HOUR, PEOPLE.",     # the Queen's
	"PER MY LAST EMAIL—",       # Brandon's
	"AND WE'RE BACK.",          # the Pod Father's
	"TRUST ME.",                # ...that one stings
]

enum Attack { PACE, STEAL_TELL, NOTEBOOKS, CHAIR, MIC_RUSH, CHICKEN, RECOVER }

@export var arena_left: float = 80.0
@export var arena_right: float = 1600.0

var phase: int = 1
var _attack: Attack = Attack.PACE
var _timer: float = 1.0
var _rush_dir: int = 1
var _stolen_pool: Array = []
var _player: Player

@onready var _telegraph: ColorRect = $Visual/Telegraph


func _ready() -> void:
	super()
	health.damaged.connect(_check_phase)
	_telegraph.visible = false
	# build the set list from the player's own inventory
	_stolen_pool = ["notebooks"]
	if GameState.weapons_owned.has("folding_chair"):
		_stolen_pool.append("chair")
	if GameState.weapons_owned.has("pod_mic"):
		_stolen_pool.append("mic_rush")
	if GameState.weapons_owned.has("rubber_chicken"):
		_stolen_pool.append("chicken")


func _ai(delta: float) -> void:
	_player = _find_player()
	if _player == null:
		return
	_timer -= delta
	match _attack:
		Attack.PACE:
			facing = 1 if _player.global_position.x > global_position.x else -1
			velocity.x = (130.0 + 30.0 * phase) * facing
			if _timer <= 0.0:
				_telegraph.visible = true
				_set(Attack.STEAL_TELL, 0.4)
		Attack.STEAL_TELL:
			velocity.x = 0.0
			if _timer <= 0.0:
				_perform_stolen_bit()
		Attack.NOTEBOOKS, Attack.CHAIR, Attack.CHICKEN:
			velocity.x = 0.0
			if _timer <= 0.0:
				_set(Attack.RECOVER, 0.5)
		Attack.MIC_RUSH:
			velocity.x = (540.0 + 40.0 * phase) * _rush_dir
			if _timer <= 0.0 or is_on_wall() \
					or global_position.x < arena_left or global_position.x > arena_right:
				_set_body_hitbox(false)
				_set(Attack.RECOVER, 0.6)
		Attack.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
			if _timer <= 0.0:
				_set(Attack.PACE, maxf(0.4, 1.1 - 0.22 * phase))


func _perform_stolen_bit() -> void:
	_telegraph.visible = false
	if randf() < 0.55:
		Juice.float_text(global_position + Vector2(0, -150), STOLEN_LINES.pick_random(), Color(0.8, 0.7, 0.95))
	match _stolen_pool.pick_random():
		"notebooks":
			var count := 2 + phase
			for i in count:
				var book := GenericProjectile.new()
				book.gravity = 1050.0
				book.lift = -240.0 - 70.0 * i
				book.speed = 280.0 + 80.0 * i
				book.damage = 8
				book.color = Color(0.8, 0.75, 0.6)
				book.label_text = "HEARD IT"
				book.box_size = Vector2(22, 16)
				book.global_position = global_position + Vector2(30.0 * facing, -46.0)
				get_tree().current_scene.add_child(book)
				book.launch(facing)
			_set(Attack.NOTEBOOKS, 0.5)
		"chair":
			var chair := GenericProjectile.new()
			chair.gravity = 1300.0
			chair.lift = -420.0
			chair.speed = 330.0
			chair.damage = 13
			chair.color = Color(0.5, 0.34, 0.2)
			chair.label_text = "(yours)"
			chair.box_size = Vector2(40, 40)
			chair.global_position = global_position + Vector2(30.0 * facing, -60.0)
			get_tree().current_scene.add_child(chair)
			chair.launch(facing)
			_set(Attack.CHAIR, 0.5)
		"mic_rush":
			_rush_dir = 1 if _player.global_position.x > global_position.x else -1
			facing = _rush_dir
			_set_body_hitbox(true)
			_set(Attack.MIC_RUSH, 0.8)
		"chicken":
			for i in 2 + phase:
				var bird := GenericProjectile.new()
				bird.gravity = 1100.0
				bird.lift = randf_range(-520.0, -260.0)
				bird.speed = randf_range(180.0, 420.0)
				bird.damage = 7
				bird.color = Color(0.95, 0.85, 0.3)
				bird.label_text = "BAWK"
				bird.box_size = Vector2(24, 20)
				bird.global_position = global_position + Vector2(20.0 * facing, -50.0)
				get_tree().current_scene.add_child(bird)
				bird.launch(facing if randf() < 0.8 else -facing)
			_set(Attack.CHICKEN, 0.6)


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
		_phase_fx("OK, NEW MATERIAL. (it is not new material)")
	elif phase == 2 and ratio <= 0.33:
		phase = 3
		_phase_fx("THIS NEXT BIT KILLED IN '09. FOR SOMEBODY.")


func _phase_fx(line: String) -> void:
	Juice.hitstop(0.2, 0.02)
	Juice.shake(8.0)
	Juice.float_text(global_position + Vector2(0, -160), line, Color(0.8, 0.7, 0.95))
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
	died.emit(self)
	DialogueSystem.start([
		{"speaker": "HACK MASTER GENERAL", "text": "Wait— wait. Use the bit about the raccoon. It's a good bit. It could be OUR bit."},
		{"speaker": "DA'HERM", "text": "Write your own raccoon."},
		{"speaker": "HACK MASTER GENERAL", "text": "...I don't know how. I never knew how. Take the coat. At least the coat was always mine."},
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
