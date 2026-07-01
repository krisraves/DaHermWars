# content_cove.gd
# ILLUMINEPSTEIN ISLAND — CONTENT COVE. Elite content creators at the
# top of the funnel. The ILLUMINEPSTEIN INITIATE costume hangs in the
# robing room - cult security barely notices its own.

extends RoomBase

const PRIEST := preload("res://scenes/enemies/sponsor_priest.tscn")
const ACOLYTE := preload("res://scenes/enemies/executive_acolyte.tscn")
const COSTUME := preload("res://scripts/items/costume_pickup.gd")
const ORB := preload("res://scripts/items/follower_orb.gd")

const GOLD := Color(0.8, 0.66, 0.28)
const PURPLE := Color(0.3, 0.2, 0.42)


func _build() -> void:
	spawn_points = {
		&"default": Vector2(150, 560),       # from the Marina
		&"from_pyramid": Vector2(2750, 560),
	}
	camera_rect = Rect2(-280, -900, 3560, 2200)
	kill_y = 1200.0

	solid(-280, -700, 80, 1560, PURPLE.darkened(0.4))
	solid(3000, -700, 80, 1560, PURPLE.darkened(0.4))
	solid(-200, 660, 3200, 200, PURPLE.darkened(0.25))

	# creator cabanas
	for x in [500.0, 1200.0, 1900.0]:
		decor(x, 420, 280, 240, PURPLE.lightened(0.1))
		decor(x + 30.0, 450, 90, 20, GOLD)
	sign_label(Vector2(540, 478), "STUDIO CABANA — OCCUPIED FOREVER", 12)

	# the robing room route (steps, then a dash gap - 300px)
	solid(900, 540, 100, 20, GOLD.darkened(0.2))
	solid(1050, 440, 100, 20, GOLD.darkened(0.2))
	solid(1200, 340, 180, 20, GOLD.darkened(0.2))
	solid(1680, 340, 180, 20, GOLD.darkened(0.2))   # 300px gap: dash-jump
	sign_label(Vector2(1700, 290), "ROBING ROOM (members)", 12)

	sign_label(Vector2(300, 500), "CONTENT COVE\nEverything is beautiful. Everything is expensive.\nEverything feels wrong.", 13)
	sign_label(Vector2(2400, 600), "\"THE PYRAMID HAS A GUEST LIST\"\n(here, it's not graffiti. it's signage.)", 12)


func _populate() -> void:
	var west := Door.new()
	west.door_label = "← VIP MARINA"
	west.target_scene = "res://scenes/levels/vip_marina.tscn"
	west.target_spawn = &"from_cove"
	place(west, Vector2(60, 605))

	var east := Door.new()
	east.door_label = "THE LAUGHING PYRAMID →"
	east.target_scene = "res://scenes/levels/laughing_pyramid.tscn"
	east.target_spawn = &"default"
	place(east, Vector2(2900, 605))

	# the costume: ILLUMINEPSTEIN INITIATE
	if not GameState.costumes_owned.has("illuminepstein_initiate"):
		var robes: Area2D = COSTUME.new()
		robes.costume_id = &"illuminepstein_initiate"
		robes.display_name = "ILLUMINEPSTEIN INITIATE"
		robes.bonus_text = "Outer-circle robes. Cult security barely notices its own."
		robes.garment_color = Color(0.35, 0.25, 0.45)
		place(robes, Vector2(1740, 290))

	# George, bartender
	var george := GeorgeNPC.new()
	george.encounter_flag = &"george_cove"
	george.first_dialogue = [
		{"speaker": "DA'HERM", "text": "What's good here?"},
		{"speaker": "GEORGE", "text": "Nothing. It's all very expensive, though."},
		{"speaker": "DA'HERM", "text": "Then why tend the bar?"},
		{"speaker": "GEORGE", "text": "People talk to bartenders. Somebody should listen."},
	]
	george.lines = ["Top shelf's a lie.", "Hm."]
	place(george, Vector2(2250, 615))

	# Sponsor Priest Victor (NPC_BIBLE)
	var victor := NPCBase.new()
	victor.npc_name = "SPONSOR PRIEST VICTOR"
	victor.body_color = Color(0.5, 0.4, 0.15)
	victor.lines = ["What's the revenue model?", "Even attention tithes, friend. EVERYTHING tithes.",
		"(exhausted) Between us? I haven't laughed since the IPO."]
	place(victor, Vector2(800, 615))

	place(PRIEST.instantiate(), Vector2(1500, 560))
	place(PRIEST.instantiate(), Vector2(2500, 560))
	place(ACOLYTE.instantiate(), Vector2(700, 560))
	place(ACOLYTE.instantiate(), Vector2(2100, 560))

	for pos: Vector2 in [Vector2(1250, 300), Vector2(1730, 300), Vector2(950, 500),
			Vector2(2650, 560)]:
		place(ORB.new(), pos)

	var save := SavePoint.new()
	save.club_name = "THE GREEN ROOM"
	save.spawn_id = &"save"
	place(save, Vector2(2350, 595))
	spawn_points[&"save"] = Vector2(2400, 560)
	place(CircuitPhone.new(), Vector2(2480, 615))
