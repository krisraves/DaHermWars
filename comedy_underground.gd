# pyramid_summit.gd
# THE SUMMIT. TUFF TIDDY (BOSS 24) - all three phases, down to the
# living baby-oil demon. His fall unlocks the GOOD ENDING.

extends RoomBase

const TUFF := preload("res://scenes/enemies/tuff_tiddy.tscn")
const RESIDUE := preload("res://scripts/interactables/flame_residue.gd")
const OFFER := preload("res://scripts/interactables/the_offer.gd")

const GOLD := Color(0.85, 0.7, 0.3)
const OBSIDIAN := Color(0.1, 0.08, 0.14)

var _boss: TuffTiddy = null
var _fight_started: bool = false


func _build() -> void:
	spawn_points = {&"default": Vector2(150, 560)}
	camera_rect = Rect2(-280, -900, 2260, 2200)
	kill_y = 1200.0

	solid(-280, -700, 80, 1560, OBSIDIAN)
	solid(1700, -700, 80, 1560, OBSIDIAN)
	solid(-200, 660, 1900, 200, OBSIDIAN.lightened(0.06))

	# the summit stage: one spotlight, one man, one ego
	decor(700, 200, 500, 60, GOLD.darkened(0.3))
	decor(940, 260, 30, 400, GOLD.darkened(0.5))
	sign_label(Vector2(720, 170), "THE SUMMIT — PRODUCED BY TUFF TIDDY\n(EXECUTIVE PRODUCED BY TUFF TIDDY)", 12)
	sign_label(Vector2(300, 540), "(He's been watching the whole climb. He thinks it's a great episode.)", 12)


func _populate() -> void:
	var down := Door.new()
	down.door_label = "← COUNCIL FLOOR"
	down.target_scene = "res://scenes/levels/laughing_pyramid.tscn"
	down.target_spawn = &"from_summit"
	place(down, Vector2(60, 605))

	if GameState.has_flag(&"boss_tuff_defeated"):
		if GameState.has_flag(&"good_ending_unlocked") and not GameState.has_infernal_mastery:
			var residue: Interactable = RESIDUE.new()
			place(residue, Vector2(950, 660))
			sign_label(Vector2(700, 560), "(The stage is empty. The spotlight stayed on. Something glints where he stood.)", 12)
		return
	# THE OFFER (Bad Ending route): the contract sits before the
	# fight trigger at x>420, so the choice precedes the violence
	var offer: Interactable = OFFER.new()
	place(offer, Vector2(280, 660))

	_boss = TUFF.instantiate()
	_boss.arena_left = 80.0
	_boss.arena_right = 1640.0
	_boss.floor_y = 660.0
	place(_boss, Vector2(950, 515))
	_boss.boss_defeated.connect(_on_tuff_defeated)


func _physics_process(delta: float) -> void:
	super(delta)
	if _fight_started or _boss == null:
		return
	if player.global_position.x > 420.0:
		_start_fight()


func _start_fight() -> void:
	_fight_started = true
	Juice.shake(7.0)
	DialogueSystem.start([
		{"speaker": "TUFF TIDDY", "text": "THE BUSKER! Loved your arc. The dark stuff in the middle? GREAT television."},
		{"speaker": "DA'HERM", "text": "Those were people."},
		{"speaker": "TUFF TIDDY", "text": "People ARE television, kid. Now — let's make this funny. I'll carry us. I always do."},
	])
	DialogueSystem.finished.connect(_show_boss_bar, CONNECT_ONE_SHOT)


func _show_boss_bar() -> void:
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("TUFF TIDDY\n\"He genuinely believes he is funny.\"")
		hud.show_boss("TUFF TIDDY", _boss.health)


func _on_tuff_defeated() -> void:
	GameState.set_flag(&"boss_tuff_defeated")
	GameState.set_flag(&"good_ending_unlocked")
	SaveSystem.autosave()
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("THE PYRAMID GOES QUIET")
	get_tree().create_timer(2.0).timeout.connect(_roll_ending)


func _roll_ending() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/ending_good.tscn")
