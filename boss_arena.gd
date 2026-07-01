# laughing_pyramid.gd
# BOSS 21 / ENDGAME REGION: THE LAUGHING PYRAMID
# "Living headquarters. Multi-stage dungeon boss."
#
# Implemented as a building that fights back: each floor of the
# vertical climb (the Corporate Tower's verified step math) is a
# gauntlet of BEAM HAZARDS - the pyramid itself targeting you -
# plus cult patrols. FLOOR 3 holds the SCREENING ROOM (THE SPECIAL,
# optional, final fragment). The COUNCIL FLOOR holds the INNER
# CIRCLE (three at once) -> CULT KEY -> the SUMMIT door.
# George is the janitor. He was the janitor in the Alley, too.

extends RoomBase

const INITIATE := preload("res://scenes/enemies/illuminepstein_initiate.tscn")
const ACOLYTE := preload("res://scenes/enemies/executive_acolyte.tscn")
const GUARD := preload("res://scenes/enemies/inner_circle_guard.tscn")
const COUNCIL := preload("res://scripts/bosses/inner_circle.gd")
const TRUE_GATE := preload("res://scripts/interactables/true_gate.gd")
const ORB := preload("res://scripts/items/follower_orb.gd")

const GOLD := Color(0.82, 0.68, 0.3)
const OBSIDIAN := Color(0.12, 0.1, 0.16)
const SLAB := Color(0.32, 0.26, 0.4)

var _council: InnerCircle = null
var _fight_started: bool = false


func _build() -> void:
	spawn_points = {
		&"default": Vector2(420, 560),          # the atrium, from the Cove
		&"from_screening": Vector2(1560, 18),   # back out of the Screening Room
		&"from_summit": Vector2(300, -282),     # back down from the summit
	}
	camera_rect = Rect2(-280, -1100, 2680, 2160)
	kill_y = 1200.0

	solid(-280, -1100, 80, 1960, OBSIDIAN)
	solid(2200, -1100, 80, 1960, OBSIDIAN)
	solid(-200, 660, 2400, 200, SLAB)               # ATRIUM

	# floors (the Tower's verified pattern: gaps alternate ends)
	solid(-200, 360, 2000, 30, SLAB)    # FLOOR 2 (gap: east)
	solid(0, 60, 2200, 30, SLAB)        # FLOOR 3 (gap: west)
	solid(-200, -240, 1900, 30, SLAB)   # COUNCIL FLOOR (gap: east)

	# climb steps - every rise <=120px (verified in M7)
	solid(1900, 540, 120, 20, GOLD)     # atrium -> F2 (east)
	solid(1980, 440, 120, 20, GOLD)
	solid(-80, 250, 110, 20, GOLD)      # F2 -> F3 (west)
	solid(-140, 140, 100, 20, GOLD)
	solid(1980, -40, 110, 20, GOLD)     # F3 -> COUNCIL (east)
	solid(1840, -140, 110, 20, GOLD)

	# atrium dressing
	decor(900, 380, 360, 280, OBSIDIAN.lightened(0.06))
	decor(1020, 420, 120, 120, GOLD.darkened(0.2))   # the mic-pyramid sigil
	sign_label(Vector2(940, 350), "THE LAUGHING PYRAMID\nATTENTION IS THE HIGHEST FORM OF POWER", 13)
	sign_label(Vector2(350, 600), "(The building is humming. It knows you're inside it.)", 12)

	# floor signage
	sign_label(Vector2(700, 320), "FLOOR 2 — ACQUISITIONS", 12)
	sign_label(Vector2(700, 20), "FLOOR 3 — PROGRAMMING · SCREENING ROOM", 12)
	sign_label(Vector2(700, -280), "COUNCIL FLOOR — THE INNER CIRCLE", 12)
	sign_label(Vector2(120, -290), "SUMMIT ↑", 12)


func _populate() -> void:
	# back to the Cove
	var cove := Door.new()
	cove.door_label = "← CONTENT COVE"
	cove.target_scene = "res://scenes/levels/content_cove.tscn"
	cove.target_spawn = &"from_pyramid"
	place(cove, Vector2(80, 605))

	# the Screening Room, Floor 3
	var screening := Door.new()
	screening.door_label = "SCREENING ROOM"
	screening.target_scene = "res://scenes/levels/screening_room.tscn"
	screening.target_spawn = &"default"
	place(screening, Vector2(1500, 5))

	# the Summit, Council floor west (the Cult Key gate)
	var summit := Door.new()
	summit.door_label = "THE SUMMIT"
	summit.target_scene = "res://scenes/levels/pyramid_summit.tscn"
	summit.target_spawn = &"default"
	summit.required_flag = &"cult_key"
	summit.flag_gate_line = "(A wall that is obviously a door. It will not admit you while the Council stands.)"
	place(summit, Vector2(180, -295))

	# the door that is very specifically not there (M11: THE HEADLINER)
	var gate: Interactable = TRUE_GATE.new()
	place(gate, Vector2(2050, 660))

	# the building fights back: beam hazards per floor
	for config: Array in [
			[Vector2(1300, 600), 660.0], [Vector2(2050, 600), 660.0],
			[Vector2(600, 300), 360.0], [Vector2(1500, 300), 360.0],
			[Vector2(500, 0), 60.0], [Vector2(1200, 0), 60.0]]:
		var hazard := BeamHazard.new()
		hazard.floor_y = config[1]
		hazard.interval = 2.4
		place(hazard, config[0])

	# patrols
	place(INITIATE.instantiate(), Vector2(1500, 560))
	place(ACOLYTE.instantiate(), Vector2(1000, 320))
	place(INITIATE.instantiate(), Vector2(1700, 320))
	place(GUARD.instantiate(), Vector2(900, 20))
	place(INITIATE.instantiate(), Vector2(1900, 20))

	# George, janitor (he was sweeping at the announcement, too)
	var george := GeorgeNPC.new()
	george.encounter_flag = &"george_pyramid"
	george.first_dialogue = [
		{"speaker": "DA'HERM", "text": "You. You were sweeping in the Alley. The night of the announcement."},
		{"speaker": "GEORGE", "text": "Floors everywhere."},
		{"speaker": "DA'HERM", "text": "...Who ARE you?"},
		{"speaker": "GEORGE", "text": "George."},
	]
	george.lines = ["Big floor, this one.", "Hm."]
	place(george, Vector2(1750, 615))

	# orbs up the climb
	for pos: Vector2 in [Vector2(1950, 500), Vector2(2030, 400), Vector2(-30, 210),
			Vector2(2030, -80), Vector2(400, -280), Vector2(1100, -280)]:
		place(ORB.new(), pos)

	# save: THE GIFT SHOP (even cult headquarters has one)
	var save := SavePoint.new()
	save.club_name = "THE GIFT SHOP"
	save.spawn_id = &"save"
	place(save, Vector2(1200, 295))
	spawn_points[&"save"] = Vector2(1150, 318)
	place(CircuitPhone.new(), Vector2(1330, 315))

	# THE INNER CIRCLE (Council floor)
	if GameState.has_flag(&"cult_key"):
		return
	_council = COUNCIL.new()
	place(_council, Vector2(800, -300))
	_council.boss_defeated.connect(_on_council_defeated)


func _physics_process(delta: float) -> void:
	super(delta)
	if _fight_started or _council == null:
		return
	if player.global_position.y < -180.0 and player.global_position.x < 1500.0:
		_start_fight()


func _start_fight() -> void:
	_fight_started = true
	Juice.shake(6.0)
	_council.summon_council()
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("THE INNER CIRCLE\n\"Council of elite cultists.\" All three. At once.")
		hud.show_boss("THE INNER CIRCLE", _council.health)


func _on_council_defeated() -> void:
	SaveSystem.autosave()
