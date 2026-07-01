# secret_club.gd
# THE SECRET CLUB (behind the poster). One room. One mic. One crowd.
# THE CROWD (BOSS 18) - the boss you win over, not beat down.
# Reward: EMPATHY FRAGMENT (required for the True Ending).

extends RoomBase

const CROWD := preload("res://scenes/enemies/the_crowd.tscn")
const RELIC := preload("res://scripts/items/relic_pickup.gd")

const VELVET := Color(0.26, 0.14, 0.2)
const WOOD := Color(0.3, 0.22, 0.18)

var _crowd: TheCrowd = null
var _fight_started: bool = false


func _build() -> void:
	spawn_points = {&"default": Vector2(140, 560)}
	camera_rect = Rect2(-280, -900, 2060, 2200)
	kill_y = 1200.0

	solid(-280, -700, 80, 1560, VELVET.darkened(0.4))
	solid(1500, -700, 80, 1560, VELVET.darkened(0.4))
	solid(-200, 660, 1700, 200, WOOD)

	decor(250, 480, 120, 180, WOOD.lightened(0.15))  # the stage riser
	sign_label(Vector2(260, 440), "(a stage. a mic. a room that decides.)", 12)
	sign_label(Vector2(900, 460), "(They're all looking at you. They've been waiting.)", 12)


func _populate() -> void:
	var out := Door.new()
	out.door_label = "(back through the wall)"
	out.target_scene = "res://scenes/levels/comedy_underground.tscn"
	out.target_spawn = &"from_club"
	place(out, Vector2(60, 605))

	if GameState.has_flag(&"boss_crowd_defeated"):
		if not GameState.has_relic(&"empathy_fragment"):
			_spawn_reward()
		return

	_crowd = CROWD.instantiate()
	_crowd.arena_left = 100.0
	_crowd.arena_right = 1400.0
	place(_crowd, Vector2(950, 470))
	_crowd.boss_defeated.connect(_on_crowd_defeated)

	var mic: Area2D = StageMic.new()
	mic.performed.connect(_crowd.on_performed)
	place(mic, Vector2(300, 615))


func _physics_process(delta: float) -> void:
	super(delta)
	if _fight_started or _crowd == null:
		return
	if player.global_position.x > 360.0:
		_start_fight()


func _start_fight() -> void:
	_fight_started = true
	Juice.shake(4.0)
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("THE CROWD\nPunching an audience has never once worked. The mic might.")
		hud.show_boss("THE CROWD — TOUGH ROOM", _crowd.health)


func _on_crowd_defeated() -> void:
	GameState.set_flag(&"boss_crowd_defeated")
	SaveSystem.autosave()
	_spawn_reward()


func _spawn_reward() -> void:
	var relic: Area2D = RELIC.new()
	relic.relic_id = &"empathy_fragment"
	relic.display_name = "EMPATHY FRAGMENT"
	relic.desc_text = "It doesn't do anything. That you can measure. Yet."
	relic.relic_color = Color(1.0, 0.75, 0.7)
	place(relic, Vector2(950, 580))
