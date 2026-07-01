# comedy_underground.gd
# REGION 10: COMEDY UNDERGROUND (11_LEVEL_DESIGN_BIBLE / REG_010)
# "The forgotten comics." Satire: stolen material / hack culture.
# Abandoned clubs, closed venues, underground stages.
#
# Entered from THE UNDERGROUND CLUB (boss_arena), gated on the dark
# chapter - this is where Da'Herm goes looking for the people the
# machine forgot. Mid-region: THE STOLEN STAGE - HACK MASTER GENERAL
# -> THE HACK costume. A wall-jump chimney behind a peeling poster
# hides the SECRET CLUB (THE CROWD). Far east: stairs up to the
# Lost Theater District.

extends RoomBase

const COMIC := preload("res://scenes/enemies/open_mic_comic.tscn")
const THIEF := preload("res://scenes/enemies/joke_thief.tscn")
const HACK := preload("res://scenes/enemies/hack_master_general.tscn")
const COSTUME := preload("res://scripts/items/costume_pickup.gd")
const ORB := preload("res://scripts/items/follower_orb.gd")

const BRICK := Color(0.24, 0.18, 0.2)
const VELVET := Color(0.3, 0.16, 0.24)
const NEON_DEAD := Color(0.35, 0.3, 0.4)

var _boss: HackMasterGeneral = null
var _fight_started: bool = false


func _build() -> void:
	spawn_points = {
		&"default": Vector2(150, 560),       # from THE UNDERGROUND CLUB
		&"from_theater": Vector2(3250, 560),
		&"from_club": Vector2(1070, 235),    # back out of the Secret Club
	}
	camera_rect = Rect2(-280, -900, 3960, 2200)
	kill_y = 1200.0

	solid(-280, -700, 80, 1560, BRICK)
	solid(3400, -700, 80, 1560, BRICK)
	solid(-200, 660, 3600, 200, BRICK.darkened(0.2))

	# ---- dead venues -----------------------------------------------------
	for x in [500.0, 950.0, 2900.0]:
		decor(x, 400, 260, 260, BRICK.lightened(0.08))
		decor(x + 30.0, 430, 200, 30, NEON_DEAD)
	sign_label(Vector2(530, 458), "THE GIGGLE FACTORY (CLOSED)", 12)
	sign_label(Vector2(980, 458), "LAUGH TRACK LOUNGE (CLOSED)", 12)
	sign_label(Vector2(2930, 458), "COMEDY CELLAR CELLAR (CLOSED)", 12)

	# ---- the Secret Club chimney (hidden behind the poster) ---------------
	# Walk IN under the left wall stub (100px clearance), wall-jump the
	# shaft (1190..1290), exit left above the stub, land on the platform.
	solid(1150, 300, 40, 260, BRICK.lightened(0.05))  # left stub: y300-560
	solid(1290, 160, 40, 500, BRICK.lightened(0.05))  # right wall: full
	solid(1000, 280, 150, 20, BRICK.lightened(0.1))   # door platform
	decor(1140, 545, 130, 110, VELVET)                # the peeling poster
	sign_label(Vector2(1120, 600), "(The poster flutters. There's air behind it.)", 12)

	# ---- THE STOLEN STAGE (boss zone: 1800 < x < 3000) ---------------------
	decor(1820, 300, 20, 360, NEON_DEAD)
	decor(2980, 300, 20, 360, NEON_DEAD)
	sign_label(Vector2(2300, 500), "THE STOLEN STAGE\nEvery bit performed here belonged to someone else.", 13)

	# George's coat check pocket (drop in from the entry-side crates)
	solid(420, 520, 90, 20, BRICK.lightened(0.1))     # crate step
	solid(560, 420, 60, 240, BRICK.lightened(0.05))   # pocket right wall
	sign_label(Vector2(590, 380), "COAT CHECK", 12)

	sign_label(Vector2(250, 600), "(Down here, nobody asks for your follower count.)", 12)
	sign_label(Vector2(3300, 540), "STAIRS — LOST THEATER DISTRICT", 12)


func _populate() -> void:
	# west: back up to THE UNDERGROUND CLUB
	var west := Door.new()
	west.door_label = "← THE UNDERGROUND CLUB"
	west.target_scene = "res://scenes/levels/boss_arena.tscn"
	west.target_spawn = &"default"
	place(west, Vector2(60, 605))

	# the Secret Club door, top of the chimney
	var club := Door.new()
	club.door_label = "(an unmarked door)"
	club.target_scene = "res://scenes/levels/secret_club.tscn"
	club.target_spawn = &"default"
	place(club, Vector2(1070, 225))

	# east: stairs to the Lost Theater
	var stairs := Door.new()
	stairs.door_label = "LOST THEATER ↑"
	stairs.target_scene = "res://scenes/levels/lost_theater.tscn"
	stairs.target_spawn = &"default"
	place(stairs, Vector2(3320, 605))

	# George, coat check (drop into the pocket between the wall and venue)
	var george := GeorgeNPC.new()
	george.encounter_flag = &"george_underground"
	george.first_dialogue = [
		{"speaker": "DA'HERM", "text": "Coat check? Nobody's been here in years."},
		{"speaker": "GEORGE", "text": "Forty-one coats, still waiting."},
		{"speaker": "DA'HERM", "text": "Why keep them?"},
		{"speaker": "GEORGE", "text": "People come back. Sometimes it takes a while."},
	]
	george.lines = ["Forty-one.", "Hm."]
	place(george, Vector2(640, 615))

	# the forgotten
	var lifer := NPCBase.new()
	lifer.npc_name = "OPEN MIC LIFER"
	lifer.body_color = Color(0.5, 0.45, 0.5)
	lifer.lines = ["I bombed on that stage in '99. Best night of my life.",
		"The Hack Master took my airport bit. It wasn't even good. It was MINE.",
		"You hear about the room behind the poster? Don't punch anybody in there. Trust me."]
	place(lifer, Vector2(800, 615))

	# enemies
	place(COMIC.instantiate(), Vector2(1500, 560))
	place(COMIC.instantiate(), Vector2(2550, 560))
	place(THIEF.instantiate(), Vector2(1950, 560))
	place(THIEF.instantiate(), Vector2(2750, 560))

	# orbs
	for pos: Vector2 in [Vector2(460, 470), Vector2(1240, 420), Vector2(1100, 240),
			Vector2(2200, 560), Vector2(3100, 560)]:
		place(ORB.new(), pos)

	# save: THE BACK ROOM
	var save := SavePoint.new()
	save.club_name = "THE BACK ROOM"
	save.spawn_id = &"save"
	place(save, Vector2(1550, 595))
	spawn_points[&"save"] = Vector2(1620, 560)
	place(CircuitPhone.new(), Vector2(1700, 615))

	# HACK MASTER GENERAL
	if GameState.has_flag(&"boss_hack_defeated"):
		if not GameState.costumes_owned.has("the_hack"):
			_spawn_reward()
		return
	_boss = HACK.instantiate()
	_boss.arena_left = 1860.0
	_boss.arena_right = 2960.0
	place(_boss, Vector2(2400, 530))
	_boss.boss_defeated.connect(_on_boss_defeated)


func _physics_process(delta: float) -> void:
	super(delta)
	if _fight_started or _boss == null:
		return
	if player.global_position.x > 1860.0 and player.global_position.x < 2960.0:
		_start_fight()


func _start_fight() -> void:
	_fight_started = true
	Juice.shake(5.0)
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("HACK MASTER GENERAL\n\"Collector of stolen jokes.\"")
		hud.show_boss("HACK MASTER GENERAL", _boss.health)


func _on_boss_defeated() -> void:
	GameState.set_flag(&"boss_hack_defeated")
	SaveSystem.autosave()
	_spawn_reward()


func _spawn_reward() -> void:
	var costume: Area2D = COSTUME.new()
	costume.costume_id = &"the_hack"
	costume.display_name = "THE HACK"
	costume.bonus_text = "Stolen technique: +3 damage with every non-Flame weapon. Comics can tell."
	costume.garment_color = Color(0.45, 0.35, 0.55)
	place(costume, Vector2(2400, 590))
