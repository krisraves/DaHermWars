# king_crossover.gd
# BOSS 05: KING CROSSOVER (05_BOSS_BIBLE / BOSS_DATABASE)
# Theme: Ego. "Streetball legend. Possibly invented basketball."
#
# PHASE 1 - THE WARMUP: dribble charges, chest-pass basketballs.
# PHASE 2 - RIM LAUNCHES: rises to the rim, dunks on the player's
#   position (marker telegraph), bouncing balls flood the court.
# PHASE 3 - GAME POINT: everything, faster, trash talk constant.
# Reward: AIR CROSSOVER (double jump) - he teaches you the move
# the only way he knows how: by losing.

class_name KingCrossover
extends EnemyBase

signal boss_defeated

const TRASH_TALK := ["YOU CAN'T GUARD ME.", "AND-ONE.", "BALL DON'T LIE.", "GET THAT OUTTA HERE."]

enum Attack { PACE, CHARGE_TELL, CHARGE, PASS, RISE, HANG, DUNK, LAND, RECOVER }

@export var arena_left: float = 80.0
@export var arena_right: float = 1750.0

var phase: int = 1
var _attack: Attack = Attack.PACE
var _timer: float = 0.8
var _charge_dir: int = 1
var _dunk_marker: ColorRect = null
var _player: Player

@onready var _body_hitbox: Hitbox = $BodyHitbox
@onready var _body_shape: CollisionShape2D = $BodyHitbox/Shape
@onready var _telegraph: ColorRect = $Visual/Telegraph


func _ready() -> void:
	super()
	health.damaged.connect(_check_phase)
	_set_body_hitbox(false)
	_telegraph.visible = false


func _ai(delta: float) -> void:
	_player = _find_player()
	if _player == null:
		return
	_timer -= delta
	match _attack:
		Attack.PACE:
			facing = 1 if _player.global_position.x > global_position.x else -1
			velocity.x = (150.0 + 40.0 * phase) * facing
			if _timer <= 0.0:
				_pick_attack()
		Attack.CHARGE_TELL:
			velocity.x = 0.0
			if _timer <= 0.0:
				_begin_charge()
		Attack.CHARGE:
			velocity.x = (520.0 + 60.0 * phase) * _charge_dir
			if _timer <= 0.0 or is_on_wall() \
					or global_position.x < arena_left or global_position.x > arena_right:
				_set_body_hitbox(false)
				_set(Attack.RECOVER, 0.7)
		Attack.PASS:
			velocity.x = 0.0
			if _timer <= 0.0:
				_chest_pass()
		Attack.RISE:
			velocity = Vector2(0, -900)
			if global_position.y < -150.0:
				velocity = Vector2.ZERO
				_set(Attack.HANG, 0.55)
				_show_dunk_marker()
		Attack.HANG:
			velocity = Vector2.ZERO
			global_position.x = move_toward(global_position.x, _player.global_position.x, 600.0 * delta)
			_move_marker()
			if _timer <= 0.0:
				_set(Attack.DUNK, 2.0)
				_set_body_hitbox(true)
		Attack.DUNK:
			velocity = Vector2(0, 1500)
			if is_on_floor():
				_land_dunk()
		Attack.LAND:
			velocity.x = 0.0
			if _timer <= 0.0:
				_set(Attack.RECOVER, 0.6)
		Attack.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
			if _timer <= 0.0:
				_set(Attack.PACE, 1.0 - 0.2 * phase)


func _pick_attack() -> void:
	var dist: float = absf(_player.global_position.x - global_position.x)
	if phase >= 2 and randf() < (0.35 + 0.15 * (phase - 2)):
		_set(Attack.RISE, 2.0)
		Juice.float_text(global_position + Vector2(0, -140), "RIM TIME.", Color(1, 0.6, 0.2))
		return
	if dist > 220.0 and randf() < 0.45:
		_telegraph.visible = true
		_set(Attack.PASS, 0.4)
		return
	_charge_dir = 1 if _player.global_position.x > global_position.x else -1
	facing = _charge_dir
	_telegraph.visible = true
	_set(Attack.CHARGE_TELL, 0.45)


func _begin_charge() -> void:
	_telegraph.visible = false
	_set_body_hitbox(true)
	Juice.shake(3.0)
	if randf() < 0.4:
		Juice.float_text(global_position + Vector2(0, -140), TRASH_TALK.pick_random(), Color(1, 0.6, 0.2))
	_set(Attack.CHARGE, 0.9)


func _chest_pass() -> void:
	_telegraph.visible = false
	var count := 1 if phase == 1 else 2
	for i in count:
		var ball := _make_ball()
		ball.global_position = global_position + Vector2(34.0 * facing, -30.0)
		ball.launch_vector(Vector2((380.0 + 120.0 * i) * facing, -120.0))
	_set(Attack.RECOVER, 0.5)


func _show_dunk_marker() -> void:
	_dunk_marker = ColorRect.new()
	_dunk_marker.size = Vector2(110, 10)
	_dunk_marker.color = Color(1, 0.25, 0.2, 0.85)
	get_tree().current_scene.add_child(_dunk_marker)
	_move_marker()


func _move_marker() -> void:
	if _dunk_marker != null:
		_dunk_marker.position = Vector2(global_position.x - 55.0, 646.0)


func _land_dunk() -> void:
	_set_body_hitbox(false)
	if _dunk_marker != null:
		_dunk_marker.queue_free()
		_dunk_marker = null
	Juice.shake(10.0)
	Juice.hitstop(0.06)
	var balls := 1 + phase
	for i in balls:
		var ball := _make_ball()
		var dir := -1 if i % 2 == 0 else 1
		ball.global_position = global_position + Vector2(40.0 * dir, -40.0)
		ball.launch_vector(Vector2((260.0 + 70.0 * i) * dir, -380.0))
	Juice.float_text(global_position + Vector2(0, -150), "AND THE FOUL.", Color(1, 0.6, 0.2))
	_set(Attack.LAND, 0.5)


func _make_ball() -> GenericProjectile:
	var ball := GenericProjectile.new()
	ball.gravity = 1500.0
	ball.bouncing = true
	ball.max_bounces = 4
	ball.damage = 9
	ball.box_size = Vector2(26, 26)
	ball.color = Color(0.9, 0.45, 0.1)
	ball.lifetime = 5.0
	get_tree().current_scene.add_child(ball)
	return ball


func _set(attack: Attack, time: float) -> void:
	_attack = attack
	_timer = time


func _set_body_hitbox(active: bool) -> void:
	if active:
		_body_hitbox.monitoring_changed_rearm()
	_body_hitbox.set_deferred("monitoring", active)
	_body_shape.set_deferred("disabled", not active)


# ------------------------------------------------------------------ phases / defeat

func _check_phase(_amount: int, current: int) -> void:
	var ratio := float(current) / float(health.max_health)
	if phase == 1 and ratio <= 0.66:
		_phase_up(2, "OK. OK. WARMUP'S OVER.")
	elif phase == 2 and ratio <= 0.33:
		_phase_up(3, "GAME POINT. MY BALL.")


func _phase_up(p: int, line: String) -> void:
	phase = p
	Juice.hitstop(0.2, 0.02)
	Juice.shake(8.0)
	Juice.float_text(global_position + Vector2(0, -150), line, Color(1, 0.5, 0.2))
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
	if _dunk_marker != null:
		_dunk_marker.queue_free()
	died.emit(self)
	DialogueSystem.start([
		{"speaker": "KING CROSSOVER", "text": "...Nobody's beat me on this court since '94."},
		{"speaker": "DA'HERM", "text": "Maybe the court was tired of you winning."},
		{"speaker": "KING CROSSOVER", "text": "HA. Ball don't lie. Here — the Air Crossover. Footwork's yours now. Don't embarrass me with it."},
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
