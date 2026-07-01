# inner_circle.gd
# BOSS 22: INNER CIRCLE (05_BOSS_BIBLE)
# Theme: Elite Complicity. "Council of elite cultists.
# Multi-opponent battle."
#
# Three council members fight at once - a contract-thrower, a
# charger, and a hovering visionary - built from the existing
# behavior scripts with council-grade health. This controller owns
# the shared boss bar (Health = 3 seats); each member's death
# empties a seat. Reward: the CULT KEY (opens the summit).

class_name InnerCircle
extends Node2D

signal boss_defeated

const PRIEST := preload("res://scenes/enemies/sponsor_priest.tscn")
const ACOLYTE := preload("res://scenes/enemies/executive_acolyte.tscn")
const DRONE := preload("res://scenes/enemies/algorithm_drone.tscn")

const COUNCIL_TITLES := ["THE PRODUCER", "THE EXECUTIVE", "THE VISIONARY"]

var health: Health
var _members_alive: int = 0
var _seat: int = 0


func _ready() -> void:
	health = Health.new()
	health.max_health = 3
	add_child(health)
	health.died.connect(_on_council_fallen)


func summon_council() -> void:
	_spawn_member(PRIEST.instantiate(), Vector2(-360, -40), 120)
	_spawn_member(ACOLYTE.instantiate(), Vector2(320, -40), 130)
	_spawn_member(DRONE.instantiate(), Vector2(0, -220), 90)


func _spawn_member(member: EnemyBase, offset: Vector2, hp: int) -> void:
	member.get_node("Health").max_health = hp
	member.follower_drop = 30
	member.position = global_position + offset
	get_tree().current_scene.add_child(member)
	_members_alive += 1
	var title: String = COUNCIL_TITLES[_seat]
	_seat += 1
	Juice.float_text(member.global_position + Vector2(0, -110), title, Color(0.95, 0.85, 0.4))
	member.died.connect(_on_member_died)


func _on_member_died(_member: EnemyBase) -> void:
	_members_alive -= 1
	health.take_damage(1)
	if _members_alive > 0:
		Juice.float_text(global_position + Vector2(0, -160),
				"(an empty chair. the others pretend not to notice.)", Color(0.85, 0.8, 0.7))


func _on_council_fallen() -> void:
	DialogueSystem.start([
		{"speaker": "INNER CIRCLE", "text": "(the last one, on his knees) You don't understand. We don't RUN it. Nobody runs it. We just... benefit."},
		{"speaker": "DA'HERM", "text": "Then you'll understand when it stops benefiting."},
		{"speaker": "INNER CIRCLE", "text": "He's at the summit. He's been watching the whole climb. He thinks it's a great episode."},
	])
	DialogueSystem.finished.connect(_finish, CONNECT_ONE_SHOT)


func _finish() -> void:
	GameState.set_flag(&"cult_key")
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("CULT KEY\nThe summit door no longer pretends to be a wall.")
	boss_defeated.emit()
