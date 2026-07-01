# former_winner_manor.gd
# THE WINNER'S ESTATE (interior). One man, one trophy room, no staff,
# no summons. The FORMER WINNER (BOSS 15) -> PERFECT JOKE FRAGMENT.

extends RoomBase

const WINNER := preload("res://scenes/enemies/former_winner.tscn")
const FRAGMENT := preload("res://scripts/items/fragment_pickup.gd")

const IVORY := Color(0.6, 0.57, 0.52)
const GOLD := Color(0.78, 0.66, 0.3)

var _boss: FormerWinner = null
var _fight_started: bool = false


func _build() -> void:
	spawn_points = {&"default": Vector2(150, 560)}
	camera_rect = Rect2(-280, -900, 2160, 2200)
	kill_y = 1200.0

	solid(-280, -700, 80, 1560, IVORY.darkened(0.4))
	solid(1600, -700, 80, 1560, IVORY.darkened(0.4))
	solid(-200, 660, 1800, 200, IVORY.darkened(0.2))

	# the trophy room: shelves of first places, lights off
	for i in 5:
		decor(260.0 + i * 240.0, 300, 140, 30, GOLD.darkened(0.2))
		decor(290.0 + i * 240.0, 250, 30, 50, GOLD)
		decor(350.0 + i * 240.0, 256, 24, 44, GOLD.darkened(0.1))
	decor(1280, 420, 200, 240, IVORY.lightened(0.08))  # the trophy case
	sign_label(Vector2(1300, 390), "CHUCKLE YUCKS — GRAND CHAMPION", 12)
	sign_label(Vector2(300, 520), "(Every light is off. He knows where everything is.)", 12)


func _populate() -> void:
	var out := Door.new()
	out.door_label = "← SPECIAL ESTATES"
	out.target_scene = "res://scenes/levels/special_estates.tscn"
	out.target_spawn = &"from_manor"
	place(out, Vector2(60, 605))

	if GameState.has_flag(&"boss_winner_defeated"):
		if not GameState.has_flag(&"fragment_winner_taken"):
			_spawn_reward()
		return
	_boss = WINNER.instantiate()
	_boss.arena_left = 80.0
	_boss.arena_right = 1540.0
	_boss.floor_y = 660.0
	place(_boss, Vector2(900, 525))
	_boss.boss_defeated.connect(_on_boss_defeated)


func _physics_process(delta: float) -> void:
	super(delta)
	if _fight_started or _boss == null:
		return
	if player.global_position.x > 380.0:
		_start_fight()


func _start_fight() -> void:
	_fight_started = true
	Juice.shake(5.0)
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("THE FORMER WINNER\n\"Got everything. Still miserable.\"")
		hud.show_boss("THE FORMER WINNER", _boss.health)


func _on_boss_defeated() -> void:
	GameState.set_flag(&"boss_winner_defeated")
	SaveSystem.autosave()
	_spawn_reward()


func _spawn_reward() -> void:
	var fragment := FragmentPickup.new()
	fragment.taken_flag = &"fragment_winner_taken"
	place(fragment, Vector2(1340, 600))
