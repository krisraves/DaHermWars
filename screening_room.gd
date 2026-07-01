# vip_marina.gd
# ILLUMINEPSTEIN ISLAND — VIP MARINA (11_LEVEL_DESIGN_BIBLE)
# "Luxury arrivals." The most famous place nobody has ever seen
# (02_WORLD_BIBLE) - and it's real. Gold, purple, deep black.

extends RoomBase

const INITIATE := preload("res://scenes/enemies/illuminepstein_initiate.tscn")
const ORB := preload("res://scripts/items/follower_orb.gd")

const GOLD := Color(0.8, 0.66, 0.28)
const PURPLE := Color(0.28, 0.18, 0.4)
const NIGHT := Color(0.1, 0.08, 0.14)


func _build() -> void:
	spawn_points = {
		&"default": Vector2(200, 560),       # off the boat
		&"from_cove": Vector2(2750, 560),
	}
	camera_rect = Rect2(-280, -900, 3560, 2200)
	kill_y = 1200.0

	solid(-280, -700, 80, 1560, NIGHT)
	solid(3000, -700, 80, 1560, NIGHT)
	solid(-200, 660, 3200, 200, PURPLE.darkened(0.3))

	# the dock and the yachts
	decor(150, 560, 500, 100, GOLD.darkened(0.35))
	decor(700, 420, 380, 240, Color(0.92, 0.9, 0.88))
	decor(1250, 440, 340, 220, Color(0.88, 0.86, 0.85))
	sign_label(Vector2(760, 390), "M/Y 'WRITE-OFF'", 12)
	sign_label(Vector2(1290, 410), "M/Y 'CONTENT II'", 12)

	# the welcome arch
	decor(2000, 240, 30, 420, GOLD)
	decor(2160, 240, 30, 420, GOLD)
	sign_label(Vector2(2010, 200), "WELCOME, CONTESTANT\n(the sign knows your name)", 12)

	sign_label(Vector2(350, 500), "VIP MARINA\nIt was real the whole time.", 13)
	sign_label(Vector2(2500, 600), "(Boats come in full. They go back light.)", 12)


func _populate() -> void:
	# the boat home
	var boat := Door.new()
	boat.door_label = "THE BOAT — MAINLAND"
	boat.target_scene = "res://scenes/levels/special_estates.tscn"
	boat.target_spawn = &"from_dock"
	place(boat, Vector2(80, 605))

	# east: Content Cove
	var east := Door.new()
	east.door_label = "CONTENT COVE →"
	east.target_scene = "res://scenes/levels/content_cove.tscn"
	east.target_spawn = &"default"
	place(east, Vector2(2900, 605))

	# George, dockhand
	var george := GeorgeNPC.new()
	george.encounter_flag = &"george_marina"
	george.first_dialogue = [
		{"speaker": "DA'HERM", "text": "You work the docks too?"},
		{"speaker": "GEORGE", "text": "Boats come in full. Go back empty."},
		{"speaker": "DA'HERM", "text": "Empty of what?"},
		{"speaker": "GEORGE", "text": "Depends on the boat."},
	]
	george.lines = ["Tide's in.", "Hm."]
	place(george, Vector2(450, 615))

	# Initiate Greg (NPC_BIBLE)
	var greg := NPCBase.new()
	greg.npc_name = "INITIATE GREG"
	greg.body_color = Color(0.4, 0.3, 0.5)
	greg.lines = ["I'm moving up soon.", "They let me hold the rope last week. The ACTUAL rope.",
		"You're a contestant? Wild. I've never seen one come BACK before. I mean— moving up soon!"]
	place(greg, Vector2(1800, 615))

	place(INITIATE.instantiate(), Vector2(2300, 560))
	place(INITIATE.instantiate(), Vector2(2600, 560))

	for pos: Vector2 in [Vector2(900, 380), Vector2(2080, 560), Vector2(1500, 400)]:
		place(ORB.new(), pos)

	var save := SavePoint.new()
	save.club_name = "THE ARRIVALS LOUNGE"
	save.spawn_id = &"save"
	place(save, Vector2(1600, 595))
	spawn_points[&"save"] = Vector2(1550, 560)
	place(CircuitPhone.new(), Vector2(1700, 615))
