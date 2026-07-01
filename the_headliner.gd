# celebrity_estates.gd
# REGION 08: CELEBRITY ESTATES (11_LEVEL_DESIGN / REGION_DATABASE)
# Theme: Empty Success. Satirical target: celebrity culture.
# "Mansions. Security checkpoints. Trophy rooms." Nobody is
# satisfied. Local saying: "Just one more deal."
#
# Deferred three times across the roadmap; paid in full here.
# Contains: the PAPARAZZI SWARM (red carpet ambush), the door to
# BRITTNEY'S ESTATE (the non-lethal duel), three canon NPCs, the
# RED CARPET ELITE costume, a hidden double-jump route to THE
# FORMER WINNER costume, and the 13th George.

extends RoomBase

const PAPARAZZO := preload("res://scenes/enemies/paparazzo.tscn")
const BODYGUARD := preload("res://scenes/enemies/celebrity_bodyguard.tscn")
const SWARM := preload("res://scenes/enemies/paparazzi_swarm.tscn")
const COSTUME := preload("res://scripts/items/costume_pickup.gd")
const RELIC := preload("res://scripts/items/relic_pickup.gd")
const ORB := preload("res://scripts/items/follower_orb.gd")

const GOLD := Color(0.85, 0.72, 0.35)
const IVORY := Color(0.88, 0.85, 0.78)
const EMERALD := Color(0.15, 0.4, 0.3)

var _swarm: PaparazziSwarm = null
var _fight_started: bool = false


func _build() -> void:
	spawn_points = {
		&"default": Vector2(180, 560),         # from Influencer Hills
		&"from_brittney": Vector2(2520, 560),
	}
	camera_rect = Rect2(-280, -900, 4260, 2200)
	kill_y = 1200.0

	solid(-280, -700, 80, 1560, EMERALD.darkened(0.4))
	solid(3900, -700, 80, 1560, EMERALD.darkened(0.4))
	solid(-200, 660, 4100, 200, IVORY.darkened(0.35))

	# mansions behind hedges and checkpoints
	for x in [600.0, 1500.0, 3100.0]:
		decor(x, 320, 420, 340, IVORY)
		decor(x + 40.0, 380, 80, 120, GOLD.darkened(0.3))     # gilt door
		decor(x - 60.0, 520, 40, 140, EMERALD)                # hedge
		decor(x + 440.0, 520, 40, 140, EMERALD)
	sign_label(Vector2(640, 290), "EST. WHENEVER MONEY WAS INVENTED", 12)
	sign_label(Vector2(3140, 290), "FOR SALE (AGAIN)", 12)

	# THE RED CARPET - the Swarm's ambush ground (x 2100-3000)
	decor(2100, 644, 900, 16, Color(0.7, 0.12, 0.18))
	decor(2080, 500, 24, 160, GOLD)   # stanchions
	decor(2990, 500, 24, 160, GOLD)
	sign_label(Vector2(2380, 470), "RED CARPET — TALENT ONLY\n(the carpet has opinions about who counts)", 12)

	# BRITTNEY'S estate sits past the carpet
	decor(2300, 280, 520, 200, IVORY.lightened(0.05))
	sign_label(Vector2(2440, 250), "NUTTINGS ESTATE", 12)

	# hidden route: double-jump ledges up the west mansion to the
	# trophy attic (THE FORMER WINNER costume) - 230px rises
	solid(880, 430, 130, 20, GOLD.darkened(0.2))
	solid(740, 200, 130, 20, GOLD.darkened(0.2))
	sign_label(Vector2(760, 150), "TROPHY ATTIC\n(dust on every shelf except one)", 12)

	# RED CARPET ELITE costume: stanchion-top ledge
	solid(3420, 420, 140, 20, GOLD)

	sign_label(Vector2(300, 500), "CELEBRITY ESTATES\nNobody is satisfied.", 13)
	sign_label(Vector2(1300, 600), "\"JUST ONE MORE DEAL\"", 13)
	sign_label(Vector2(3650, 600), "(every window is lit. nobody is home in any of the ways that count.)", 12)


func _populate() -> void:
	# back to the Hills
	var hills := Door.new()
	hills.door_label = "← INFLUENCER HILLS"
	hills.target_scene = "res://scenes/levels/influencer_hills.tscn"
	hills.target_spawn = &"from_celebrity"
	place(hills, Vector2(80, 605))

	# Brittney's estate (the duel)
	var estate := Door.new()
	estate.door_label = "NUTTINGS ESTATE"
	estate.target_scene = "res://scenes/levels/brittney_estate.tscn"
	estate.target_spawn = &"default"
	place(estate, Vector2(2560, 605))

	# costumes
	if not GameState.costumes_owned.has("red_carpet_elite"):
		var carpet: Area2D = COSTUME.new()
		carpet.costume_id = &"red_carpet_elite"
		carpet.display_name = "RED CARPET ELITE"
		carpet.bonus_text = "Celebrity status. +20% follower gain. People ask for selfies."
		carpet.garment_color = Color(0.75, 0.12, 0.2)
		place(carpet, Vector2(3480, 370))
	if not GameState.costumes_owned.has("the_former_winner"):
		var winner: Area2D = COSTUME.new()
		winner.costume_id = &"the_former_winner"
		winner.display_name = "THE FORMER WINNER"
		winner.bonus_text = "Success wasn't worth it. +3 damage. People think you're somebody else."
		winner.garment_color = Color(0.55, 0.5, 0.42)
		place(winner, Vector2(800, 150))

	# the 13th George: the valet
	var george := GeorgeNPC.new()
	george.encounter_flag = &"george_celebrity"
	george.first_dialogue = [
		{"speaker": "DA'HERM", "text": "Nice car."},
		{"speaker": "GEORGE", "text": "It's not mine. None of them are."},
		{"speaker": "DA'HERM", "text": "Whose are they?"},
		{"speaker": "GEORGE", "text": "They're still deciding. That's most of the job, here."},
	]
	george.lines = ["Keys go on the hook.", "Hm."]
	place(george, Vector2(1250, 615))

	# canon NPCs (NPC_BIBLE)
	var frank := NPCBase.new()
	frank.npc_name = "FORMER STAR FRANK"
	frank.body_color = Color(0.6, 0.5, 0.4)
	frank.lines = ["You know who I am, right?", "I had a CATCHPHRASE. People put it on SHIRTS.",
		"...You really don't know who I am."]
	place(frank, Vector2(1750, 615))

	var melissa := NPCBase.new()
	melissa.npc_name = "AGENT MELISSA"
	melissa.body_color = Color(0.25, 0.25, 0.32)
	melissa.lines = ["Let's make a deal.", "Everyone has a price. Yours is adorable, by the way.",
		"Call me when the underdog thing stops paying. It will."]
	place(melissa, Vector2(3300, 615))

	var deborah := NPCBase.new()
	deborah.npc_name = "STAGE MOM DEBORAH"
	deborah.body_color = Color(0.7, 0.45, 0.55)
	deborah.lines = ["My baby is next.", "He's FORTY-SEVEN and he is RIGHT ON SCHEDULE.",
		"We've been 'about to break through' since the Clinton administration."]
	place(deborah, Vector2(700, 615))

	# patrols
	place(PAPARAZZO.instantiate(), Vector2(1900, 400))
	place(PAPARAZZO.instantiate(), Vector2(3250, 380))
	place(BODYGUARD.instantiate(), Vector2(1480, 560))
	place(BODYGUARD.instantiate(), Vector2(3050, 560))

	for pos: Vector2 in [Vector2(940, 380), Vector2(800, 150), Vector2(3480, 370),
			Vector2(2000, 560), Vector2(3700, 560)]:
		place(ORB.new(), pos)

	# save: THE TROPHY ROOM
	var save := SavePoint.new()
	save.club_name = "THE TROPHY ROOM"
	save.spawn_id = &"save"
	place(save, Vector2(1100, 595))
	spawn_points[&"save"] = Vector2(1050, 560)
	place(CircuitPhone.new(), Vector2(950, 615))

	# THE PAPARAZZI SWARM ambushes on the red carpet
	if GameState.has_flag(&"boss_swarm_defeated"):
		_spawn_reward()
		return
	_swarm = SWARM.instantiate()
	_swarm.arena_left = 1950.0
	_swarm.arena_right = 3150.0
	_swarm.floor_y = 660.0
	place(_swarm, Vector2(2850, 420))
	_swarm.boss_defeated.connect(_on_swarm_defeated)


func _physics_process(delta: float) -> void:
	super(delta)
	if _fight_started or _swarm == null:
		return
	if player.global_position.x > 2150.0 and player.global_position.x < 3000.0:
		_start_fight()


func _start_fight() -> void:
	_fight_started = true
	Juice.shake(5.0)
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("THE PAPARAZZI SWARM\n(you're not even famous. they don't care.)")
		hud.show_boss("THE PAPARAZZI SWARM", _swarm.health)


func _on_swarm_defeated() -> void:
	GameState.set_flag(&"boss_swarm_defeated")
	SaveSystem.autosave()
	_spawn_reward()


func _spawn_reward() -> void:
	# relics persist in GameState - that IS the taken-flag. (The
	# tree_exited pattern was a bug in M9 and would be one here too.)
	if GameState.has_relic(&"stealth_upgrade"):
		return
	var stealth: Area2D = RELIC.new()
	stealth.relic_id = &"stealth_upgrade"
	stealth.display_name = "STEALTH UPGRADE"
	stealth.desc_text = "You've learned how not to be seen. All enemies notice you later."
	stealth.relic_color = Color(0.3, 0.3, 0.4)
	place(stealth, Vector2(2550, 600))
