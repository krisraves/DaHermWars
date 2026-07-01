# corporate_tower.gd
# REGION 06: CORPORATE MEDIA TOWER (11_LEVEL_DESIGN_BIBLE)
# "Let's schedule something." Satire: corporate entertainment.
# Palette: steel blue, glass cyan, white. Controlled success.
#
# The game's first VERTICAL region: five floors, each climb a stepped
# route at alternating ends (all rises <=120px, single-jump verified).
# LOBBY: Brittney Nuttings - the first Illuminepstein whisper.
# FLOOR 2: HR + the MANDATORY FUN ROOM (save). FLOOR 3: management +
# the CORPORATE CLEAN costume (DJ ledge). EXEC FLOOR: BRANDON
# SPONSORSON -> SPONSOR SIGIL. ROOF: the door to Streaming HQ.

extends RoomBase

const HR := preload("res://scenes/enemies/hr_enforcer.tscn")
const MANAGER := preload("res://scenes/enemies/middle_manager.tscn")
const BRANDON := preload("res://scenes/enemies/brandon_sponsorson.tscn")
const COSTUME := preload("res://scripts/items/costume_pickup.gd")
const RELIC := preload("res://scripts/items/relic_pickup.gd")
const ORB := preload("res://scripts/items/follower_orb.gd")
const BRITTNEY := preload("res://scripts/npcs/brittney_npc.gd")

const STEEL := Color(0.3, 0.38, 0.48)
const GLASS := Color(0.55, 0.75, 0.85)
const SLAB := Color(0.42, 0.48, 0.56)

var _brandon: BrandonSponsorson = null
var _fight_started: bool = false


func _build() -> void:
	spawn_points = {
		&"default": Vector2(420, 560),     # lobby, from Open Mic Alley
		&"roof": Vector2(1100, -582),      # from Streaming HQ
	}
	camera_rect = Rect2(-280, -1100, 2680, 2160)
	kill_y = 1200.0

	solid(-280, -1100, 80, 1960, STEEL)
	solid(2200, -1100, 80, 1960, STEEL)
	solid(-200, 660, 2400, 200, SLAB)               # lobby floor

	# ---- floor slabs (gaps alternate ends; that's the climb) -----------
	solid(-200, 360, 2000, 30, SLAB)    # FLOOR 2 (gap: east)
	solid(0, 60, 2200, 30, SLAB)        # FLOOR 3 (gap: west)
	solid(-200, -240, 1900, 30, SLAB)   # EXEC (gap: east)
	solid(0, -540, 2200, 30, SLAB)      # ROOF (gap: west)

	# climb steps - every rise <=120px
	solid(1900, 540, 120, 20, GLASS)    # lobby -> F2 (east)
	solid(1980, 440, 120, 20, GLASS)
	solid(-80, 250, 110, 20, GLASS)     # F2 -> F3 (west)
	solid(-140, 140, 100, 20, GLASS)
	solid(1980, -40, 110, 20, GLASS)    # F3 -> EXEC (east)
	solid(1840, -140, 110, 20, GLASS)
	solid(-80, -340, 110, 20, GLASS)    # EXEC -> ROOF (west)
	solid(-150, -440, 110, 20, GLASS)

	# ---- lobby dressing -------------------------------------------------
	solid(300, 540, 40, 120, STEEL)     # mailroom partition (hop it)
	sign_label(Vector2(140, 500), "MAILROOM", 12)
	decor(900, 420, 300, 240, GLASS.darkened(0.2))  # reception glass
	sign_label(Vector2(920, 440), "CORPORATE MEDIA TOWER\nYour visit is being optimized.", 13)
	sign_label(Vector2(1500, 600), "\"WHO PRODUCES THE PRODUCERS?\"\n(maintenance has been notified)", 12)

	# floor signage
	sign_label(Vector2(700, 320), "FLOOR 2 — HUMAN RESOURCES\n(resources, mostly)", 12)
	sign_label(Vector2(700, 20), "FLOOR 3 — MIDDLE MANAGEMENT", 12)
	sign_label(Vector2(700, -280), "EXECUTIVE FLOOR — BY INVITATION", 12)
	sign_label(Vector2(600, -580), "ROOF ACCESS\n\"THE PYRAMID HAS A GUEST LIST\" (scratched in)", 12)

	# DJ ledge above Floor 3 (the costume)
	solid(220, -100, 140, 20, GLASS)


func _populate() -> void:
	# lobby door back to the Alley
	var alley := Door.new()
	alley.door_label = "← OPEN MIC ALLEY"
	alley.target_scene = "res://scenes/levels/open_mic_alley.tscn"
	alley.target_spawn = &"from_tower"
	place(alley, Vector2(80, 605))

	# roof door to Streaming HQ
	var roof := Door.new()
	roof.door_label = "STREAMING HQ →"
	roof.target_scene = "res://scenes/levels/streaming_hq.tscn"
	roof.target_spawn = &"default"
	place(roof, Vector2(1100, -595))

	# BRITTNEY NUTTINGS, lobby (the whisper)
	place(BRITTNEY.new(), Vector2(760, 615))

	# George, mailroom
	var george := GeorgeNPC.new()
	george.encounter_flag = &"george_tower"
	george.first_dialogue = [
		{"speaker": "DA'HERM", "text": "They've got you sorting mail?"},
		{"speaker": "GEORGE", "text": "Somebody writes letters. Still."},
		{"speaker": "DA'HERM", "text": "To a media company?"},
		{"speaker": "GEORGE", "text": "Mostly complaints. Some of them are very funny."},
	]
	george.lines = ["Lot of mail today.", "Hm."]
	place(george, Vector2(160, 615))

	# Manager Steve, Floor 3
	var steve := NPCBase.new()
	steve.npc_name = "MANAGER STEVE"
	steve.body_color = Color(0.45, 0.5, 0.6)
	steve.lines = ["Let's schedule something.", "I have a meeting about this conversation at 3.", "Circle back? Loop in? Touch base? Pick one, I'll book a room."]
	place(steve, Vector2(1200, 15))

	# enemies by floor
	place(MANAGER.instantiate(), Vector2(1400, 560))      # lobby security
	place(HR.instantiate(), Vector2(700, 320))            # floor 2
	place(HR.instantiate(), Vector2(1400, 320))
	place(MANAGER.instantiate(), Vector2(900, 20))        # floor 3
	place(HR.instantiate(), Vector2(1600, 20))

	# CORPORATE CLEAN (DJ ledge above Floor 3)
	if not GameState.costumes_owned.has("corporate_clean"):
		var costume: Area2D = COSTUME.new()
		costume.costume_id = &"corporate_clean"
		costume.display_name = "CORPORATE CLEAN"
		costume.bonus_text = "You look like you belong. Corporate security barely notices you."
		costume.garment_color = Color(0.16, 0.22, 0.34)
		place(costume, Vector2(280, -150))

	# orbs up the climb
	for pos: Vector2 in [Vector2(1950, 500), Vector2(2030, 400), Vector2(-30, 210),
			Vector2(2030, -80), Vector2(-100, -380), Vector2(1100, -600)]:
		place(ORB.new(), pos)

	# save: the MANDATORY FUN ROOM, Floor 2
	var save := SavePoint.new()
	save.club_name = "MANDATORY FUN ROOM"
	save.spawn_id = &"save"
	place(save, Vector2(1000, 295))
	spawn_points[&"save"] = Vector2(950, 318)
	place(CircuitPhone.new(), Vector2(1150, 315))

	# Brandon, exec floor
	if GameState.has_flag(&"boss_brandon_defeated"):
		if not GameState.has_relic(&"sponsor_sigil"):
			_spawn_reward()
		return
	_brandon = BRANDON.instantiate()
	_brandon.arena_left = 60.0
	_brandon.arena_right = 1600.0
	_brandon.floor_y = -240.0
	place(_brandon, Vector2(500, -310))
	_brandon.boss_defeated.connect(_on_brandon_defeated)


func _physics_process(delta: float) -> void:
	super(delta)
	if _fight_started or _brandon == null:
		return
	if player.global_position.y < -180.0 and player.global_position.x < 1500.0:
		_start_fight()


func _start_fight() -> void:
	_fight_started = true
	Juice.shake(5.0)
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("BRANDON SPONSORSON\n\"Living sponsorship executive.\"")
		hud.show_boss("BRANDON SPONSORSON", _brandon.health)


func _on_brandon_defeated() -> void:
	GameState.set_flag(&"boss_brandon_defeated")
	SaveSystem.autosave()
	_spawn_reward()


func _spawn_reward() -> void:
	var relic: Area2D = RELIC.new()
	relic.relic_id = &"sponsor_sigil"
	relic.display_name = "SPONSOR SIGIL"
	relic.desc_text = "The full benefits package: +20 Max Health. Dental implied."
	relic.relic_color = Color(0.6, 0.85, 1.0)
	place(relic, Vector2(500, -290))
