# content_castle.gd
# BOSS 09: CONTENT CASTLE (05_BOSS_BIBLE)
# "A living mansion that creates content." Shifting rooms, selfie
# traps, viral hazards. Reward: FOLLOWER BOOSTER.
#
# You fight the house. It does not move - it was always going to be
# the venue AND the host. SELFIE TRAPS flash up from the floor in
# clusters; VIRAL hazards bounce around the room long after they're
# fired; ROOM SHIFT sends walls of furniture sweeping in from the
# edges; content drones peel off the chandeliers.

class_name ContentCastle
extends EnemyBase

signal boss_defeated

const DRONE := preload("res://scenes/enemies/camera_drone.tscn")

enum Attack { IDLE, SELFIE, VIRAL, SHIFT, SPAWN, RECOVER }

@export var arena_left: float = 100.0
@export var arena_right: float = 1500.0
@export var floor_y: float = 660.0

var phase: int = 1
var _attack: Attack = Attack.IDLE
var _timer: float = 1.4
var _adds_alive: int = 0
var _player: Player

@onready var _telegraph: ColorRect = $Visual/Telegraph


func _ready() -> void:
	super()
	health.damaged.connect(_check_phase)
	_telegraph.visible = false


func _ai(_delta: float) -> void:
	_player = _find_player()
	if _player == null:
		return
	_timer -= _delta
	match _attack:
		Attack.IDLE:
			if _timer <= 0.0:
				_pick()
		Attack.SELFIE, Attack.VIRAL, Attack.SHIFT, Attack.SPAWN:
			if _timer <= 0.0:
				_set(Attack.RECOVER, 0.5)
		Attack.RECOVER:
			if _timer <= 0.0:
				_set(Attack.IDLE, maxf(0.45, 1.2 - 0.25 * phase))


func _pick() -> void:
	var roll := randf()
	if roll < 0.35:
		_selfie_traps()
	elif roll < 0.65:
		_viral_hazards()
	elif roll < 0.85 or _adds_alive >= 2:
		_room_shift()
	else:
		_spawn_drone()


func _selfie_traps() -> void:
	# flash columns cluster around where you're standing
	Juice.float_text(Vector2(global_position.x, 200.0), "SAY CHEESE", Color(1, 0.8, 0.9))
	var count := 2 + phase
	for i in count:
		var trap := TentacleStrike.new()
		trap.warn_time = 0.5 + 0.12 * i
		trap.active_time = 0.2
		trap.column_height = 420.0
		trap.position = Vector2(
			clampf(_player.global_position.x + randf_range(-180.0, 180.0),
				arena_left + 40.0, arena_right - 40.0), floor_y)
		get_tree().current_scene.add_child(trap)
	_set(Attack.SELFIE, 0.9)


func _viral_hazards() -> void:
	# they bounce. they keep bouncing. that's the whole point of viral.
	for i in 1 + phase:
		var viral := GenericProjectile.new()
		viral.speed = 280.0 + 40.0 * i
		viral.gravity = 900.0
		viral.lift = -420.0 - 60.0 * i
		viral.bouncing = true
		viral.damage = 8
		viral.color = Color(0.95, 0.5, 0.85)
		viral.label_text = "VIRAL"
		viral.box_size = Vector2(26, 26)
		viral.lifetime = 6.0
		viral.global_position = global_position + Vector2(randf_range(-100.0, 100.0), -120.0)
		get_tree().current_scene.add_child(viral)
		viral.launch(-1 if _player.global_position.x < global_position.x else 1)
	_set(Attack.VIRAL, 0.6)


func _room_shift() -> void:
	# the room rearranges itself across you: furniture walls sweep in
	var labels := ["OTTOMAN", "CREDENZA", "ACCENT WALL", "STATEMENT PIECE"]
	var dirs: Array = [-1, 1] if phase >= 2 else [1 if _player.global_position.x < global_position.x else -1]
	for dir: int in dirs:
		var wall := GenericProjectile.new()
		wall.speed = 180.0 + 30.0 * phase
		wall.damage = 10
		wall.box_size = Vector2(44, 100)
		wall.color = Color(0.8, 0.7, 0.55, 0.95)
		wall.label_text = labels.pick_random()
		wall.lifetime = 7.0
		wall.global_position = Vector2(
			arena_right - 60.0 if dir < 0 else arena_left + 60.0, floor_y - 64.0)
		get_tree().current_scene.add_child(wall)
		wall.launch(dir)
	Juice.shake(3.0)
	Juice.float_text(Vector2(global_position.x, 240.0), "(the room redecorates. at you.)", Color(0.95, 0.8, 0.9))
	_set(Attack.SHIFT, 0.6)


func _spawn_drone() -> void:
	var drone := DRONE.instantiate()
	drone.position = Vector2(global_position.x + randf_range(-150.0, 150.0), 220.0)
	get_tree().current_scene.add_child(drone)
	_adds_alive += 1
	drone.died.connect(func(_e): _adds_alive -= 1)
	Juice.float_text(drone.position + Vector2(0, -50), "(it drops off the chandelier)", Color(0.9, 0.85, 0.95))
	_set(Attack.SPAWN, 0.5)


func _set(attack: Attack, time: float) -> void:
	_attack = attack
	_timer = time


func _check_phase(_amount: int, current: int) -> void:
	var ratio := float(current) / float(health.max_health)
	if phase == 1 and ratio <= 0.66:
		phase = 2
		_phase_fx("NEW ROOM REVEAL (GONE WRONG)")
	elif phase == 2 and ratio <= 0.33:
		phase = 3
		_phase_fx("(the house is filming its own destruction. engagement is up.)")


func _phase_fx(line: String) -> void:
	Juice.hitstop(0.2, 0.02)
	Juice.shake(8.0)
	Juice.float_text(global_position + Vector2(0, -180), line, Color(0.95, 0.6, 0.85))
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
		{"speaker": "CONTENT CASTLE", "text": "(every screen in the house at once) THANKS FOR WATCHING. LIKE AND SUBSCRI--"},
		{"speaker": "DA'HERM", "text": "A house. I just fought a HOUSE. And honestly? Not even top five weirdest this month."},
	])
	DialogueSystem.finished.connect(_finish, CONNECT_ONE_SHOT)


func _finish() -> void:
	boss_defeated.emit()
	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 1.4)
	tween.tween_callback(queue_free)


func _find_player() -> Player:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] as Player if not nodes.is_empty() else null
