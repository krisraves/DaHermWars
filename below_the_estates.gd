# podcast_wasteland.gd
# REGION 04: PODCAST WASTELAND (11_LEVEL_DESIGN_BIBLE)
# "Can we clip that?" Satire target: podcast culture.
# Palette: LED blue, white, black - artificial humanity.
#
# Entered from Courtside (east). The MAIN STUDIO (west) holds the
# POD FATHER (3 phases + AD BREAKS) -> POD MIC. A one-way drop from
# the Open Mic Alley STUDIO TUNNEL lands on a high ledge; climbing
# back up needs DOUBLE JUMP - the region closes the world's first
# loop, and teaches it with a 230px ledge spacing (single jump max
# ~132px, double ~257px).

extends RoomBase

const PODCAST_BRO := preload("res://scenes/enemies/podcast_bro.tscn")
const COMMENT_TROLL := preload("res://scenes/enemies/comment_troll.tscn")
const POD_FATHER := preload("res://scenes/enemies/pod_father.tscn")
const COSTUME := preload("res://scripts/items/costume_pickup.gd")
const WEAPON := preload("res://scripts/items/weapon_pickup.gd")
const ORB := preload("res://scripts/items/follower_orb.gd")

const STUDIO := Color(0.12, 0.13, 0.18)
const LED := Color(0.35, 0.85, 1.0)
const FOAM := Color(0.18, 0.18, 0.22)

var _boss: PodFather = null
var _fight_started: bool = false


func _build() -> void:
	spawn_points = {
		&"default": Vector2(3850, 560),     # from Courtside (east)
		&"from_alley": Vector2(3380, 150),  # STUDIO TUNNEL ledge (one-way drop)
	}
	camera_rect = Rect2(-280, -900, 4360, 2200)
	kill_y = 1200.0

	solid(-280, -700, 80, 1560, STUDIO)
	solid(4000, -700, 80, 1560, STUDIO)
	solid(-200, 660, 4200, 200, FOAM)

	# ---- the DJ return ledges to the STUDIO TUNNEL ---------------------
	solid(3300, 200, 180, 20, STUDIO)   # tunnel ledge (spawn here from alley)
	solid(3460, 430, 140, 20, STUDIO)   # mid ledge: 230px below tunnel
	# ground -> 430 -> 200: each step 230px = double-jump only
	sign_label(Vector2(3470, 380), "(those ledges are mocking you)", 12)

	# ---- recording booths + ring lights ----------------------------------
	for x in [600.0, 1500.0, 2400.0]:
		decor(x, 380, 280, 280, STUDIO)
		decor(x + 20.0, 400, 80, 26, LED)
	sign_label(Vector2(640, 408), "ON AIR", 13)
	sign_label(Vector2(1540, 408), "ON AIR", 13)
	sign_label(Vector2(2440, 408), "ON AIR (10 YRS)", 13)

	# booth-roof hop line (costume route) + access steps (<=120px rises)
	solid(1320, 540, 110, 20, STUDIO)
	solid(1460, 440, 110, 20, STUDIO)
	solid(1500, 360, 280, 20, STUDIO)
	solid(1900, 250, 160, 20, STUDIO)
	solid(2150, 360, 140, 20, STUDIO)

	# ---- George's booth pocket: drop between booths ----------------------
	solid(2750, 220, 60, 440, STUDIO)
	solid(2900, 400, 60, 260, STUDIO)
	sign_label(Vector2(2770, 170), "(the only quiet booth)", 12)

	# ---- MAIN STUDIO (boss zone, west: x < 900) ----------------------------
	decor(880, 180, 26, 480, LED)
	solid(380, 520, 300, 24, STUDIO)  # the Pod Father's stage
	sign_label(Vector2(940, 520), "MAIN STUDIO\nEpisode 4,061 and counting.", 13)

	sign_label(Vector2(3700, 520), "PODCAST WASTELAND\nEverything is recorded.\nNothing is forgotten.")
	sign_label(Vector2(1200, 600), "\"CAN WE CLIP THAT?\"", 13)


func _populate() -> void:
	# east door back to Courtside
	var east := Door.new()
	east.door_label = "COURTSIDE KINGDOM →"
	east.target_scene = "res://scenes/levels/courtside_kingdom.tscn"
	east.target_spawn = &"from_wasteland"
	place(east, Vector2(3880, 605))

	# STUDIO TUNNEL door on the high ledge -> Open Mic Alley
	var tunnel := Door.new()
	tunnel.door_label = "STUDIO TUNNEL"
	tunnel.target_scene = "res://scenes/levels/open_mic_alley.tscn"
	tunnel.target_spawn = &"from_tunnel"
	place(tunnel, Vector2(3360, 145))

	# enemies: the content ecosystem
	place(PODCAST_BRO.instantiate(), Vector2(1100, 560))
	place(PODCAST_BRO.instantiate(), Vector2(2100, 560))
	place(PODCAST_BRO.instantiate(), Vector2(3100, 560))
	place(COMMENT_TROLL.instantiate(), Vector2(1700, 560))
	place(COMMENT_TROLL.instantiate(), Vector2(2600, 560))

	# THOUGHT LEADER costume on the booth-roof line
	if not GameState.costumes_owned.has("thought_leader"):
		var costume: Area2D = COSTUME.new()
		costume.costume_id = &"thought_leader"
		costume.display_name = "THOUGHT LEADER"
		costume.bonus_text = "Talk forever. Say nothing. NPCs pay +2 Followers per chat."
		costume.garment_color = Color(0.35, 0.35, 0.4)
		place(costume, Vector2(1970, 210))

	# CONTENT MACHINE costume: on top of the pocket wall (DJ-gated:
	# right wall top y400 -> left wall top y220 is a 180px rise)
	if not GameState.costumes_owned.has("content_machine"):
		var machine: Area2D = COSTUME.new()
		machine.costume_id = &"content_machine"
		machine.display_name = "CONTENT MACHINE"
		machine.bonus_text = "Busking yields DOUBLE. Quantity over quality. (Comics notice.)"
		machine.garment_color = Color(0.85, 0.2, 0.6)
		place(machine, Vector2(2780, 170))

	# George, boom op, the only quiet booth
	var george := GeorgeNPC.new()
	george.encounter_flag = &"george_wasteland"
	george.first_dialogue = [
		{"speaker": "DA'HERM", "text": "You work every booth in this place?"},
		{"speaker": "GEORGE", "text": "Just the quiet ones."},
		{"speaker": "DA'HERM", "text": "None of these booths are quiet."},
		{"speaker": "GEORGE", "text": "Hm."},
	]
	george.lines = ["Long episode.", "Hm."]
	place(george, Vector2(2855, 600))

	# the locals
	var mike := NPCBase.new()
	mike.npc_name = "PODCAST MIKE"
	mike.body_color = Color(0.3, 0.32, 0.4)
	mike.lines = ["Hold on, let me record this.", "You'd be GREAT on the pod.", "Episode 300 is where it gets good. Trust the catalog."]
	place(mike, Vector2(2550, 615))

	var carl := NPCBase.new()
	carl.npc_name = "CLIP FARMER CARL"
	carl.body_color = Color(0.45, 0.5, 0.3)
	carl.lines = ["Can we clip that?", "Full episodes are dead. Long live the clip.", "That thing you just did? That's a clip."]
	place(carl, Vector2(1350, 615))

	# orbs
	for pos: Vector2 in [Vector2(1560, 320), Vector2(1950, 210), Vector2(2200, 320),
			Vector2(2800, 380), Vector2(3490, 390), Vector2(3360, 160)]:
		place(ORB.new(), pos)

	# save club + circuit
	var save := SavePoint.new()
	save.club_name = "THE LAUGH TRACK"
	save.spawn_id = &"save"
	place(save, Vector2(3000, 595))
	spawn_points[&"save"] = Vector2(2950, 560)
	place(CircuitPhone.new(), Vector2(3130, 615))

	# the Pod Father
	if GameState.has_flag(&"boss_podfather_defeated"):
		if not GameState.weapons_owned.has("pod_mic"):
			_spawn_reward()
		return
	_boss = POD_FATHER.instantiate()
	place(_boss, Vector2(520, 430))
	_boss.boss_defeated.connect(_on_boss_defeated)


func _physics_process(delta: float) -> void:
	super(delta)
	if _fight_started or _boss == null:
		return
	if player.global_position.x < 860.0:
		_start_fight()


func _start_fight() -> void:
	_fight_started = true
	Juice.shake(5.0)
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("POD FATHER\n\"Runs 34 podcasts. Simultaneously.\"")
		hud.show_boss("POD FATHER", _boss.health)


func _on_boss_defeated() -> void:
	GameState.set_flag(&"boss_podfather_defeated")
	SaveSystem.autosave()
	_spawn_reward()


func _spawn_reward() -> void:
	var mic := WEAPON.new()
	mic.weapon_id = &"pod_mic"
	mic.auto_equip = false
	place(mic, Vector2(520, 470))
