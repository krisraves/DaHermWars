# open_mic_alley.gd
# REGION 02: OPEN MIC ALLEY (11_LEVEL_DESIGN_BIBLE)
# "One good set changes everything."
# Palette: neon pink, purple, black (09_ART_BIBLE).
#
# Contains: the save club (The Chuckle Hut), comics defending their
# stage time, the basement door (boss route), and - after the boss -
# the SLICE FINALE: the Chuckle Yucks broadcast, exactly as scripted
# in 13_VERTICAL_SLICE_SPEC. George sweeps in the background.
# Nobody notices him.

extends RoomBase

const COMIC := preload("res://scenes/enemies/open_mic_comic.tscn")
const ORB := preload("res://scripts/items/follower_orb.gd")

const ASPHALT := Color(0.16, 0.13, 0.2)
const CLUB := Color(0.22, 0.12, 0.24)
const NEON_PINK := Color(1.0, 0.25, 0.6)
const NEON_PURPLE := Color(0.6, 0.3, 1.0)

var _finale_started: bool = false


func _build() -> void:
	spawn_points = {
		&"default": Vector2(120, 560),
		&"save": Vector2(760, 560),
		&"from_basement": Vector2(2380, 560),
		&"from_tunnel": Vector2(350, 560),
		&"from_tower": Vector2(1660, 560),
	}
	camera_rect = Rect2(-280, -700, 3000, 2000)
	kill_y = 1200.0

	solid(-280, -700, 80, 1560, CLUB)
	solid(2640, -700, 80, 1560, CLUB)
	solid(-200, 660, 2840, 200, ASPHALT)

	# club facades + neon
	decor(180, 360, 300, 300, CLUB)
	decor(200, 380, 120, 40, NEON_PINK)
	sign_label(Vector2(206, 388), "GIGGLE PIT", 15)
	decor(1100, 320, 340, 340, CLUB)
	decor(1130, 350, 200, 40, NEON_PURPLE)
	sign_label(Vector2(1138, 358), "LAUGH LAUNDROMAT", 14)

	# rooftop hop line with orbs
	solid(420, 470, 140, 24, CLUB)
	solid(640, 360, 140, 24, CLUB)

	# THE BIG SCREEN (finale stage)
	decor(1850, 220, 460, 260, Color(0.08, 0.08, 0.1))
	decor(1870, 240, 420, 220, Color(0.2, 0.22, 0.3))
	sign_label(Vector2(1980, 330), "[ NO SIGNAL ]", 18)

	# flyers everywhere (open mic culture)
	sign_label(Vector2(540, 600), "OPEN MIC TONITE\n(sign-up closed)", 12)
	sign_label(Vector2(1550, 600), "COMEDY? COMEDY.\nFREE-ISH", 12)

	sign_label(Vector2(30, 520), "OPEN MIC ALLEY\n\"One good set changes everything.\"")
	sign_label(Vector2(2330, 480), "THE BASEMENT\n(something's been bombing\ndown there for ten years)", 13)


func _populate() -> void:
	# save club
	var save := SavePoint.new()
	save.club_name = "THE CHUCKLE HUT"
	place(save, Vector2(800, 595))

	# STUDIO TUNNEL: drops into the Podcast Wasteland (one-way until
	# double jump - the world's first loop)
	var tunnel := Door.new()
	tunnel.door_label = "STUDIO TUNNEL ↓"
	tunnel.target_scene = "res://scenes/levels/podcast_wasteland.tscn"
	tunnel.target_spawn = &"from_alley"
	place(tunnel, Vector2(320, 605))

	# CORPORATE MEDIA TOWER lobby door ("security respects metrics")
	var tower := Door.new()
	tower.door_label = "MEDIA TOWER LOBBY"
	tower.target_scene = "res://scenes/levels/corporate_tower.tscn"
	tower.target_spawn = &"default"
	tower.min_followers = 250
	tower.gate_speaker = "TOWER SECURITY"
	tower.gate_line = "Building access starts at %d followers. It's policy. The policy is also a metric."
	place(tower, Vector2(1600, 605))

	# CHUCKLE YUCKS sign-up kiosk, under the big screen
	place(ChuckleKiosk.new(), Vector2(1950, 615))

	# Comedy Circuit phone outside the club
	place(CircuitPhone.new(), Vector2(640, 615))

	# FOLDING CHAIR stashed on the rooftop hop line
	var chair := WeaponPickup.new()
	chair.weapon_id = &"folding_chair"
	chair.auto_equip = false
	place(chair, Vector2(700, 320))

	# club owner - overworked, cynical, necessary (04_CHARACTER_BIBLE)
	var owner := NPCBase.new()
	owner.npc_name = "CLUB OWNER"
	owner.body_color = Color(0.4, 0.4, 0.45)
	owner.lines = [
		"You want stage time? Everybody wants stage time.",
		"Handle whatever's bombing in my basement and we'll talk.",
		"Ten years. TEN YEARS of muffled crowd work through my floor.",
	]
	place(owner, Vector2(980, 615))

	# comics defending the alley
	place(COMIC.instantiate(), Vector2(1300, 560))
	place(COMIC.instantiate(), Vector2(1650, 560))
	place(COMIC.instantiate(), Vector2(2100, 560))

	for pos: Vector2 in [Vector2(480, 430), Vector2(700, 320), Vector2(1450, 600)]:
		place(ORB.new(), pos)

	# basement door (boss route)
	var basement := Door.new()
	basement.door_label = "THE BASEMENT ↓"
	basement.target_scene = "res://scenes/levels/boss_arena.tscn"
	basement.target_spawn = &"default"
	place(basement, Vector2(2420, 605))

	# back to the district
	var back := Door.new()
	back.door_label = "← HOMELESS DISTRICT"
	back.target_scene = "res://scenes/levels/homeless_district.tscn"
	back.target_spawn = &"from_alley"
	place(back, Vector2(40, 605))

	# after the boss: George sweeps near the screen. Just a janitor.
	if GameState.has_flag(&"boss_disgraced_defeated"):
		var george := GeorgeNPC.new()
		george.lines = ["Big night.", "Hm."]
		place(george, Vector2(2250, 600))


func _physics_process(delta: float) -> void:
	super(delta)
	# SLICE FINALE: the broadcast triggers when the player approaches
	# the big screen after clearing the basement.
	if _finale_started:
		return
	if not GameState.has_flag(&"boss_disgraced_defeated"):
		return
	if GameState.has_flag(&"finale_seen"):
		return
	if absf(player.global_position.x - 2080.0) < 220.0:
		_run_finale()


func _run_finale() -> void:
	_finale_started = true
	GameState.set_flag(&"finale_seen")
	Juice.shake(4.0)
	DialogueSystem.start([
		{"speaker": "", "text": "(Every screen in the alley flickers on at once.)"},
		{"speaker": "TUFF TIDDY", "text": "OUT EAST! Are you ready for the BIGGEST comedy competition in HISTORY?"},
		{"speaker": "TUFF TIDDY", "text": "CHUCKLE YUCKS! One winner. One SPECIAL. Fame! Followers! Celebrity access!"},
		{"speaker": "TUFF TIDDY", "text": "People always ask me how I became successful. Write that down. That's gold."},
		{"speaker": "BRITTNEY NUTTINGS", "text": "(smiling exactly the right amount) Sign-ups open now."},
		{"speaker": "RAVES SUPREME", "text": "...We're gonna be rich."},
		{"speaker": "DA'HERM", "text": "You're damn right."},
		{"speaker": "", "text": "(Behind the crowd, a janitor sweeps the alley. Nobody notices him. He's smiling.)"},
	])
	DialogueSystem.finished.connect(_show_slice_banner, CONNECT_ONE_SHOT)


func _show_slice_banner() -> void:
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("VERTICAL SLICE COMPLETE\nWho is George? What is Chuckle Yucks? What happens next?")
