# brittney_estate.gd
# NUTTINGS ESTATE: the non-lethal duel (BOSS 13). She picked the
# venue: her own training room, no cameras, no witnesses. The one
# place she gets to be exactly what she is.

extends RoomBase

const BRITTNEY := preload("res://scenes/enemies/brittney_duel.tscn")

const IVORY := Color(0.9, 0.87, 0.8)
const ROSE := Color(0.85, 0.6, 0.7)

var _boss: BrittneyDuel = null
var _fight_started: bool = false


func _build() -> void:
	spawn_points = {&"default": Vector2(150, 560)}
	camera_rect = Rect2(-280, -900, 2160, 2200)
	kill_y = 1200.0

	solid(-280, -700, 80, 1560, IVORY.darkened(0.5))
	solid(1600, -700, 80, 1560, IVORY.darkened(0.5))
	solid(-200, 660, 1800, 200, IVORY.darkened(0.3))

	# a training room nobody is supposed to know about
	decor(200, 200, 60, 460, ROSE.darkened(0.3))      # heavy bag
	decor(1200, 420, 300, 240, IVORY)
	sign_label(Vector2(1230, 390), "AWARDS (dusted weekly, looked at never)", 12)
	sign_label(Vector2(330, 540), "(The heavy bag has seen things. Mostly her schedule.)", 12)
	sign_label(Vector2(700, 600), "NO CAMERAS PAST THIS POINT.\n(the only honest sign on the property)", 12)


func _populate() -> void:
	var out := Door.new()
	out.door_label = "← THE ESTATES"
	out.target_scene = "res://scenes/levels/celebrity_estates.tscn"
	out.target_spawn = &"from_brittney"
	place(out, Vector2(60, 605))

	if GameState.has_flag(&"brittney_duel_done"):
		# post-duel: she's an ally now, and a person
		var brittney := NPCBase.new()
		brittney.npc_name = "BRITTNEY"
		brittney.body_color = Color(0.92, 0.55, 0.7)
		brittney.lines = ["Card working out? Doors behaving?",
			"Cut the applause, you cut the power. I meant that literally.",
			"When this is over, I'm doing one honest interview. ONE. Then a very long nap."]
		place(brittney, Vector2(850, 615))
		return
	_boss = BRITTNEY.instantiate()
	_boss.arena_left = 100.0
	_boss.arena_right = 1500.0
	place(_boss, Vector2(1000, 530))
	_boss.duel_ended.connect(_on_duel_ended)


func _physics_process(delta: float) -> void:
	super(delta)
	if _fight_started or _boss == null:
		return
	if player.global_position.x > 420.0:
		_start_fight()


func _start_fight() -> void:
	_fight_started = true
	DialogueSystem.start([
		{"speaker": "BRITTNEY", "text": "You found the one room without cameras. Good instinct."},
		{"speaker": "DA'HERM", "text": "I came for information."},
		{"speaker": "BRITTNEY", "text": "And I don't hand the dangerous kind to people who fold. So: hands up. First one to forty percent buys lunch."},
		{"speaker": "DA'HERM", "text": "Wait - you can FIGHT?"},
		{"speaker": "BRITTNEY", "text": "(rolling her shoulders) Everyone keeps assuming I can't do ANYTHING. It's my favorite weapon."},
	])
	DialogueSystem.finished.connect(_show_boss_bar, CONNECT_ONE_SHOT)


func _show_boss_bar() -> void:
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("BRITTNEY NUTTINGS\nNon-lethal duel. \"Tests player assumptions.\"")
		hud.show_boss("BRITTNEY NUTTINGS", _boss.health)


func _on_duel_ended() -> void:
	pass  # flags, relic, and autosave are handled inside the duel script
