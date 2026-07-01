# influencer_hills.gd
# REGION 05: INFLUENCER HILLS (11_LEVEL_DESIGN_BIBLE)
# "If it isn't posted, it didn't happen." Satire: influencer culture.
# Palette: pastel luxury, overexposed whites, gold accents.
#
# Entered from the Courtside SKY COURT - contestants only (gated on
# chuckle_yucks_signed). The high route is the region's mechanical
# identity: 300px dash gaps (pure jump max ~234px, dash-jump ~378px).
# West: THE GOLDEN HOUR TERRACE - RING LIGHT QUEEN -> INFLUENCE RELIC.

extends RoomBase

const DISCIPLE := preload("res://scenes/enemies/ring_light_disciple.tscn")
const AMBASSADOR := preload("res://scenes/enemies/brand_ambassador.tscn")
const DRONE := preload("res://scenes/enemies/camera_drone.tscn")
const QUEEN := preload("res://scenes/enemies/ring_light_queen.tscn")
const COSTUME := preload("res://scripts/items/costume_pickup.gd")
const RELIC := preload("res://scripts/items/relic_pickup.gd")
const ORB := preload("res://scripts/items/follower_orb.gd")

const PASTEL := Color(0.93, 0.86, 0.82)
const GOLD := Color(0.9, 0.75, 0.35)
const POOL := Color(0.55, 0.85, 0.95)

var _queen: RingLightQueen = null
var _fight_started: bool = false


func _build() -> void:
	spawn_points = {
		&"default": Vector2(3650, 560),    # from the Courtside sky court
		&"from_estates": Vector2(420, 560),  # back from Special Estates
		&"from_celebrity": Vector2(780, 560),
		&"from_castle": Vector2(2560, 560),
	}
	camera_rect = Rect2(-280, -900, 4160, 2200)
	kill_y = 1200.0

	solid(-280, -700, 80, 1560, PASTEL.darkened(0.3))
	solid(3800, -700, 80, 1560, PASTEL.darkened(0.3))
	solid(-200, 660, 4000, 200, PASTEL)

	# ---- THE GOLDEN HOUR TERRACE (boss zone, west: x < 900) -----------
	decor(880, 240, 24, 420, GOLD)
	decor(150, 300, 160, 360, PASTEL.lightened(0.1))  # the villa
	sign_label(Vector2(950, 520), "THE GOLDEN HOUR TERRACE\nSunlight by appointment.", 13)

	# ---- mansions ------------------------------------------------------
	for x in [1700.0, 2500.0, 3200.0]:
		decor(x, 380, 240, 280, PASTEL.lightened(0.08))
		decor(x + 30.0, 410, 60, 90, POOL.darkened(0.1))  # picture windows

	# ---- the high route: dash gaps (the region's lesson) ---------------
	solid(3350, 540, 100, 20, GOLD)   # step up (120)
	solid(3220, 440, 100, 20, GOLD)   # step up (100)
	solid(2900, 360, 220, 20, GOLD)   # plat A
	solid(2380, 360, 220, 20, GOLD)   # plat B - 300px gap from A
	solid(1860, 360, 220, 20, GOLD)   # plat C - 300px gap from B
	sign_label(Vector2(2950, 310), "(mind the gap. post about it.)", 12)

	# ---- the INFINITY POOL pocket (George): drop off plat C ------------
	solid(1280, 420, 50, 240, PASTEL.darkened(0.2))
	solid(1450, 420, 50, 240, PASTEL.darkened(0.2))
	decor(1330, 620, 120, 40, POOL)
	sign_label(Vector2(1300, 370), "INFINITY POOL (results may vary)", 12)

	# graffiti / sponsored vandalism
	sign_label(Vector2(2100, 600), "\"IF IT ISN'T POSTED, IT DIDN'T HAPPEN\"", 13)
	sign_label(Vector2(2950, 600), "ILLUMINEPSTEINS AREN'T REAL\n(paid partnership)", 12)
	sign_label(Vector2(3550, 500), "INFLUENCER HILLS\nEverything is perfect. Too perfect.")


func _populate() -> void:
	# west, past the Queen: the private road (story-gated on the whisper)
	var estates := Door.new()
	estates.door_label = "PRIVATE ROAD"
	estates.target_scene = "res://scenes/levels/special_estates.tscn"
	estates.target_spawn = &"default"
	estates.required_flag = &"heard_whisper"
	estates.flag_gate_line = "(A private road behind the terrace. Unmarked. You don't know what's down it yet - and nothing's told you to look.)"
	place(estates, Vector2(350, 605))

	# east: back to the sky court
	var east := Door.new()
	east.door_label = "SKY COURT →"
	east.target_scene = "res://scenes/levels/courtside_kingdom.tscn"
	east.target_spawn = &"from_hills"
	place(east, Vector2(3720, 605))

	# the high route reward: VERIFIED
	if not GameState.costumes_owned.has("verified"):
		var costume: Area2D = COSTUME.new()
		costume.costume_id = &"verified"
		costume.display_name = "VERIFIED"
		costume.bonus_text = "Artificial status. Follower gates take you 25% more seriously."
		costume.garment_color = Color(0.2, 0.55, 0.95)
		place(costume, Vector2(1930, 310))

	# THE GATED COMMUNITY: Celebrity Estates. Canon gates celebrity
	# access by follower count (50k at world scale; 400 at ours - logged).
	var celebrity := Door.new()
	celebrity.door_label = "GATED COMMUNITY"
	celebrity.target_scene = "res://scenes/levels/celebrity_estates.tscn"
	celebrity.target_spawn = &"default"
	celebrity.min_followers = 400
	place(celebrity, Vector2(700, 605))

	# THE CONTENT CASTLE (BOSS_009): the mansion that streams itself
	var castle := Door.new()
	castle.door_label = "THE CONTENT CASTLE"
	castle.target_scene = "res://scenes/levels/castle_interior.tscn"
	castle.target_spawn = &"default"
	place(castle, Vector2(2480, 605))

	# George, cleaning the infinity pool
	var george := GeorgeNPC.new()
	george.encounter_flag = &"george_hills"
	george.first_dialogue = [
		{"speaker": "DA'HERM", "text": "You clean pools now?"},
		{"speaker": "GEORGE", "text": "This one. Nobody swims in it."},
		{"speaker": "DA'HERM", "text": "Then why clean it?"},
		{"speaker": "GEORGE", "text": "It photographs better."},
	]
	george.lines = ["Nice light today.", "Hm."]
	place(george, Vector2(1380, 600))

	# the locals
	var sam := NPCBase.new()
	sam.npc_name = "SELFIE SAM"
	sam.body_color = Color(0.95, 0.7, 0.6)
	sam.lines = ["Take another one.", "I haven't actually SEEN the sunset in years. But I have it.", "Hold on — golden hour. GOLDEN HOUR."]
	place(sam, Vector2(2800, 615))

	var tina := NPCBase.new()
	tina.npc_name = "TREND CHASER TINA"
	tina.body_color = Color(0.7, 0.85, 0.95)
	tina.lines = ["This one's gonna blow up.", "The last one was gonna blow up too. The wind changed.", "Have you heard about the island parties? ...Forget I said that."]
	place(tina, Vector2(1700, 615))

	# the ecosystem
	place(DISCIPLE.instantiate(), Vector2(2200, 560))
	place(DISCIPLE.instantiate(), Vector2(3000, 560))
	place(AMBASSADOR.instantiate(), Vector2(1500, 560))
	place(AMBASSADOR.instantiate(), Vector2(2650, 560))
	place(DRONE.instantiate(), Vector2(2640, 280))

	# orbs along the dash route
	for pos: Vector2 in [Vector2(2750, 320), Vector2(2230, 320), Vector2(2010, 320),
			Vector2(1390, 480), Vector2(3280, 400)]:
		place(ORB.new(), pos)

	# save club + circuit
	var save := SavePoint.new()
	save.club_name = "THE FILTER"
	save.spawn_id = &"save"
	place(save, Vector2(3100, 595))
	spawn_points[&"save"] = Vector2(3050, 560)
	place(CircuitPhone.new(), Vector2(3230, 615))

	# the Queen
	if GameState.has_flag(&"boss_queen_defeated"):
		if not GameState.has_relic(&"influence_relic"):
			_spawn_reward()
		return
	_queen = QUEEN.instantiate()
	_queen.arena_left = 60.0
	_queen.arena_right = 840.0
	place(_queen, Vector2(420, 530))
	_queen.boss_defeated.connect(_on_queen_defeated)


func _physics_process(delta: float) -> void:
	super(delta)
	if _fight_started or _queen == null:
		return
	if player.global_position.x < 840.0:
		_start_fight()


func _start_fight() -> void:
	_fight_started = true
	Juice.shake(5.0)
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("RING LIGHT QUEEN\n\"Lives entirely on camera.\"")
		hud.show_boss("RING LIGHT QUEEN", _queen.health)


func _on_queen_defeated() -> void:
	GameState.set_flag(&"boss_queen_defeated")
	SaveSystem.autosave()
	_spawn_reward()


func _spawn_reward() -> void:
	var relic: Area2D = RELIC.new()
	relic.relic_id = &"influence_relic"
	relic.display_name = "INFLUENCE RELIC"
	relic.desc_text = "+25% Follower gain. Influence, apparently, is transferable."
	relic.relic_color = Color(1, 0.85, 0.5)
	place(relic, Vector2(420, 580))
