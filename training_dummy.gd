# ring_light_queen.gd
# BOSS 08: RING LIGHT QUEEN (05_BOSS_BIBLE)
# Theme: Validation. "Lives entirely on camera."
#
# Signature: THE FLASH - the whole terrace lights up; the blast
# sweeps the FLOOR. Counter-play: be airborne when it pops. The
# arena-wide "JUMP" tell is generous in P1 and tightens by P3.
# Plus: STRIKE (pose-dash across the terrace) and camera drone
# summons (max 2 alive - adds support her, never replace her).

class_name RingLightQueen
extends EnemyBase

signal boss_defeated

const DRONE := preload("res://scenes/enemies/camera_drone.tscn")

enum Attack { POSE, FLASH_TELL, FLASH, STRIKE_TELL, STRIKE, SUMMON, RECOVER }

@export var arena_left: float = 80.0
@export var arena_right: float = 1700.0

var phase: int = 1
var _attack: Attack = Attack.POSE
var _timer: float = 1.0
var _strike_dir: int = 1
var _drones_alive: int = 0
var _flash_overlay: ColorRect = null
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
		Attack.POSE:
			facing = 1 if _player.global_position.x > global_position.x else -1
			velocity.x = 120.0 * facing
			if _timer <= 0.0:
				_pick()
		Attack.FLASH_TELL:
			velocity.x = 0.0
			if _timer <= 0.0:
				_pop_flash()
		Attack.FLASH:
			if _timer <= 0.0:
				_set(Attack.RECOVER, 0.8)
		Attack.STRIKE_TELL:
			velocity.x = 0.0
			if _timer <= 0.0:
				_begin_strike()
		Attack.STRIKE:
			velocity.x = (560.0 + 50.0 * phase) * _strike_dir
			if _timer <= 0.0 or is_on_wall() \
					or global_position.x < arena_left or global_position.x > arena_right:
				_end_strike()
		Attack.SUMMON:
			velocity.x = 0.0
			if _timer <= 0.0:
				_set(Attack.RECOVER, 0.5)
		Attack.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
			if _timer <= 0.0:
				_set(Attack.POSE, maxf(0.4, 1.2 - 0.25 * phase))


func _pick() -> void:
	var roll := randf()
	if roll < 0.4:
		_start_flash_tell()
	elif roll < 0.75 or _drones_alive >= 2:
		_strike_dir = 1 if _player.global_position.x > global_position.x else -1
		facing = _strike_dir
		_telegraph.visible = true
		_set(Attack.STRIKE_TELL, 0.45)
	else:
		_summon_drone()


func _start_flash_tell() -> void:
	_flash_overlay = ColorRect.new()
	_flash_overlay.color = Color(1, 1, 0.85, 0.12)
	_flash_overlay.size = Vector2(4000, 2000)
	_flash_overlay.position = Vector2(-1000, -1000)
	_flash_overlay.z_index = 5
	get_tree().current_scene.add_child(_flash_overlay)
	Juice.float_text(global_position + Vector2(0, -150), "EVERYBODY SAY 'CONTENT' — JUMP!", Color(1, 0.95, 0.6))
	_set(Attack.FLASH_TELL, maxf(0.55, 1.0 - 0.18 * phase))


func _pop_flash() -> void:
	if _flash_overlay != null:
		_flash_overlay.color = Color(1, 1, 0.95, 0.65)
		var overlay := _flash_overlay
		var tween := overlay.create_tween()
		tween.tween_property(overlay, "modulate:a", 0.0, 0.3)
		tween.tween_callback(overlay.queue_free)
		_flash_overlay = null
	Juice.shake(8.0)
	# the blast sweeps the FLOOR: airborne players are safe
	var blast := Hitbox.new()
	blast.collision_layer = 32
	blast.collision_mask = 64
	blast.damage = 12
	blast.knockback_strength = 320.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(arena_right - arena_left + 100.0, 56.0)
	shape.shape = rect
	blast.add_child(shape)
	blast.position = Vector2((arena_left + arena_right) * 0.5, 630.0)
	get_tree().current_scene.add_child(blast)
	get_tree().create_timer(0.15).timeout.connect(blast.queue_free)
	_set(Attack.FLASH, 0.2)


func _begin_strike() -> void:
	_telegraph.visible = false
	Juice.float_text(global_position + Vector2(0, -150), "COMING THROUGH, ANGELS.", Color(1, 0.8, 0.9))
	_set_body_hitbox(true)
	_set(Attack.STRIKE, 0.85)


func _end_strike() -> void:
	_set_body_hitbox(false)
	_set(Attack.RECOVER, 0.7)


func _summon_drone() -> void:
	var count := 1 if phase < 3 else 2
	for i in count:
		if _drones_alive >= 2:
			break
		var drone := DRONE.instantiate()
		drone.position = global_position + Vector2(-160.0 + 320.0 * i, -180.0)
		get_tree().current_scene.add_child(drone)
		_drones_alive += 1
		drone.died.connect(func(_e): _drones_alive -= 1)
	Juice.float_text(global_position + Vector2(0, -150), "GET MY ANGLES.", Color(1, 0.8, 0.9))
	_set(Attack.SUMMON, 0.6)


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
		_phase_fx("GOLDEN HOUR, PEOPLE. GOLDEN. HOUR.")
	elif phase == 2 and ratio <= 0.33:
		phase = 3
		_phase_fx("WE'RE GOING LIVE.")


func _phase_fx(line: String) -> void:
	Juice.hitstop(0.2, 0.02)
	Juice.shake(8.0)
	Juice.float_text(global_position + Vector2(0, -160), line, Color(1, 0.7, 0.85))
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
	if _flash_overlay != null:
		_flash_overlay.queue_free()
	died.emit(self)
	DialogueSystem.start([
		{"speaker": "RING LIGHT QUEEN", "text": "Wait— delete that. DELETE THAT."},
		{"speaker": "DA'HERM", "text": "Nobody was filming."},
		{"speaker": "RING LIGHT QUEEN", "text": "...nobody was filming? Then who was I... (she looks at her hands) ...take the relic. Apparently influence is transferable."},
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
