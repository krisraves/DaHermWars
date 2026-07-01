# courtside_kingdom.gd
# REGION 03: COURTSIDE KINGDOM (11_LEVEL_DESIGN_BIBLE)
# "Ball don't lie." Streetball mythology; satire target:
# "I could've gone pro" culture.
# Palette: basketball orange, teal, concrete gray, bright graffiti.
#
# East door <-> Homeless District. West, past the Cathedral Court
# (KING CROSSOVER, 3 phases -> AIR CROSSOVER double jump), the door
# to Podcast Wasteland. Bounce pads introduce vertical play; the
# SKY COURT holds the BASKETBALL PROPHET costume; George refs a
# game nobody is playing, in a pocket you drop into.

extends RoomBase

const BALL_HOG := preload("res://scenes/enemies/ball_hog.tscn")
const SNEAKERHEAD := preload("res://scenes/enemies/sneakerhead.tscn")
const KING := preload("res://scenes/enemies/king_crossover.tscn")
const ABILITY_PICKUP := preload("res://scenes/items/flame_dash_pickup.tscn")
const COSTUME := preload("res://scripts/items/costume_pickup.gd")
const ORB := preload("res://scripts/items/follower_orb.gd")

const CONCRETE := Color(0.32, 0.32, 0.35)
const COURT := Color(0.55, 0.32, 0.18)
const TEAL := Color(0.1, 0.5, 0.5)
const HOOP := Color(0.9, 0.45, 0.1)

var _king: KingCrossover = null
var _fight_started: bool = false


func _build() -> void:
	spawn_points = {
		&"default": Vector2(4150, 560),       # from Homeless District (east)
		&"from_wasteland": Vector2(150, 560),  # from Podcast Wasteland (west)
		&"from_hills": Vector2(2700, -110),    # back from Influencer Hills
	}
	camera_rect = Rect2(-280, -900, 4760, 2200)
	kill_y = 1200.0

	solid(-280, -700, 80, 1560, CONCRETE)
	solid(4400, -700, 80, 1560, CONCRETE)
	solid(-200, 660, 4600, 200, COURT)

	# ---- Cathedral Court (boss zone, west: x < 900) ------------------
	decor(870, 200, 30, 460, TEAL)  # the arch
	decor(120, 360, 18, 300, HOOP)  # the sacred rim pole
	decor(80, 340, 100, 16, HOOP)
	sign_label(Vector2(950, 520), "THE CATHEDRAL COURT\nNobody's beaten the King since '94.", 13)

	# ---- main courts: hoops, towers, bounce pads ----------------------
	for x in [1500.0, 2400.0, 3300.0]:
		decor(x, 380, 16, 280, Color(0.3, 0.3, 0.34))
		decor(x - 40.0, 360, 96, 14, HOOP)

	# vertical play: bounce pad chains up the apartment towers
	# (pads sit OFFSET from the platforms above - rise clear, drift on)
	solid(1900, 360, 200, 28, CONCRETE)
	solid(2350, 240, 200, 28, CONCRETE)   # dash-jump from the 1900 platform
	solid(3150, 320, 200, 28, CONCRETE)

	# ---- SKY COURT (costume route: pad -> platform -> pad -> sky) -----
	solid(2450, -60, 360, 26, TEAL)
	# pocket entry steps (120px rises - single-jump verified)
	solid(1500, 540, 90, 20, CONCRETE)
	solid(1390, 440, 90, 20, CONCRETE)
	sign_label(Vector2(2480, -110), "SKY COURT — invite only", 12)

	# ---- George's pocket: drop in from the tower above ---------------
	solid(1180, 200, 60, 460, CONCRETE)   # pocket left wall
	solid(1330, 380, 60, 280, CONCRETE)   # pocket right wall (lower: drop in)
	sign_label(Vector2(1200, 150), "(a whistle echoes below)", 12)

	# ---- DJ-gated stash: 240px above the 3150 tower platform ------------
	# (single jump max ~132px; double ~250px - the gate is the lesson)
	solid(3000, 80, 160, 20, TEAL)
	sign_label(Vector2(3010, 30), "(seriously, how?)", 12)

	# graffiti
	sign_label(Vector2(1700, 600), "\"BALL DON'T LIE\"", 13)
	sign_label(Vector2(2900, 600), "RIP MID-RANGE 1987–2014", 13)
	sign_label(Vector2(3900, 520), "COURTSIDE KINGDOM\nEvery legend here invented basketball.")


func _populate() -> void:
	# doors
	var east := Door.new()
	east.door_label = "HOMELESS DISTRICT →"
	east.target_scene = "res://scenes/levels/homeless_district.tscn"
	east.target_spawn = &"from_courtside"
	place(east, Vector2(4280, 605))

	var west := Door.new()
	west.door_label = "← PODCAST WASTELAND"
	west.target_scene = "res://scenes/levels/podcast_wasteland.tscn"
	west.target_spawn = &"default"
	place(west, Vector2(40, 605))

	# SKY COURT door: INFLUENCER HILLS (contestants only - the M7 gate)
	var hills := Door.new()
	hills.door_label = "THE HILLS — VIP"
	hills.target_scene = "res://scenes/levels/influencer_hills.tscn"
	hills.target_spawn = &"default"
	hills.required_flag = &"chuckle_yucks_signed"
	hills.flag_gate_line = "CLIPBOARD ANGEL: \"Are you on the list? The Hills are contestants only. Chuckle Yucks or go home.\""
	place(hills, Vector2(2740, -115))

	# bounce pads
	place(BouncePad.new(), Vector2(1820, 640))   # ground -> 1900 platform
	place(BouncePad.new(), Vector2(2300, 225))   # 2350 platform -> SKY COURT
	place(BouncePad.new(), Vector2(3450, 640))   # ground -> 3150 platform

	# SKY COURT costume: BASKETBALL PROPHET
	if not GameState.costumes_owned.has("basketball_prophet"):
		var prophet: Area2D = COSTUME.new()
		prophet.costume_id = &"basketball_prophet"
		prophet.display_name = "BASKETBALL PROPHET"
		prophet.bonus_text = "Jump height + air control. Players assume you can hoop."
		prophet.garment_color = Color(0.1, 0.55, 0.55)
		place(prophet, Vector2(2620, -110))

	# George, refereeing nothing, in the pocket
	var george := GeorgeNPC.new()
	george.encounter_flag = &"george_courtside"
	george.first_dialogue = [
		{"speaker": "DA'HERM", "text": "You ref these games?"},
		{"speaker": "GEORGE", "text": "Somebody has to watch."},
		{"speaker": "DA'HERM", "text": "Do you ever call fouls?"},
		{"speaker": "GEORGE", "text": "Mostly I just watch."},
	]
	george.lines = ["Good game.", "Hm."]
	place(george, Vector2(1285, 600))

	# the locals
	var trevor := NPCBase.new()
	trevor.npc_name = "TANK TOP TREVOR"
	trevor.body_color = Color(0.85, 0.85, 0.9)
	trevor.lines = ["Coach screwed me.", "I had a 40-inch vertical. HAD.", "One tryout. ONE. That's all I needed."]
	place(trevor, Vector2(3000, 615))

	var historian := NPCBase.new()
	historian.npc_name = "PLAYGROUND HISTORIAN"
	historian.body_color = Color(0.5, 0.42, 0.35)
	historian.lines = ["You know who used to play here?", "Half these legends never existed. The important half.", "The King? Oh, the King is real. Unfortunately."]
	place(historian, Vector2(2200, 615))

	# enemies
	place(BALL_HOG.instantiate(), Vector2(1700, 560))
	place(BALL_HOG.instantiate(), Vector2(3550, 560))
	place(SNEAKERHEAD.instantiate(), Vector2(1960, 300))
	place(SNEAKERHEAD.instantiate(), Vector2(2900, 560))

	# orbs along the vertical routes
	for pos: Vector2 in [Vector2(1990, 300), Vector2(2440, 180), Vector2(2550, -120),
			Vector2(2750, -120), Vector2(3230, 260), Vector2(1280, 320)]:
		place(ORB.new(), pos)

	# DJ-gated stash (backtracking payoff)
	for pos: Vector2 in [Vector2(3040, 40), Vector2(3090, 40)]:
		place(ORB.new(), pos)
	place(BurritoPickup.new(), Vector2(3140, 40))

	# save club + circuit
	var save := SavePoint.new()
	save.club_name = "COURTSIDE CHUCKLES"
	save.spawn_id = &"save"
	place(save, Vector2(3750, 595))
	spawn_points[&"save"] = Vector2(3700, 560)
	place(CircuitPhone.new(), Vector2(3620, 615))

	# the King
	if GameState.has_flag(&"boss_king_defeated"):
		if not GameState.has_double_jump:
			_spawn_reward()
		return
	_king = KING.instantiate()
	_king.arena_left = 60.0
	_king.arena_right = 840.0
	place(_king, Vector2(400, 520))
	_king.boss_defeated.connect(_on_king_defeated)


func _physics_process(delta: float) -> void:
	super(delta)
	if _fight_started or _king == null:
		return
	if player.global_position.x < 820.0:
		_start_fight()


func _start_fight() -> void:
	_fight_started = true
	Juice.shake(5.0)
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("KING CROSSOVER\n\"Possibly invented basketball.\"")
		hud.show_boss("KING CROSSOVER", _king.health)


func _on_king_defeated() -> void:
	GameState.set_flag(&"boss_king_defeated")
	SaveSystem.autosave()
	_spawn_reward()


func _spawn_reward() -> void:
	var pickup := ABILITY_PICKUP.instantiate()
	pickup.ability = &"double_jump"
	pickup.banner_text = "AIR CROSSOVER — DOUBLE JUMP\nJump again mid-air. The King's footwork, your flame.\nSomewhere, a high ledge just became a place."
	place(pickup, Vector2(420, 590))
