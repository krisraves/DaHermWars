# lost_theater.gd
# REGION 11: LOST THEATER DISTRICT (11_LEVEL_DESIGN_BIBLE / REG_011)
# "This place used to matter." Satire: abandoned art.
# Empty theaters, broken marquees, dust-covered stages.
#
# Up the stairs from the Comedy Underground. HEADLINER X haunts the
# dead stage -> PERFECT JOKE FRAGMENT (from under the stage, where he
# kept it for forty years). The HEADLINER X costume hangs in the
# rafters (double-jump). Visiting unbolts the BOARDED EXIT - a
# permanent shortcut back to the Homeless District. George has the
# front row. He always did.

extends RoomBase

const USHER := preload("res://scenes/enemies/usher_ghost.tscn")
const HEADLINER := preload("res://scenes/enemies/headliner_x.tscn")
const COSTUME := preload("res://scripts/items/costume_pickup.gd")
const FRAGMENT := preload("res://scripts/items/fragment_pickup.gd")
const ORB := preload("res://scripts/items/follower_orb.gd")

const DUST := Color(0.32, 0.3, 0.28)
const CURTAIN := Color(0.4, 0.2, 0.22)
const MARQUEE := Color(0.5, 0.45, 0.35)

var _boss: HeadlinerX = null
var _fight_started: bool = false


func _build() -> void:
	# arriving at all unbolts the District shortcut (the flag the
	# boarded door on the other side checks)
	GameState.set_flag(&"theater_unlocked")

	spawn_points = {
		&"default": Vector2(150, 560),      # stairs from the Underground
		&"from_district": Vector2(2780, 560),
	}
	camera_rect = Rect2(-280, -900, 3560, 2200)
	kill_y = 1200.0

	solid(-280, -700, 80, 1560, DUST.darkened(0.3))
	solid(3000, -700, 80, 1560, DUST.darkened(0.3))
	solid(-200, 660, 3200, 200, DUST)

	# ---- the street of dead marquees -------------------------------------
	for x in [450.0, 1000.0]:
		decor(x, 320, 300, 340, DUST.lightened(0.06))
		decor(x + 20.0, 350, 260, 40, MARQUEE)
	sign_label(Vector2(480, 380), "THE MAJESTIC — \"ONE NIGHT ON Y\" (the L fell)", 12)
	sign_label(Vector2(1030, 380), "PALACE THEATER — FINAL SHOW: TBD", 12)

	# ---- the theater interior (east half) ----------------------------------
	decor(1850, 240, 1000, 420, CURTAIN.darkened(0.3))   # the dark house
	decor(2000, 420, 700, 240, CURTAIN)                  # the stage backdrop
	decor(1900, 600, 80, 60, DUST.lightened(0.1))        # front row seats
	decor(1790, 600, 80, 60, DUST.lightened(0.1))
	sign_label(Vector2(2200, 390), "(The dust on the stage is undisturbed. Mostly.)", 12)

	# rafters (double-jump route, 230px rises)
	solid(2350, 430, 120, 20, DUST.lightened(0.12))
	solid(2150, 200, 140, 20, DUST.lightened(0.12))
	sign_label(Vector2(2170, 150), "(something hangs in the rafters)", 12)

	sign_label(Vector2(300, 600), "LOST THEATER DISTRICT\nThis place used to matter.", 13)
	sign_label(Vector2(2860, 540), "BOARDED EXIT — HOMELESS DISTRICT", 12)


func _populate() -> void:
	# west: back down the stairs
	var west := Door.new()
	west.door_label = "← COMEDY UNDERGROUND"
	west.target_scene = "res://scenes/levels/comedy_underground.tscn"
	west.target_spawn = &"from_theater"
	place(west, Vector2(60, 605))

	# east: the boarded shortcut (always usable from this side)
	var boarded := Door.new()
	boarded.door_label = "BOARDED EXIT"
	boarded.target_scene = "res://scenes/levels/homeless_district.tscn"
	boarded.target_spawn = &"from_theater"
	place(boarded, Vector2(2900, 605))

	# George, front row
	var george := GeorgeNPC.new()
	george.encounter_flag = &"george_theater"
	george.first_dialogue = [
		{"speaker": "DA'HERM", "text": "You watch every night? There's no show."},
		{"speaker": "GEORGE", "text": "Front row's always open."},
		{"speaker": "DA'HERM", "text": "Because nobody comes."},
		{"speaker": "GEORGE", "text": "Somebody does."},
	]
	george.lines = ["Good seat.", "Hm."]
	place(george, Vector2(1830, 615))

	# the locals
	var usher_npc := NPCBase.new()
	usher_npc.npc_name = "OLD STAGEHAND"
	usher_npc.body_color = Color(0.45, 0.42, 0.4)
	usher_npc.lines = [
		"Same bald guy in the front row, forty years. Never laughs. Never leaves early.",
		"The Headliner's still up there. Some nights you hear the set. It's... fine?",
		"They say he kept something under the stage. Wouldn't sell it. Couldn't tell you what it was.",
	]
	place(usher_npc, Vector2(1300, 615))

	# enemies
	place(USHER.instantiate(), Vector2(800, 360))
	place(USHER.instantiate(), Vector2(1600, 320))
	place(USHER.instantiate(), Vector2(2500, 340))

	# rafter costume: HEADLINER X
	if not GameState.costumes_owned.has("headliner_x"):
		var costume: Area2D = COSTUME.new()
		costume.costume_id = &"headliner_x"
		costume.display_name = "HEADLINER X"
		costume.bonus_text = "Forgotten greatness: +15% damage to bosses. Older comics recognize the outfit."
		costume.garment_color = Color(0.7, 0.75, 0.9)
		place(costume, Vector2(2210, 150))

	# orbs
	for pos: Vector2 in [Vector2(2400, 390), Vector2(2200, 160), Vector2(700, 560),
			Vector2(1450, 560)]:
		place(ORB.new(), pos)

	# save: THE INTERMISSION
	var save := SavePoint.new()
	save.club_name = "THE INTERMISSION"
	save.spawn_id = &"save"
	place(save, Vector2(1450, 595))
	spawn_points[&"save"] = Vector2(1520, 560)
	place(CircuitPhone.new(), Vector2(1600, 615))

	# HEADLINER X
	if GameState.has_flag(&"boss_headliner_defeated"):
		if not GameState.has_flag(&"fragment_headliner_taken"):
			_spawn_reward()
		return
	_boss = HEADLINER.instantiate()
	_boss.arena_left = 1900.0
	_boss.arena_right = 2820.0
	place(_boss, Vector2(2350, 420))
	_boss.boss_defeated.connect(_on_boss_defeated)


func _physics_process(delta: float) -> void:
	super(delta)
	if _fight_started or _boss == null:
		return
	if player.global_position.x > 1950.0:
		_start_fight()


func _start_fight() -> void:
	_fight_started = true
	Juice.shake(5.0)
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("HEADLINER X\n\"The ghost of a comic who almost made it.\"")
		hud.show_boss("HEADLINER X", _boss.health)


func _on_boss_defeated() -> void:
	GameState.set_flag(&"boss_headliner_defeated")
	SaveSystem.autosave()
	_spawn_reward()


func _spawn_reward() -> void:
	# "under the stage" - the fragment he never understood
	var fragment := FragmentPickup.new()
	fragment.taken_flag = &"fragment_headliner_taken"
	place(fragment, Vector2(2350, 600))
