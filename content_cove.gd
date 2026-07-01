# the_headliner.gd
# THE HEADLINER (02_WORLD_BIBLE region 13: secret final arena).
# A venue so large the back rows are a rumor. Every seat is sold.
# Every seat has always been sold. Nobody in them has ever laughed.

extends RoomBase

const RAVAGER := preload("res://scenes/enemies/ravager_prime.tscn")

const VOID := Color(0.03, 0.03, 0.06)
const STAGE_GOLD := Color(0.85, 0.72, 0.35)
const CROWD := Color(0.1, 0.1, 0.16)

var _boss: RavagerPrime = null
var _fight_started: bool = false
var _midfight_done: bool = false


func _build() -> void:
	spawn_points = {&"default": Vector2(180, 560)}
	camera_rect = Rect2(-280, -1200, 2860, 2500)
	kill_y = 1400.0

	solid(-280, -1000, 80, 1860, VOID)
	solid(2300, -1000, 80, 1860, VOID)
	solid(-200, 660, 2500, 200, Color(0.08, 0.07, 0.1))

	# the stage
	decor(1300, 600, 900, 60, STAGE_GOLD.darkened(0.45))
	decor(1320, 80, 40, 520, Color(0.5, 0.42, 0.25))   # proscenium
	decor(2140, 80, 40, 520, Color(0.5, 0.42, 0.25))
	decor(1320, 40, 860, 50, Color(0.5, 0.42, 0.25))
	sign_label(Vector2(1520, 0), "THE HEADLINER — TONIGHT: RAVES SUPREME\n(the marquee has never said anything else)", 13)

	# the infinite audience: rows receding upward into the dark
	for row in 6:
		var y := 520.0 - row * 90.0
		var inset := row * 50.0
		decor(-180.0 + inset, y, 1100.0 - inset * 1.6, 26, CROWD.lightened(0.02 * row))
		for seat in 9:
			decor(-150.0 + inset + seat * (1000.0 - inset * 1.6) / 9.0, y - 30.0,
					24, 30, CROWD.lightened(0.05 + 0.02 * row))
	sign_label(Vector2(150, 200), "(Every seat is full.)\n(No one is laughing.)\n(No one has ever laughed.)", 12)
	sign_label(Vector2(400, 620), "(The applause is constant. It has no beginning. You can't remember silence.)", 12)


func _populate() -> void:
	if GameState.has_flag(&"true_ending_unlocked"):
		# the room after: lights up, seats empty, door home
		var out := Door.new()
		out.door_label = "← THE PYRAMID"
		out.target_scene = "res://scenes/levels/laughing_pyramid.tscn"
		out.target_spawn = &"default"
		place(out, Vector2(80, 605))
		sign_label(Vector2(1500, 560), "(An empty stage. A swept floor. Somewhere, an open mic on a Tuesday.)", 12)
		return
	_boss = RAVAGER.instantiate()
	_boss.arena_left = 120.0
	_boss.arena_right = 2200.0
	_boss.floor_y = 660.0
	place(_boss, Vector2(1700, 510))
	_boss.boss_defeated.connect(_on_ravager_defeated)
	_boss.phase_three.connect(_on_phase_three)


func _physics_process(delta: float) -> void:
	super(delta)
	if _fight_started or _boss == null:
		return
	if player.global_position.x > 900.0:
		_start_fight()


func _start_fight() -> void:
	_fight_started = true
	Juice.shake(5.0)
	DialogueSystem.start([
		{"speaker": "RAVES", "text": "D! YOU CAME! Look at this ROOM, man. LOOK AT IT."},
		{"speaker": "DA'HERM", "text": "Raves. Look at THEM. Nobody out there is laughing."},
		{"speaker": "RAVES", "text": "They're APPLAUDING. That's BETTER. Laughter ends, D. Applause you can keep FOREVER."},
		{"speaker": "DA'HERM", "text": "Who told you that?"},
		{"speaker": "RAVES", "text": "(the halo flickers behind his eyes) ...The room did."},
	])
	DialogueSystem.finished.connect(_show_boss_bar, CONNECT_ONE_SHOT)


func _show_boss_bar() -> void:
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("SUPREME BEING: RAVAGER PRIME\n\"That could have been Da'Herm.\"")
		hud.show_boss("RAVAGER PRIME", _boss.health)


func _on_phase_three() -> void:
	if _midfight_done:
		return
	_midfight_done = true
	DialogueSystem.start([
		{"speaker": "RAVES", "text": "WHY ARE YOU STILL SWINGING? I MADE IT. WE made it!"},
		{"speaker": "DA'HERM", "text": "Nobody's laughing, Raves."},
		{"speaker": "RAVES", "text": "(the applause swells until it has a heartbeat) THEY DON'T NEED TO."},
	])


func _on_ravager_defeated() -> void:
	GameState.set_flag(&"boss_ravager_defeated")
	GameState.set_flag(&"true_ending_unlocked")
	SaveSystem.autosave()
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("(somewhere in row thirty, one single person starts to laugh)")
	get_tree().create_timer(2.4).timeout.connect(_roll_george)


func _roll_george() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/ending_george.tscn")
