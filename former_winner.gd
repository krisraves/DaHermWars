# brandon_sponsorson.gd
# BOSS 10: BRANDON SPONSORSON (05_BOSS_BIBLE)
# Theme: Monetization. "Living sponsorship executive."
# Kit: CONTRACTS (arcing paperwork volleys) · AD PLACEMENT (marked
# drop zones, then crates of branding fall) · CORPORATE SUMMONS
# (HR Enforcers, max 2). Phase 3 is just a hostile quarterly review.

class_name BrandonSponsorson
extends EnemyBase

signal boss_defeated

const HR := preload("res://scenes/enemies/hr_enforcer.tscn")

enum Attack { PACE, CONTRACT_TELL, CONTRACT, AD_TELL, AD_DROP, SUMMON, RECOVER }

@export var arena_left: float = 80.0
@export var arena_right: float = 1500.0
@export var floor_y: float = 660.0

var phase: int = 1
var _attack: Attack = Attack.PACE
var _timer: float = 1.0
var _adds_alive: int = 0
var _ad_markers: Array = []
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
			velocity.x = 110.0 * facing
			if _timer <= 0.0:
				_pick()
		Attack.CONTRACT_TELL:
			velocity.x = 0.0
			if _timer <= 0.0:
				_throw_contracts()
		Attack.AD_TELL:
			velocity.x = 0.0
			if _timer <= 0.0:
				_drop_ads()
		Attack.AD_DROP:
			if _timer <= 0.0:
				_set(Attack.RECOVER, 0.6)
		Attack.SUMMON:
			velocity.x = 0.0
			if _timer <= 0.0:
				_set(Attack.RECOVER, 0.5)
		Attack.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
			if _timer <= 0.0:
				_set(Attack.PACE, maxf(0.45, 1.1 - 0.22 * phase))


func _pick() -> void:
	var roll := randf()
	if roll < 0.45:
		_telegraph.visible = true
		_set(Attack.CONTRACT_TELL, 0.4)
	elif roll < 0.8 or _adds_alive >= 2:
		_mark_ads()
	else:
		_summon()


func _throw_contracts() -> void:
	_telegraph.visible = false
	var count := 1 + phase
	for i in count:
		var paper := GenericProjectile.new()
		paper.gravity = 1000.0
		paper.lift = -260.0 - 60.0 * i
		paper.speed = 300.0 + 70.0 * i
		paper.damage = 8
		paper.color = Color(0.95, 0.95, 0.97)
		paper.label_text = "EXHIBIT %c" % (65 + i)
		paper.box_size = Vector2(24, 18)
		paper.global_position = global_position + Vector2(34.0 * facing, -50.0)
		get_tree().current_scene.add_child(paper)
		paper.launch(facing)
	if randf() < 0.4:
		Juice.float_text(global_position + Vector2(0, -150), "PER MY LAST EMAIL—", Color(0.8, 0.9, 1))
	_set(Attack.RECOVER, 0.55)


func _mark_ads() -> void:
	var count := 2 + phase
	_ad_markers.clear()
	for i in count:
		var x := _player.global_position.x + randf_range(-260.0, 260.0)
		x = clampf(x, arena_left + 40.0, arena_right - 40.0)
		var marker := ColorRect.new()
		marker.size = Vector2(70, 8)
		marker.position = Vector2(x - 35.0, floor_y - 12.0)
		marker.color = Color(1, 0.3, 0.2, 0.85)
		get_tree().current_scene.add_child(marker)
		_ad_markers.append(marker)
	Juice.float_text(global_position + Vector2(0, -150), "AD PLACEMENT INCOMING.", Color(0.8, 0.9, 1))
	_set(Attack.AD_TELL, 0.7)


func _drop_ads() -> void:
	for marker: ColorRect in _ad_markers:
		var crate := GenericProjectile.new()
		crate.speed = 0.0
		crate.gravity = 2200.0
		crate.damage = 11
		crate.color = Color(0.95, 0.75, 0.2)
		crate.label_text = "AD"
		crate.box_size = Vector2(46, 46)
		crate.lifetime = 3.0
		crate.global_position = Vector2(marker.position.x + 35.0, floor_y - 700.0)
		get_tree().current_scene.add_child(crate)
		crate.launch_vector(Vector2.ZERO)
		get_tree().create_timer(1.2).timeout.connect(marker.queue_free)
	_ad_markers.clear()
	_set(Attack.AD_DROP, 0.8)


func _summon() -> void:
	var enforcer := HR.instantiate()
	enforcer.position = global_position + Vector2(-200.0 * facing, -40.0)
	get_tree().current_scene.add_child(enforcer)
	_adds_alive += 1
	enforcer.died.connect(func(_e): _adds_alive -= 1)
	Juice.float_text(global_position + Vector2(0, -150), "LOOPING IN HR.", Color(0.8, 0.9, 1))
	_set(Attack.SUMMON, 0.6)


func _set(attack: Attack, time: float) -> void:
	_attack = attack
	_timer = time


func _check_phase(_amount: int, current: int) -> void:
	var ratio := float(current) / float(health.max_health)
	if phase == 1 and ratio <= 0.66:
		phase = 2
		_phase_fx("LET'S TALK DELIVERABLES.")
	elif phase == 2 and ratio <= 0.33:
		phase = 3
		_phase_fx("THIS IS NOW A QUARTERLY REVIEW.")


func _phase_fx(line: String) -> void:
	Juice.hitstop(0.2, 0.02)
	Juice.shake(8.0)
	Juice.float_text(global_position + Vector2(0, -160), line, Color(0.6, 0.85, 1))
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
	for marker in _ad_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	died.emit(self)
	DialogueSystem.start([
		{"speaker": "BRANDON SPONSORSON", "text": "This was... a pre-revenue altercation. Off the books."},
		{"speaker": "DA'HERM", "text": "Invoice me."},
		{"speaker": "BRANDON SPONSORSON", "text": "(coughing) Take the sigil. Full benefits. Dental. ...Tell the tower I monetized with honor."},
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
