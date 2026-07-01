# test_room.gd
# MILESTONE 1 movement gym, built in code so geometry is trivial to tweak.
#
# Layout sections, left to right:
#   1. Flat runway          - run feel, acceleration/friction
#   2. Platform staircase   - jump height & buffering
#   3. Gap series           - coyote time, max jump distance
#   4. Wall-jump shaft      - wall slide + wall jump chaining
#   5. High ledge           - "can I get there?" (no - not until Flame Dash)
#
# Success metric (CLAUDE_BUILD_EXECUTION_PROMPT):
# "Moving around is fun for ten minutes."

extends Node2D

const GROUND_COLOR := Color(0.22, 0.2, 0.26)
const PLATFORM_COLOR := Color(0.32, 0.28, 0.38)
const WALL_COLOR := Color(0.18, 0.22, 0.3)
const TEASE_COLOR := Color(0.6, 0.45, 0.1)  # the ledge you can't reach yet

const KILL_Y := 1200.0

@onready var _player: Player = $Player


func _ready() -> void:
	_build_room()


func _physics_process(_delta: float) -> void:
	if _player.global_position.y > KILL_Y:
		_player.respawn()


func _build_room() -> void:
	# -- 1. Flat runway -------------------------------------------------
	_solid(-200, 660, 1400, 200, GROUND_COLOR)

	# -- 2. Platform staircase ------------------------------------------
	_solid(1250, 560, 220, 40, PLATFORM_COLOR)
	_solid(1530, 440, 220, 40, PLATFORM_COLOR)
	_solid(1810, 320, 220, 40, PLATFORM_COLOR)

	# -- 3. Gap series (run + jump distance tests) ----------------------
	_solid(2120, 660, 300, 200, GROUND_COLOR)
	_solid(2560, 660, 260, 200, GROUND_COLOR)   # medium gap
	_solid(3030, 660, 240, 200, GROUND_COLOR)   # big gap, needs full run-up

	# -- 4. Wall-jump shaft ----------------------------------------------
	_solid(3270, -700, 80, 1560, WALL_COLOR)    # left shaft wall
	_solid(3650, -700, 80, 1360, WALL_COLOR)    # right shaft wall (shorter: exit top-right)
	_solid(3350, 660, 300, 200, GROUND_COLOR)   # shaft floor
	_solid(3730, 660, 600, 200, GROUND_COLOR)   # landing past the shaft

	# -- 5. The tease ledge (Flame Dash gate preview) --------------------
	# Visible, obviously interesting, deliberately out of reach.
	# This is the Metroidvania promise: "Not yet."
	_solid(4050, -820, 280, 40, TEASE_COLOR)
	_sign(Vector2(4100, -880), "???")

	# -- Signage ---------------------------------------------------------
	_sign(Vector2(60, 560), "OUT EAST MOVEMENT GYM\nMove: A/D   Jump: Space (hold)\nPunch: J   Reset: R   Debug: F1")
	_sign(Vector2(3380, 520), "WALL SHAFT\nHold toward wall to slide\nJump off walls to climb")


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
