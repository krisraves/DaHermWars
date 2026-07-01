# boardroom.gd
# THE BOARDROOM (Streaming HQ, past the Core). NETFLICKS (BOSS 12)
# looms here - the platform itself, wearing a tie. Reward: the
# STREAMING PASS (Heat trickles back: always buffering).

extends RoomBase

const NETFLICKS := preload("res://scenes/enemies/netflicks.tscn")
const RELIC := preload("res://scripts/items/relic_pickup.gd")

const DARKRED := Color(0.25, 0.05, 0.07)
const SERVER := Color(0.08, 0.09, 0.12)

var _boss: Netflicks = null
var _fight_started: bool = false


func _build() -> void:
	spawn_points = {&"default": Vector2(140, 560)}
	camera_rect = Rect2(-280, -900, 2160, 2200)
	kill_y = 1200.0

	solid(-280, -700, 80, 1560, SERVER)
	solid(1600, -700, 80, 1560, SERVER)
	solid(-200, 660, 1800, 200, SERVER.lightened(0.06))

	decor(300, 560, 1000, 40, DARKRED.lightened(0.1))   # the long table
	for i in 5:
		decor(360.0 + i * 190.0, 500, 70, 60, SERVER.lightened(0.12))  # empty chairs
	sign_label(Vector2(400, 470), "(Five chairs. All empty. They report to IT now.)", 12)
	sign_label(Vector2(950, 200), "Q3 PRIORITY: MORE", 13)


func _populate() -> void:
	var out := Door.new()
	out.door_label = "← THE CORE"
	out.target_scene = "res://scenes/levels/streaming_hq.tscn"
	out.target_spawn = &"from_boardroom"
	place(out, Vector2(60, 605))

	if GameState.has_flag(&"boss_netflicks_defeated"):
		_spawn_reward()
		return
	_boss = NETFLICKS.instantiate()
	_boss.arena_left = 100.0
	_boss.arena_right = 1500.0
	_boss.floor_y = 660.0
	place(_boss, Vector2(1100, 360))
	_boss.boss_defeated.connect(_on_boss_defeated)


func _physics_process(delta: float) -> void:
	super(delta)
	if _fight_started or _boss == null:
		return
	if player.global_position.x > 380.0:
		_start_fight()


func _start_fight() -> void:
	_fight_started = true
	Juice.shake(4.0)
	DialogueSystem.start([
		{"speaker": "NETFLICKS", "text": "SIT. WE'VE BEEN REVIEWING YOUR NUMBERS."},
		{"speaker": "DA'HERM", "text": "I don't work here."},
		{"speaker": "NETFLICKS", "text": "EVERYONE WORKS HERE. MOST OF THEM JUST DON'T KNOW IT YET."},
	])
	DialogueSystem.finished.connect(_show_boss_bar, CONNECT_ONE_SHOT)


func _show_boss_bar() -> void:
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("NETFLICKS\n\"A giant red squid-like executive creature.\"")
		hud.show_boss("NETFLICKS", _boss.health)


func _on_boss_defeated() -> void:
	GameState.set_flag(&"boss_netflicks_defeated")
	SaveSystem.autosave()
	_spawn_reward()


func _spawn_reward() -> void:
	if GameState.has_relic(&"streaming_pass"):
		return
	var streaming: Area2D = RELIC.new()
	streaming.relic_id = &"streaming_pass"
	streaming.display_name = "STREAMING PASS"
	streaming.desc_text = "Always buffering. Heat slowly regenerates on its own."
	streaming.relic_color = Color(0.85, 0.15, 0.2)
	place(streaming, Vector2(800, 600))
