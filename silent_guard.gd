# pod_father.gd
# BOSS 04: POD FATHER (05_BOSS_BIBLE / BOSS_DATABASE)
# Theme: Content Addiction. "Runs 34 podcasts simultaneously."
# Semi-stationary - he hasn't left the booth in years.
#
# Kit: ground SOUNDWAVES (jump them) · aimed AUDIO BLASTS (dash
# i-frames or jump) · MIC TENTACLES (warning columns at your feet) ·
# AD BREAK at every phase change (invulnerable, spawns sponsored
# Podcast Bros - the fight is brought to you by the fight).
# Reward: POD MIC (combo-scaling weapon).

class_name PodFather
extends EnemyBase

signal boss_defeated

const PODCAST_BRO := preload("res://scenes/enemies/podcast_bro.tscn")
const AD_READS := [
	"THIS BEATDOWN IS SPONSORED BY MATTRESS.",
	"USE CODE 'PODFATHER' FOR 10% OFF.",
	"WE'LL BE RIGHT BACK.",
]

enum Attack { IDLE, WAVE, BLAST_TELL, BLAST, TENTACLES, AD_BREAK, RECOVER }

var phase: int = 1
var _attack: Attack = Attack.IDLE
var _timer: float = 1.2
var _ad_invuln: bool = false
var _player: Player

@onready var _telegraph: ColorRect = $Visual/Telegraph


func _ready() -> void:
	super()
	health.damaged.connect(_check_phase)
	_telegraph.visible = false


func _ai(delta: float) -> void:
	velocity.x = 0.0  # he does not leave the booth
	_player = _find_player()
	if _player == null:
		return
	_timer -= delta
	match _attack:
		Attack.IDLE:
			facing = 1 if _player.global_position.x > global_position.x else -1
			if _timer <= 0.0:
				_pick_attack()
		Attack.WAVE:
			if _timer <= 0.0:
				_fire_waves()
		Attack.BLAST_TELL:
			if _timer <= 0.0:
				_fire_blast()
		Attack.TENTACLES:
			if _timer <= 0.0:
				_set(Attack.RECOVER, 0.7)
		Attack.AD_BREAK:
			if _timer <= 0.0:
				_end_ad_break()
		Attack.RECOVER:
			if _timer <= 0.0:
				_set(Attack.IDLE, maxf(0.4, 1.1 - 0.25 * phase))


func _pick_attack() -> void:
	var roll := randf()
	if phase >= 2 and roll < 0.4:
		_launch_tentacles()
	elif roll < 0.7:
		_telegraph.visible = true
		_set(Attack.WAVE, 0.45)
	else:
		_telegraph.visible = true
		_set(Attack.BLAST_TELL, 0.35)


func _fire_waves() -> void:
	_telegraph.visible = false
	for dir in [-1, 1]:
		var wave := GenericProjectile.new()
		wave.speed = 300.0 + 50.0 * phase
		wave.damage = 8
		wave.box_size = Vector2(30, 46)
		wave.color = Color(0.4, 0.85, 1.0, 0.85)
		wave.label_text = "~ ~ ~"
		wave.lifetime = 4.0
		wave.global_position = global_position + Vector2(40.0 * dir, 34.0)
		get_tree().current_scene.add_child(wave)
		wave.launch(dir)
	_set(Attack.RECOVER, 0.6)


func _fire_blast() -> void:
	_telegraph.visible = false
	var count := 1 if phase < 3 else 2
	for i in count:
		var blast := GenericProjectile.new()
		blast.speed = 440.0
		blast.damage = 9
		blast.box_size = Vector2(26, 18)
		blast.color = Color(0.9, 0.4, 1.0)
		blast.label_text = "GREAT POINT—"
		blast.lifetime = 3.5
		blast.global_position = global_position + Vector2(0, -40.0 - 60.0 * i)
		get_tree().current_scene.add_child(blast)
		var to_player := (_player.global_position - blast.global_position).normalized()
		blast.launch_vector(to_player * blast.speed)
	_set(Attack.RECOVER, 0.5)


func _launch_tentacles() -> void:
	var count := phase  # 2 in p2, 3 in p3
	for i in count:
		var tentacle := TentacleStrike.new()
		tentacle.warn_time = 0.65 + 0.18 * i
		var x := _player.global_position.x + randf_range(-90.0, 90.0) * i
		tentacle.position = Vector2(x, 660.0)
		get_tree().current_scene.add_child(tentacle)
	_set(Attack.TENTACLES, 0.9 + 0.2 * count)


func _start_ad_break() -> void:
	_ad_invuln = true
	visual.modulate = Color(1.4, 1.4, 0.8)
	Juice.float_text(global_position + Vector2(0, -160), AD_READS.pick_random(), Color(1, 0.9, 0.3))
	for i in 2:
		var bro := PODCAST_BRO.instantiate()
		bro.position = global_position + Vector2(-260.0 + 520.0 * i, -60.0)
		get_tree().current_scene.add_child(bro)
	_set(Attack.AD_BREAK, 2.6)


func _end_ad_break() -> void:
	_ad_invuln = false
	visual.modulate = Color.WHITE
	Juice.float_text(global_position + Vector2(0, -160), "AND WE'RE BACK.", Color(1, 0.9, 0.3))
	_set(Attack.RECOVER, 0.4)


func _set(attack: Attack, time: float) -> void:
	_attack = attack
	_timer = time


# ------------------------------------------------------------------ phases / defeat

func _check_phase(_amount: int, current: int) -> void:
	var ratio := float(current) / float(health.max_health)
	if phase == 1 and ratio <= 0.66:
		phase = 2
		_phase_fx("SEGMENT TWO. THINGS GET REAL.")
		_start_ad_break()
	elif phase == 2 and ratio <= 0.33:
		phase = 3
		_phase_fx("THE LISTENERS DESERVE THIS.")
		_start_ad_break()


func _phase_fx(line: String) -> void:
	Juice.hitstop(0.2, 0.02)
	Juice.shake(8.0)
	Juice.float_text(global_position + Vector2(0, -170), line, Color(1, 0.5, 0.8))
	_telegraph.visible = false


func _on_hit_received(hitbox: Hitbox) -> void:
	if _is_dead:
		return
	if _ad_invuln:
		Juice.float_text(global_position + Vector2(0, -140), "(we're on a break)", Color(0.7, 0.7, 0.75))
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
		{"speaker": "POD FATHER", "text": "Wait— hold on— we're still rolling— this is GREAT content—"},
		{"speaker": "DA'HERM", "text": "Nobody's listening, man."},
		{"speaker": "POD FATHER", "text": "...Episode 4,062. The day the downloads stopped. (whispering) ...take the mic. It deserves a real voice."},
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
