# castle_interior.gd
# Inside the CONTENT CASTLE (Influencer Hills). The mansion has been
# streaming its own interior, unedited, for four years. It would
# like you to be in the next one. Reward: FOLLOWER BOOSTER.

extends RoomBase

const CASTLE := preload("res://scenes/enemies/content_castle.tscn")
const RELIC := preload("res://scripts/items/relic_pickup.gd")

const PASTEL := Color(0.85, 0.75, 0.8)
const PINK := Color(0.95, 0.6, 0.8)

var _boss: ContentCastle = null
var _fight_started: bool = false


func _build() -> void:
	spawn_points = {&"default": Vector2(150, 560)}
	camera_rect = Rect2(-280, -900, 2160, 2200)
	kill_y = 1200.0

	solid(-280, -700, 80, 1560, PASTEL.darkened(0.5))
	solid(1600, -700, 80, 1560, PASTEL.darkened(0.5))
	solid(-200, 660, 1800, 200, PASTEL.darkened(0.3))

	# a foyer designed entirely for thumbnails
	decor(400, 200, 60, 460, PINK.darkened(0.2))      # statement column
	decor(1100, 200, 60, 460, PINK.darkened(0.2))
	decor(620, 140, 340, 50, Color(0.95, 0.9, 0.85))  # chandelier mount
	sign_label(Vector2(640, 110), "LIVE — 4 YEARS, 0 VIEWERS, ALL CONFIDENCE", 12)
	sign_label(Vector2(300, 540), "(Every wall has a ring light. Every ring light is on.)", 12)
	sign_label(Vector2(900, 600), "WELCOME TO THE TOUR.\n(you did not ask for the tour.)", 12)


func _populate() -> void:
	var out := Door.new()
	out.door_label = "← THE HILLS"
	out.target_scene = "res://scenes/levels/influencer_hills.tscn"
	out.target_spawn = &"from_castle"
	place(out, Vector2(60, 605))

	if GameState.has_flag(&"boss_castle_defeated"):
		_spawn_reward()
		return
	_boss = CASTLE.instantiate()
	_boss.arena_left = 100.0
	_boss.arena_right = 1500.0
	_boss.floor_y = 660.0
	place(_boss, Vector2(800, 360))
	_boss.boss_defeated.connect(_on_boss_defeated)


func _physics_process(delta: float) -> void:
	super(delta)
	if _fight_started or _boss == null:
		return
	if player.global_position.x > 420.0:
		_start_fight()


func _start_fight() -> void:
	_fight_started = true
	Juice.shake(4.0)
	DialogueSystem.start([
		{"speaker": "CONTENT CASTLE", "text": "(the front door locks itself, politely) WELCOME BACK TO THE CHANNEL."},
		{"speaker": "DA'HERM", "text": "I have never been here."},
		{"speaker": "CONTENT CASTLE", "text": "WE SAY THAT TO EVERYONE. IT BUILDS PARASOCIAL TRUST."},
	])
	DialogueSystem.finished.connect(_show_boss_bar, CONNECT_ONE_SHOT)


func _show_boss_bar() -> void:
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("CONTENT CASTLE\n\"A living mansion that creates content.\"")
		hud.show_boss("CONTENT CASTLE", _boss.health)


func _on_boss_defeated() -> void:
	GameState.set_flag(&"boss_castle_defeated")
	SaveSystem.autosave()
	_spawn_reward()


func _spawn_reward() -> void:
	if GameState.has_relic(&"follower_booster"):
		return
	var booster: Area2D = RELIC.new()
	booster.relic_id = &"follower_booster"
	booster.display_name = "FOLLOWER BOOSTER"
	booster.desc_text = "Salvaged from the house's growth strategy. +25% follower gain."
	booster.relic_color = Color(0.95, 0.6, 0.8)
	place(booster, Vector2(800, 600))
