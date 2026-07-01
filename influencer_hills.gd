# streaming_hq.gd
# REGION 07: STREAMING HEADQUARTERS (11_LEVEL_DESIGN_BIBLE)
# "A machine is deciding what matters." Satire: streaming platforms.
# Palette: server cyan on black. Algorithmic reality.
#
# Entered from the Corporate Tower roof. Flying enemies own the halls
# (Algorithm Drones aim ahead of you; Buffer Spirits just... arrive).
# East: THE CORE - THE ALGORITHM (randomized pool, predictive beams,
# visibility suppression) -> DISCOVERY MODULE (orbs home to you).

extends RoomBase

const DRONE := preload("res://scenes/enemies/algorithm_drone.tscn")
const BUFFER := preload("res://scenes/enemies/buffer_spirit.tscn")
const ALGO := preload("res://scenes/enemies/the_algorithm.tscn")
const RELIC := preload("res://scripts/items/relic_pickup.gd")
const ORB := preload("res://scripts/items/follower_orb.gd")

const SERVER := Color(0.07, 0.1, 0.12)
const CYAN := Color(0.3, 1.0, 0.75)

var _algo: TheAlgorithm = null
var _fight_started: bool = false


func _build() -> void:
	spawn_points = {
		&"from_boardroom": Vector2(3420, 560),
		&"default": Vector2(160, 560),  # from the Tower roof
	}
	camera_rect = Rect2(-280, -900, 3960, 2200)
	kill_y = 1200.0

	solid(-280, -700, 80, 1560, SERVER)
	solid(3600, -700, 80, 1560, SERVER)
	solid(-200, 660, 3800, 200, SERVER.lightened(0.08))

	# ---- server racks ---------------------------------------------------
	for x in [500.0, 1100.0, 2000.0, 2550.0]:
		decor(x, 320, 140, 340, SERVER.lightened(0.05))
		decor(x + 16.0, 350, 30, 8, CYAN)
		decor(x + 16.0, 390, 30, 8, CYAN.darkened(0.3))
		decor(x + 16.0, 430, 30, 8, CYAN)

	# ---- DJ-gated secret: above the racks (240px rises) ------------------
	solid(900, 430, 140, 20, SERVER.lightened(0.15))
	solid(1050, 200, 140, 20, SERVER.lightened(0.15))
	sign_label(Vector2(920, 380), "(maintenance only. sure.)", 12)

	# ---- George's pocket: the intern desk --------------------------------
	solid(1580, 540, 90, 20, SERVER.lightened(0.15))   # entry step
	solid(1700, 460, 50, 200, SERVER.lightened(0.1))
	solid(1860, 460, 50, 200, SERVER.lightened(0.1))
	sign_label(Vector2(1720, 410), "INTERN AREA (unpaid)", 12)

	# ---- THE CORE (boss zone, east: x > 2950) -----------------------------
	decor(2940, 200, 24, 460, CYAN.darkened(0.4))
	sign_label(Vector2(2700, 480), "THE CORE\nIt has never been wrong. It says so.", 13)

	sign_label(Vector2(400, 500), "STREAMING HEADQUARTERS\nNow recommending: you.")
	sign_label(Vector2(2200, 600), "\"THE PYRAMID HAS A GUEST LIST\"\n(this graffiti has 2.3M views)", 12)


func _populate() -> void:
	# west door back to the Tower roof
	var west := Door.new()
	west.door_label = "← TOWER ROOF"
	west.target_scene = "res://scenes/levels/corporate_tower.tscn"
	west.target_spawn = &"roof"
	place(west, Vector2(60, 605))

	# the feed's immune system
	place(DRONE.instantiate(), Vector2(1200, 380))
	place(DRONE.instantiate(), Vector2(2100, 360))
	place(DRONE.instantiate(), Vector2(2700, 400))
	place(BUFFER.instantiate(), Vector2(1500, 300))
	place(BUFFER.instantiate(), Vector2(2350, 340))

	# THE BOARDROOM (past the Core; the door only answers to metrics)
	var board := Door.new()
	board.door_label = "THE BOARDROOM"
	board.target_scene = "res://scenes/levels/boardroom.tscn"
	board.target_spawn = &"default"
	board.required_flag = &"boss_algorithm_defeated"
	board.flag_gate_line = "(The door only answers to metrics. Yours are still being computed next door.)"
	place(board, Vector2(3500, 605))

	# George, intern
	var george := GeorgeNPC.new()
	george.encounter_flag = &"george_hq"
	george.first_dialogue = [
		{"speaker": "DA'HERM", "text": "You intern HERE? You're like sixty."},
		{"speaker": "GEORGE", "text": "They said I'd get exposure."},
		{"speaker": "DA'HERM", "text": "...Was that a joke?"},
		{"speaker": "GEORGE", "text": "Was it?"},
	]
	george.lines = ["The machine hums nicely.", "Hm."]
	place(george, Vector2(1790, 600))

	var monk := NPCBase.new()
	monk.npc_name = "SERVER MONK"
	monk.body_color = Color(0.4, 0.45, 0.5)
	monk.lines = ["The feed provides. The feed withholds.", "I asked it what's funny. It showed me a chart.", "Uptime is a virtue. The only one left."]
	place(monk, Vector2(2250, 615))

	# orbs + the DJ secret
	for pos: Vector2 in [Vector2(950, 390), Vector2(1080, 160), Vector2(1130, 160),
			Vector2(700, 560), Vector2(2450, 560)]:
		place(ORB.new(), pos)
	place(BurritoPickup.new(), Vector2(1180, 160))

	# save club + circuit
	var save := SavePoint.new()
	save.club_name = "THE WATCH PARTY"
	save.spawn_id = &"save"
	place(save, Vector2(700, 595))
	spawn_points[&"save"] = Vector2(650, 560)
	place(CircuitPhone.new(), Vector2(830, 615))

	# THE ALGORITHM
	if GameState.has_flag(&"boss_algorithm_defeated"):
		if not GameState.has_relic(&"discovery_module"):
			_spawn_reward()
		return
	_algo = ALGO.instantiate()
	place(_algo, Vector2(3320, 511))
	_algo.boss_defeated.connect(_on_algo_defeated)


func _physics_process(delta: float) -> void:
	super(delta)
	if _fight_started or _algo == null:
		return
	if player.global_position.x > 2950.0:
		_start_fight()


func _start_fight() -> void:
	_fight_started = true
	Juice.shake(5.0)
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("THE ALGORITHM\n\"An AI that determines success.\"")
		hud.show_boss("THE ALGORITHM", _algo.health)


func _on_algo_defeated() -> void:
	GameState.set_flag(&"boss_algorithm_defeated")
	SaveSystem.autosave()
	_spawn_reward()


func _spawn_reward() -> void:
	var relic: Area2D = RELIC.new()
	relic.relic_id = &"discovery_module"
	relic.display_name = "DISCOVERY MODULE"
	relic.desc_text = "Follower orbs home in on you. The feed comes to you now."
	relic.relic_color = Color(0.3, 1.0, 0.75)
	place(relic, Vector2(3320, 580))
