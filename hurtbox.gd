# below_the_estates.gd
# THE DARK CHAPTER: BELOW THE ESTATES
# (03_STORY_BIBLE "The Cost of Applause" · RULE 19 · PHASE 8)
#
# The only section of the game that fully suspends the comedic tone.
# No jokes. No gag enemies. No comic relief. No follower rewards.
# The discovery is told through EVIDENCE - ledgers, bunks, contracts,
# confiscated phones - never through depiction (RULE 3).
#
# Structure: a one-way drop. Upper corridor east -> shaft down ->
# lower corridor west -> THE RECORDS ROOM (the turning point:
# "I want a special" becomes "This has to stop") -> back east ->
# the service elevator opens -> George is waiting. He doesn't explain.
#
# Audio note: per 10_AUDIO_BIBLE the music nearly disappears here.
# Silence is the intended score.

extends RoomBase

const GUARD := preload("res://scenes/enemies/inner_circle_guard.tscn")
const EVIDENCE := preload("res://scripts/interactables/evidence.gd")

const CONCRETE := Color(0.2, 0.2, 0.21)
const STEEL := Color(0.16, 0.16, 0.18)
const DIM := Color(0.3, 0.29, 0.31)

var _scene_played: bool = false
var _george_spawned: bool = false


func _build() -> void:
	spawn_points = {
		&"default": Vector2(150, 560),  # the service stair lets out here
	}
	camera_rect = Rect2(-280, -200, 2960, 2500)
	kill_y = 2300.0

	solid(-280, -100, 80, 1900, STEEL)
	solid(2400, -100, 80, 1900, STEEL)

	# ---- UPPER corridor (floor ends at x2150; the shaft is the way on) --
	solid(-200, 660, 2350, 80, CONCRETE)
	decor(-200, -100, 2680, 60, STEEL)  # ceiling

	# upper dressing: the dormitory
	for i in 6:
		decor(1560.0 + i * 90.0, 590, 70, 18, DIM)      # bunks
		decor(1560.0 + i * 90.0, 540, 70, 10, DIM.darkened(0.2))
	sign_label(Vector2(1620, 500), "(Twelve beds. No windows.)", 12)
	sign_label(Vector2(1840, 460), "(A chore chart. Like it was normal.)", 12)

	sign_label(Vector2(300, 600), "(The stairs only go down from here.)", 12)
	sign_label(Vector2(2200, 560), "(The shaft drops further than it should.)", 12)

	# ---- LOWER corridor --------------------------------------------------
	solid(-200, 1500, 2600, 200, CONCRETE)
	# a mid-shaft ledge so the 840px drop reads as two falls, not a void
	solid(2150, 1080, 120, 20, DIM)

	# lower dressing
	decor(640, 1280, 240, 220, STEEL.lightened(0.04))   # the contracts wall
	sign_label(Vector2(1140, 1440), "(It's colder down here. It's cleaner, too.)", 12)

	# ---- THE RECORDS ROOM (west end, lower) -------------------------------
	decor(40, 1200, 200, 300, STEEL.lightened(0.06))
	for i in 4:
		decor(60.0 + i * 44.0, 1240, 30, 240, DIM)       # filing cabinets
	sign_label(Vector2(70, 1160), "RECORDS", 12)

	# ---- the service elevator (east end, lower) ----------------------------
	decor(2230, 1300, 130, 200, STEEL.lightened(0.05))


func _populate() -> void:
	# guards. they drop nothing. avoid them.
	place(GUARD.instantiate(), Vector2(1150, 560))
	place(GUARD.instantiate(), Vector2(1300, 1400))
	place(GUARD.instantiate(), Vector2(500, 1400))

	# ---- evidence (upper) -------------------------------------------------
	var ledger: Area2D = EVIDENCE.new()
	ledger.evidence_name = "INTAKE LEDGER"
	ledger.lines = [
		{"speaker": "", "text": "(A ledger, left open. Names. Ages. A column labeled 'placement fee.')"},
		{"speaker": "DA'HERM", "text": "The handwriting is neat."},
	]
	place(ledger, Vector2(900, 615))

	var chart: Area2D = EVIDENCE.new()
	chart.evidence_name = "CHORE CHART"
	chart.lines = [
		{"speaker": "", "text": "(Laundry. Kitchen. 'Guest prep.' The names are first names only. Some are crossed out.)"},
		{"speaker": "DA'HERM", "text": "..."},
	]
	place(chart, Vector2(1980, 615))

	# ---- evidence (lower) ----------------------------------------------------
	var phones: Area2D = EVIDENCE.new()
	phones.evidence_name = "CONFISCATED PHONES"
	phones.object_size = Vector2(56, 26)
	phones.lines = [
		{"speaker": "", "text": "(A bin of phones. Hundreds. Dead screens, old models, glitter cases, cracked glass.)"},
		{"speaker": "DA'HERM", "text": "Every one of these used to be somebody's whole life."},
	]
	place(phones, Vector2(1700, 1455))

	var contracts: Area2D = EVIDENCE.new()
	contracts.evidence_name = "CONTRACTS WALL"
	contracts.object_size = Vector2(44, 40)
	contracts.lines = [
		{"speaker": "", "text": "(Framed contracts, floor to ceiling. Image rights. Perpetual. And there - Clause 13.)"},
		{"speaker": "DA'HERM", "text": "It's not redacted down here."},
		{"speaker": "", "text": "(You read it once. That's enough.)"},
	]
	place(contracts, Vector2(740, 1455))

	# the elevator is always there; its required_flag keeps it shut
	# until the records room. George appears only after.
	_place_exit_door()
	if GameState.has_flag(&"dark_chapter_done"):
		_scene_played = true
		_spawn_george_and_exit()


func _place_exit_door() -> void:
	var lift := Door.new()
	lift.door_label = "SERVICE ELEVATOR"
	lift.target_scene = "res://scenes/levels/special_estates.tscn"
	lift.target_spawn = &"from_below"
	lift.required_flag = &"dark_chapter_done"
	lift.flag_gate_line = "(The elevator hums behind the gate. It doesn't open. Whatever runs this place isn't done with you - or you with it.)"
	place(lift, Vector2(2290, 1445))


func _spawn_george_and_exit() -> void:
	if _george_spawned:
		return
	_george_spawned = true
	var george := GeorgeNPC.new()
	george.encounter_flag = &"george_below"
	george.first_dialogue = [
		{"speaker": "DA'HERM", "text": "Did you know about this?"},
		{"speaker": "GEORGE", "text": "Now you do."},
		{"speaker": "DA'HERM", "text": "That's not an answer."},
		{"speaker": "GEORGE", "text": "No."},
	]
	george.lines = ["...", "Go on up."]
	place(george, Vector2(2090, 1455))


func _physics_process(delta: float) -> void:
	super(delta)
	if _scene_played:
		return
	# THE RECORDS ROOM - the turning point
	if player.global_position.x < 260.0 and player.global_position.y > 1200.0:
		_scene_played = true
		_play_records_scene()


func _play_records_scene() -> void:
	DialogueSystem.start([
		{"speaker": "", "text": "(A filing room. Climate controlled. Better maintained than anywhere upstairs.)"},
		{"speaker": "", "text": "(Intake ledgers. Transfer records. 'Placement.' 'Acquisition.' 'Renewal.' People, filed like receipts.)"},
		{"speaker": "DA'HERM", "text": "..."},
		{"speaker": "DA'HERM", "text": "I came here for a special. A check. A door with my name on it."},
		{"speaker": "DA'HERM", "text": "They built all of it on this."},
		{"speaker": "DA'HERM", "text": "This has to stop."},
	])
	DialogueSystem.finished.connect(_after_records_scene, CONNECT_ONE_SHOT)


func _after_records_scene() -> void:
	GameState.set_flag(&"dark_chapter_done")
	SaveSystem.autosave()
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("THE COST OF APPLAUSE")
	_spawn_george_and_exit()
