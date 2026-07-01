# homeless_district.gd
# REGION 01: HOMELESS DISTRICT (11_LEVEL_DESIGN_BIBLE)
# "Everybody starts somewhere."
# Teaches movement, combat, Followers, and the comedy tone - without
# a text tutorial (13_VERTICAL_SLICE_SPEC: learning feels natural).
#
# Layout, left to right:
#   spawn -> busk corner -> George's alley (a wall-jump lesson in
#   disguise: you drop in off the store roof, you wall-jump out) ->
#   rooftop route up to the TRASH BAG TUXEDO -> enemies + second busk
#   spot -> Raves -> the Follower-gated door to Open Mic Alley.
#
# Palette (09_ART_BIBLE / Out East): orange streetlights, cold blues,
# brick reds, asphalt grays.

extends RoomBase

const COMIC := preload("res://scenes/enemies/open_mic_comic.tscn")
const COSTUME_PICKUP := preload("res://scripts/items/costume_pickup.gd")
const ORB := preload("res://scripts/items/follower_orb.gd")

const ASPHALT := Color(0.24, 0.23, 0.27)
const BRICK := Color(0.42, 0.22, 0.18)
const BRICK_DARK := Color(0.3, 0.16, 0.14)
const CRATE := Color(0.45, 0.33, 0.18)


func _build() -> void:
	spawn_points = {
		&"default": Vector2(120, 560),
		&"from_alley": Vector2(3040, 560),
		&"from_courtside": Vector2(120, 560),
		&"from_theater": Vector2(2640, 560),
	}
	camera_rect = Rect2(-280, -700, 3560, 2000)
	kill_y = 1200.0

	# boundaries + ground
	solid(-280, -700, 80, 1560, BRICK_DARK)
	solid(3200, -700, 80, 1560, BRICK_DARK)
	solid(-200, 660, 3400, 200, ASPHALT)

	# --- George's alley: tall wall + convenience store, 60px gap between
	solid(250, 260, 60, 400, BRICK_DARK)        # alley wall (drop in, wall-jump out)
	solid(370, 400, 240, 260, BRICK)            # convenience store (roof at 400)
	decor(380, 430, 90, 40, Color(0.9, 0.85, 0.3))   # store sign
	sign_label(Vector2(382, 440), "24HR", 14)

	# crates up to the store roof
	solid(630, 560, 100, 100, CRATE)
	solid(650, 450, 90, 20, CRATE)

	# DJ retro-gate ledge: visible from day one, reachable after the King
	solid(1180, 70, 180, 20, CRATE)
	sign_label(Vector2(1190, 20), "(seriously, how?)", 12)

	# --- rooftop route to the costume
	solid(840, 480, 260, 180, BRICK)            # building 2
	solid(1230, 360, 240, 300, BRICK_DARK)      # building 3
	solid(1210, 240, 150, 20, CRATE)            # hidden ledge w/ costume

	# street furniture
	decor(1700, 560, 90, 100, Color(0.2, 0.3, 0.4))   # dumpster
	decor(2050, 360, 16, 300, Color(0.3, 0.3, 0.32))  # streetlight pole
	decor(2030, 340, 56, 24, Color(1.0, 0.65, 0.2, 0.9))

	# graffiti (environmental storytelling is mandatory - 09_ART_BIBLE)
	sign_label(Vector2(900, 600), "\"EVERYBODY STARTS SOMEWHERE\"", 13)
	sign_label(Vector2(2400, 600), "CHUCKLE YUCKS IS A PSYOP", 13)

	sign_label(Vector2(30, 520), "OUT EAST — HOMELESS DISTRICT\nMove A/D · Jump SPACE · Punch J · Talk E")
	sign_label(Vector2(300, 200), "(something's back there)", 13)


func _populate() -> void:
	# George, in the gap behind the store. Nobody notices him. As usual.
	place(GeorgeNPC.new(), Vector2(340, 600))

	# busking
	var busk1 := BuskSpot.new()
	place(busk1, Vector2(800, 630))
	var busk2 := BuskSpot.new()
	place(busk2, Vector2(1850, 630))

	# pedestrians (the recurring world joke walks among us)
	var ped := NPCBase.new()
	ped.npc_name = "PEDESTRIAN"
	ped.lines = ["I could do comedy.", "My cousin's funnier.", "Is the hat for money or is it a bit?"]
	place(ped, Vector2(1050, 620))

	# enemies
	place(COMIC.instantiate(), Vector2(1550, 560))
	place(COMIC.instantiate(), Vector2(2150, 560))

	# follower orbs - exploration pays
	for pos: Vector2 in [Vector2(700, 400), Vector2(960, 420), Vector2(1330, 300),
			Vector2(1280, 180), Vector2(2050, 600), Vector2(2600, 600)]:
		var orb := ORB.new()
		place(orb, pos)

	# the costume, on the hidden ledge
	if GameState.costume != &"trash_bag_tuxedo":
		var costume: Area2D = COSTUME_PICKUP.new()
		place(costume, Vector2(1285, 190))

	# secret weapon: RUBBER CHICKEN on top of George's alley wall.
	# Reaching it means wall-jumping the alley and landing on the wall
	# top - exploration pays in jokes (Pillar 2).
	var chicken := WeaponPickup.new()
	chicken.weapon_id = &"rubber_chicken"
	chicken.auto_equip = false
	place(chicken, Vector2(280, 225))

	# Raves, near the exit, mid-pitch as always
	place(RavesNPC.new(), Vector2(2750, 610))

	# the boarded theater door (opens from the far side first)
	var theater := Door.new()
	theater.door_label = "BOARDED DOOR"
	theater.target_scene = "res://scenes/levels/lost_theater.tscn"
	theater.target_spawn = &"from_district"
	theater.required_flag = &"theater_unlocked"
	theater.flag_gate_line = "(Boarded shut. From the other side, by the look of it.)"
	place(theater, Vector2(2700, 605))

	# west: COURTSIDE KINGDOM
	var west := Door.new()
	west.door_label = "← COURTSIDE KINGDOM"
	west.target_scene = "res://scenes/levels/courtside_kingdom.tscn"
	west.target_spawn = &"default"
	place(west, Vector2(-130, 605))

	# DJ retro-gate stash above the costume ledge (backtracking payoff)
	for pos: Vector2 in [Vector2(1210, 30), Vector2(1260, 30)]:
		place(ORB.new(), pos)
	place(BurritoPickup.new(), Vector2(1310, 30))

	# the Follower gate
	var door := Door.new()
	door.door_label = "OPEN MIC ALLEY →"
	door.target_scene = "res://scenes/levels/open_mic_alley.tscn"
	door.target_spawn = &"default"
	door.min_followers = 50
	place(door, Vector2(3080, 605))
