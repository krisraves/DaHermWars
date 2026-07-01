# ability_gate_room.gd
# MILESTONE 3: "THE OVERPASS" - ability-gate proof room.
#
# This room exists to deliver one feeling, in order:
#   1. "Can I get there?"   - a gap you obviously cannot cross
#   2. "Not yet."           - forced down into Lower Out East
#   3. THE PICKUP           - Flame Dash, Flame Glove Tier 2
#   4. "NOW I can."         - the dash pit, then back up, then the
#                             original gap, crossed at full speed
#   + a gold ??? secret ledge for players who experiment with
#     jump + air dash. Curiosity pays (Pillar 2).
#
# Success metric (CLAUDE_BUILD_EXECUTION_PROMPT): the player
# immediately understands why older areas should be revisited.
#
# Layout (side view):
#
#   start ----GAP---- upper right .... [hole] .. ???
#     |                                  |
#   lower A [PICKUP] --PIT-- lower B [stairs]

extends Node2D

const COMIC := preload("res://scenes/enemies/open_mic_comic.tscn")
const PICKUP := preload("res://scenes/items/flame_dash_pickup.tscn")

const GROUND := Color(0.22, 0.2, 0.26)
const PLATFORM := Color(0.32, 0.28, 0.38)
const WALL := Color(0.18, 0.22, 0.3)
const TEASE := Color(0.85, 0.65, 0.15)
const KILL_Y := 1400.0

@onready var _player: Player = $Player


func _ready() -> void:
	_build_room()
	_set_camera_limits()
	_spawn_enemies()
	_spawn_pickup()


func _physics_process(_delta: float) -> void:
	if _player.global_position.y > KILL_Y:
		_player.respawn()


func _build_room() -> void:
	# ---- boundaries -----------------------------------------------
	_solid(-280, -700, 80, 2000, WALL)    # left wall
	_solid(3000, -700, 80, 2000, WALL)    # right wall

	# ---- upper level (y 660) ---------------------------------------
	_solid(-200, 660, 1100, 60, GROUND)   # start floor: -200..900
	# THE GAP: 900..1210 (310px - impossible without dash, clean with it)
	_solid(1210, 660, 1350, 60, GROUND)   # upper right A: 1210..2560
	# hole for the stairs: 2560..2760
	_solid(2760, 660, 240, 60, GROUND)    # upper right B: 2760..3000

	# ---- lower level (y 1060) ---------------------------------------
	_solid(-200, 1060, 1750, 140, GROUND)  # lower A: -200..1550
	# THE PIT: 1550..1830 (280px - jump + air dash, kill plane below)
	_solid(1830, 1060, 1170, 140, GROUND)  # lower B: 1830..3000

	# ---- stair platforms up through the hole ------------------------
	_solid(2570, 960, 90, 24, PLATFORM)
	_solid(2670, 860, 90, 24, PLATFORM)
	_solid(2570, 760, 90, 24, PLATFORM)

	# ---- secret route to the ??? ledge -------------------------------
	_solid(1750, 540, 150, 26, PLATFORM)
	_solid(1960, 430, 120, 24, PLATFORM)
	_solid(2150, 320, 220, 30, TEASE)      # the gold ??? ledge

	# ---- signage ------------------------------------------------------
	_sign(Vector2(40, 540), "THE OVERPASS\nMove: A/D  Jump: Space  Punch: J\nDash: SHIFT or K (currently: you don't have one)")
	_sign(Vector2(540, 520), "That gap is NOT happening.\n(yet)\nTry down below.")
	_sign(Vector2(120, 960), "LOWER OUT EAST\nSomething's glowing over there. <-")
	_sign(Vector2(1330, 940), "MIND THE PIT\nJump first. Dash at the top of the arc.")
	_sign(Vector2(2380, 960), "Stairs up ^")
	_sign(Vector2(1270, 540), "Remember this gap?\nNOW you can. <-")
	_sign(Vector2(2160, 250), "You found it.\n\nSo it seems.")


func _spawn_enemies() -> void:
	# Dash-through targets on the upper right + one guard below.
	for pos: Vector2 in [Vector2(1800, 560), Vector2(2300, 560), Vector2(2300, 960)]:
		var comic: OpenMicComic = COMIC.instantiate()
		comic.position = pos
		add_child(comic)


func _spawn_pickup() -> void:
	var pickup := PICKUP.instantiate()
	pickup.position = Vector2(250, 1012)  # pedestal seated on lower A
	add_child(pickup)


func _set_camera_limits() -> void:
	var cam: Camera2D = _player.get_node("Camera2D")
	cam.limit_left = -280
	cam.limit_right = 3080
	cam.limit_top = -700
	cam.limit_bottom = 1300


func _solid(x: float, y: float, w: float, h: float, color: Color) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.position = Vector2(x + w * 0.5, y + h * 0.5)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, h)
	shape.shape = rect
	body.add_child(shape)
	var visual := ColorRect.new()
	visual.size = Vector2(w, h)
	visual.position = Vector2(-w * 0.5, -h * 0.5)
	visual.color = color
	body.add_child(visual)
	add_child(body)


func _sign(pos: Vector2, text: String) -> void:
	var label := Label.new()
	label.position = pos
	label.text = text
	label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)
