# screening_room.gd
# THE SCREENING ROOM (Floor 3 of the Pyramid). They screen The
# Special here, forever, to nobody. BOSS 23 -> the FINAL FRAGMENT.

extends RoomBase

const SPECIAL := preload("res://scenes/enemies/the_special.tscn")
const FRAGMENT := preload("res://scripts/items/fragment_pickup.gd")

const DARK := Color(0.08, 0.07, 0.1)
const SCREENGLOW := Color(0.5, 0.2, 0.22)

var _boss: TheSpecial = null
var _fight_started: bool = false


func _build() -> void:
	spawn_points = {&"default": Vector2(140, 560)}
	camera_rect = Rect2(-280, -900, 2060, 2200)
	kill_y = 1200.0

	solid(-280, -700, 80, 1560, DARK)
	solid(1500, -700, 80, 1560, DARK)
	solid(-200, 660, 1700, 200, DARK.lightened(0.05))

	decor(1100, 240, 320, 220, SCREENGLOW)           # the screen, always on
	for i in 4:
		decor(300.0 + i * 180.0, 600, 110, 60, DARK.lightened(0.1))  # empty seats
	sign_label(Vector2(350, 540), "(Every seat is empty. The runtime counter says YEAR 6.)", 12)
	sign_label(Vector2(1110, 210), "NOW SHOWING: THE SPECIAL", 12)


func _populate() -> void:
	var out := Door.new()
	out.door_label = "← FLOOR 3"
	out.target_scene = "res://scenes/levels/laughing_pyramid.tscn"
	out.target_spawn = &"from_screening"
	place(out, Vector2(60, 605))

	if GameState.has_flag(&"boss_special_defeated"):
		if not GameState.has_flag(&"fragment_special_taken"):
			_spawn_reward()
		return
	_boss = SPECIAL.instantiate()
	_boss.arena_left = 100.0
	_boss.arena_right = 1400.0
	place(_boss, Vector2(900, 430))
	_boss.boss_defeated.connect(_on_boss_defeated)


func _physics_process(delta: float) -> void:
	super(delta)
	if _fight_started or _boss == null:
		return
	if player.global_position.x > 360.0:
		_start_fight()


func _start_fight() -> void:
	_fight_started = true
	Juice.shake(4.0)
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("THE SPECIAL\n\"Manifestation of manufactured fame.\"")
		hud.show_boss("THE SPECIAL", _boss.health)


func _on_boss_defeated() -> void:
	GameState.set_flag(&"boss_special_defeated")
	SaveSystem.autosave()
	_spawn_reward()


func _spawn_reward() -> void:
	var fragment := FragmentPickup.new()
	fragment.taken_flag = &"fragment_special_taken"
	place(fragment, Vector2(900, 600))
