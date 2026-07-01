# brittney_duel.gd
# BOSS 13: BRITTNEY NUTTINGS (05_BOSS_BIBLE)
# Fight type: NON-LETHAL DUEL. Purpose: "Tests player assumptions."
# Outcome: ally. Reward: Cult Information (and her business card).
#
# The assumption being tested: that the pretty famous one can't
# fight. She trained for this exact moment. The duel ends - it does
# not kill - at 40% health on either side. Health.died can never
# fire here; the threshold check disarms her first.

class_name BrittneyDuel
extends EnemyBase

signal duel_ended

enum Attack { PACE, POSE_TELL, POSE, SOUNDBITE, DASH, RECOVER }

@export var arena_left: float = 100.0
@export var arena_right: float = 1500.0

var phase: int = 1
var _attack: Attack = Attack.PACE
var _timer: float = 1.2
var _dash_dir: int = 1
var _ended: bool = false
var _player: Player

@onready var _telegraph: ColorRect = $Visual/Telegraph


func _ready() -> void:
	super()
	health.damaged.connect(_check_threshold)
	_telegraph.visible = false


func _ai(delta: float) -> void:
	if _ended:
		velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
		return
	_player = _find_player()
	if _player == null:
		return
	# the duel also ends if DA'HERM hits 40% - she stops, every time
	if _player.health.current <= int(_player.health.max_health * 0.4):
		_end_duel(false)
		return
	_timer -= delta
	match _attack:
		Attack.PACE:
			facing = 1 if _player.global_position.x > global_position.x else -1
			velocity.x = 180.0 * facing
			if _timer <= 0.0:
				_pick()
		Attack.POSE_TELL:
			velocity.x = 0.0
			if _timer <= 0.0:
				_flash_pose()
		Attack.POSE, Attack.SOUNDBITE:
			velocity.x = 0.0
			if _timer <= 0.0:
				_set(Attack.RECOVER, 0.45)
		Attack.DASH:
			velocity.x = 560.0 * _dash_dir
			if _timer <= 0.0 or is_on_wall():
				_set_body_hitbox(false)
				_set(Attack.RECOVER, 0.5)
		Attack.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
			if _timer <= 0.0:
				_set(Attack.PACE, 0.9 if phase == 1 else 0.6)


func _pick() -> void:
	var roll := randf()
	if roll < 0.4:
		_telegraph.visible = true
		_set(Attack.POSE_TELL, 0.4)
	elif roll < 0.75:
		_soundbites()
	else:
		_dash_dir = 1 if _player.global_position.x > global_position.x else -1
		facing = _dash_dir
		_set_body_hitbox(true)
		_set(Attack.DASH, 0.6)


func _flash_pose() -> void:
	# the cameras she carries with her go off all at once
	_telegraph.visible = false
	Juice.shake(3.0)
	for i in 2 + phase:
		var flash := GenericProjectile.new()
		flash.speed = 360.0 + 60.0 * i
		flash.damage = 8
		flash.color = Color(1, 1, 0.92)
		flash.label_text = "FLASH"
		flash.box_size = Vector2(20, 20)
		flash.lifetime = 2.5
		flash.global_position = global_position + Vector2(0, -50)
		get_tree().current_scene.add_child(flash)
		var aim := (_player.global_position - flash.global_position).normalized()
		flash.launch_vector(aim.rotated(randf_range(-0.18, 0.18)) * flash.speed)
	_set(Attack.POSE, 0.5)


func _soundbites() -> void:
	var lines := ["NO COMMENT", "LOVE THAT", "WE'LL CIRCLE BACK"] if phase == 1 \
			else ["I KNOW.", "I'M NOT FUNNY.", "TICKETS STILL SOLD."]
	for i in 2:
		var bite := GenericProjectile.new()
		bite.gravity = 1050.0
		bite.lift = -300.0 - 90.0 * i
		bite.speed = 300.0 + 80.0 * i
		bite.damage = 9
		bite.color = Color(0.95, 0.6, 0.75)
		bite.label_text = lines.pick_random()
		bite.box_size = Vector2(30, 16)
		bite.global_position = global_position + Vector2(26.0 * facing, -55.0)
		get_tree().current_scene.add_child(bite)
		bite.launch(facing)
	_set(Attack.SOUNDBITE, 0.5)


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


func _check_threshold(_amount: int, current: int) -> void:
	if _ended:
		return
	var ratio := float(current) / float(health.max_health)
	if phase == 1 and ratio <= 0.7:
		phase = 2
		Juice.hitstop(0.2, 0.02)
		Juice.float_text(global_position + Vector2(0, -150),
				"(she drops the media smile. this is the real one.)", Color(0.95, 0.7, 0.8))
	if ratio <= 0.4:
		_end_duel(true)


func _end_duel(player_won: bool) -> void:
	_ended = true
	health.invulnerable = true
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.hide_boss()  # non-lethal: Health.died never fires, so the
		# auto-hide wired in show_boss never would either
	_set_body_hitbox(false)
	_telegraph.visible = false
	var opener := "Okay. Okay! You can actually fight. Noted." if player_won \
			else "Sit down before you fall down. The duel's over - I don't do hospital headlines."
	DialogueSystem.start([
		{"speaker": "BRITTNEY", "text": opener},
		{"speaker": "DA'HERM", "text": "Why the audition?"},
		{"speaker": "BRITTNEY", "text": "Because the island doesn't scare off. It absorbs. I needed to know you were the other kind."},
		{"speaker": "BRITTNEY", "text": "So here's everything: the Pyramid's a funnel. The competition feeds it. The Council pretends to steer it. And the thing at the top NEEDS the applause - cut the applause, you cut the power."},
		{"speaker": "DA'HERM", "text": "Why tell me? You live inside this machine."},
		{"speaker": "BRITTNEY", "text": "I know exactly why I'm famous. Doesn't mean I have to like what it costs everyone else. Take the card. If a door won't open, show them my name and watch it remember its manners."},
	])
	DialogueSystem.finished.connect(_grant, CONNECT_ONE_SHOT)


func _grant() -> void:
	GameState.set_flag(&"brittney_duel_done")
	GameState.grant_relic(&"brittneys_card")
	SaveSystem.autosave()
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("BRITTNEY'S BUSINESS CARD\nCult information. +15% follower gain. Doors remember their manners.")
	duel_ended.emit()


func _on_hit_received(hitbox: Hitbox) -> void:
	if _ended:
		return
	health.take_damage(hitbox.damage)
	_flash()
	Juice.hitstop(0.03)
	Juice.shake(2.0)


func _on_died() -> void:
	pass  # unreachable by design: the 40% threshold disarms first


func _find_player() -> Player:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] as Player if not nodes.is_empty() else null
