# boss_arena.gd
# THE UNDERGROUND CLUB - Disgraced Comedian arena
# (13_VERTICAL_SLICE_SPEC: abandoned comedy venue).
# Walk in, cross the stage line, the marquee lights up, fight.
# Reward: FLAME DASH - the canonical first-boss reward slot.
# A dash-gated ledge sits in this very room so the upgrade pays off
# thirty seconds after you earn it (Pillar 3: revisit with new powers).

extends RoomBase

const BOSS := preload("res://scenes/enemies/disgraced_comedian.tscn")
const DASH_PICKUP := preload("res://scenes/items/flame_dash_pickup.tscn")
const ORB := preload("res://scripts/items/follower_orb.gd")

const CONCRETE := Color(0.17, 0.16, 0.19)
const STAGE := Color(0.28, 0.14, 0.18)

var _boss: DisgracedComedian = null
var _fight_started: bool = false


func _build() -> void:
	spawn_points = {&"default": Vector2(150, 560)}
	camera_rect = Rect2(-280, -800, 2280, 2100)
	kill_y = 1200.0

	solid(-280, -700, 80, 1560, CONCRETE)
	solid(1920, -700, 80, 1560, CONCRETE)
	solid(-200, 660, 2120, 200, CONCRETE)
	solid(-200, -140, 2120, 80, CONCRETE)  # low ceiling - it's a basement

	# the dead stage
	decor(1200, 560, 500, 100, STAGE)
	decor(1340, 280, 220, 60, Color(0.3, 0.3, 0.34))
	sign_label(Vector2(1364, 296), "TONIGHT: HIM. AGAIN.", 13)

	# overturned chairs (the audience left a decade ago)
	for x in [500, 640, 780, 920]:
		decor(x, 620, 40, 40, Color(0.25, 0.22, 0.28))

	# dash-gated payoff ledge: a 300px pit to a Follower stash.
	# Impossible on the way in. Trivial on the way out.
	solid(660, 380, 130, 22, STAGE)
	solid(1080, 380, 130, 22, STAGE)   # 290px gap - dash required
	sign_label(Vector2(1090, 330), "(how'd anything get over THERE?)", 12)

	sign_label(Vector2(30, 520), "THE UNDERGROUND CLUB\nIt smells like 2009 down here.")


func _populate() -> void:
	# exit back up
	# deeper: COMEDY UNDERGROUND (opens after the dark chapter -
	# Da'Herm goes looking for the people the machine forgot)
	var deeper := Door.new()
	deeper.door_label = "DEEPER ↓"
	deeper.target_scene = "res://scenes/levels/comedy_underground.tscn"
	deeper.target_spawn = &"default"
	deeper.required_flag = &"dark_chapter_done"
	deeper.flag_gate_line = "(Chained. A note, handwritten: 'We open when you understand.')"
	place(deeper, Vector2(1800, 605))

	var door := Door.new()
	door.door_label = "↑ OPEN MIC ALLEY"
	door.target_scene = "res://scenes/levels/open_mic_alley.tscn"
	door.target_spawn = &"from_basement"
	place(door, Vector2(60, 605))

	# follower stash on the dash-gated ledge
	for offset in [Vector2(1110, 340), Vector2(1150, 340), Vector2(1190, 340)]:
		var orb := ORB.new()
		orb.value = 10
		place(orb, offset)

	if GameState.has_flag(&"boss_disgraced_defeated"):
		# the basement reopens as a Comedy Circuit venue once it stops
		# bombing - the network's second node
		GameState.register_circuit_node("THE UNDERGROUND CLUB",
			GameState.current_room, &"default")
		place(CircuitPhone.new(), Vector2(300, 615))
		# recover the dash if death interrupted the pickup
		if not GameState.has_flame_dash:
			place(DASH_PICKUP.instantiate(), Vector2(1000, 590))
		return

	_boss = BOSS.instantiate()
	_boss.arena_left = 60.0
	_boss.arena_right = 1840.0
	place(_boss, Vector2(1430, 520))
	_boss.boss_defeated.connect(_on_boss_defeated)


func _physics_process(delta: float) -> void:
	super(delta)
	if _fight_started or _boss == null:
		return
	if player.global_position.x > 560.0:
		_start_fight()


func _start_fight() -> void:
	_fight_started = true
	Juice.shake(5.0)
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("THE DISGRACED COMEDIAN\n\"I never left. The industry left.\"")
		hud.show_boss("THE DISGRACED COMEDIAN", _boss.health)


func _on_boss_defeated() -> void:
	GameState.set_flag(&"boss_disgraced_defeated")
	GameState.register_circuit_node("THE UNDERGROUND CLUB",
		GameState.current_room, &"default")
	place(CircuitPhone.new(), Vector2(300, 615))
	SaveSystem.autosave()  # spec: autosave on boss defeat
	place(DASH_PICKUP.instantiate(), Vector2(1000, 590))
	Juice.float_text(Vector2(1000, 500), "He left something behind.", Color(1, 0.7, 0.3))
