# combat_room.gd
# MILESTONE 2 combat gym: "THE BACK ROOM OPEN MIC"
#
# Layout, left to right:
#   1. Training corner  - invulnerable dummy; test punch feel safely
#   2. The stage        - flat arena, 3 Open Mic Comics
#   3. Split platforms  - fight while using M1 movement (combat and
#                         movement must feel good TOGETHER)
#
# When every comic goes down, the next wave walks in after a short
# countdown - because in Out East, the open mic never ends.
# Success metric (CLAUDE_BUILD_EXECUTION_PROMPT): fighting remains
# fun after repeated encounters.

extends Node2D

const COMIC := preload("res://scenes/enemies/open_mic_comic.tscn")
const DUMMY := preload("res://scenes/enemies/training_dummy.tscn")

const GROUND_COLOR := Color(0.22, 0.2, 0.26)
const PLATFORM_COLOR := Color(0.32, 0.28, 0.38)
const STAGE_COLOR := Color(0.3, 0.18, 0.2)
const KILL_Y := 1200.0

const COMIC_SPAWNS := [
	Vector2(1500, 560), Vector2(1900, 560), Vector2(2350, 400),
]

var _alive_count: int = 0
var _wave: int = 0

@onready var _player: Player = $Player
@onready var _wave_label: Label = $WaveLabel


func _ready() -> void:
	_player.has_flame_dash = true  # combat gym assumes current abilities
	_build_room()
	_set_camera_limits()
	_spawn_dummy(Vector2(550, 580))
	_spawn_wave()


func _physics_process(_delta: float) -> void:
	if _player.global_position.y > KILL_Y:
		_player.respawn()


# ------------------------------------------------------------------ waves

func _spawn_wave() -> void:
	_wave += 1
	_alive_count = 0
	for pos in COMIC_SPAWNS:
		var comic: OpenMicComic = COMIC.instantiate()
		comic.position = pos
		comic.died.connect(_on_enemy_died)
		add_child(comic)
		_alive_count += 1
	_wave_label.text = "OPEN MIC NIGHT — SET %d" % _wave


func _on_enemy_died(_enemy: EnemyBase) -> void:
	_alive_count -= 1
	if _alive_count <= 0:
		_run_intermission()


func _run_intermission() -> void:
	_wave_label.text = "GOOD SET."
	await get_tree().create_timer(1.0).timeout
	for i in range(3, 0, -1):
		_wave_label.text = "NEXT OPEN MIC IN %d..." % i
		await get_tree().create_timer(1.0).timeout
	_spawn_wave()


func _spawn_dummy(pos: Vector2) -> void:
	var dummy := DUMMY.instantiate()
	dummy.position = pos
	add_child(dummy)


# ------------------------------------------------------------------ geometry

func _build_room() -> void:
	# 1. Training corner
	_solid(-200, 660, 1100, 200, GROUND_COLOR)
	_solid(700, 200, 80, 460, GROUND_COLOR)  # wall separating training corner
	_sign(Vector2(380, 460), "TRAINING CORNER\nThe Perfect Audience Member\n(practice edition)\nHe never reacts. Ever.")

	# 2. The stage
	_solid(900, 660, 1800, 200, STAGE_COLOR)
	_sign(Vector2(1500, 300), "THE BACK ROOM\nOpen Mic Comics believe you're\nstealing their stage time.\nWatch the red tell. Punish the recovery.")

	# 3. Split platforms - vertical play during fights
	_solid(2200, 460, 240, 36, PLATFORM_COLOR)
	_solid(2520, 340, 240, 36, PLATFORM_COLOR)
	_solid(2700, 660, 900, 200, GROUND_COLOR)
	_solid(3560, 200, 80, 660, GROUND_COLOR)  # right wall (wall-slide escape)

	_sign(Vector2(60, 560), "COMBAT GYM\nPunch: J   Move: A/D   Jump: Space\nReset: R   Debug: F1")


func _set_camera_limits() -> void:
	var cam: Camera2D = _player.get_node("Camera2D")
	cam.limit_left = -200
	cam.limit_right = 3700
	cam.limit_top = -800
	cam.limit_bottom = 900


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
