# room_base.gd
# Base for all game rooms. Handles the plumbing every room needs:
# registering with GameState, placing the player at the right spawn
# marker after a transition, camera limits, the kill plane, and the
# geometry/decor/sign builders the prototypes established.
# Full room STREAMING (load neighbors, unload distant) lands in M5;
# the vertical slice's rooms are small enough for whole-scene swaps.

class_name RoomBase
extends Node2D

var spawn_points: Dictionary = {}
var kill_y: float = 1400.0
var camera_rect: Rect2 = Rect2(-280, -700, 3500, 2000)

@onready var player: Player = $Player


func _ready() -> void:
	GameState.current_room = scene_file_path
	GameState.in_game = true
	var first_visit := GameState.mark_room_visited(scene_file_path)
	_build()
	_place_player()
	_apply_camera()
	_populate()
	if first_visit:
		SaveSystem.autosave()  # spec: autosave on entering a new region


func _physics_process(_delta: float) -> void:
	if player != null and player.global_position.y > kill_y:
		player.respawn()


# ------------------------------------------------------------ overridables

func _build() -> void:
	pass  # geometry + spawn_points + camera_rect


func _populate() -> void:
	pass  # NPCs, enemies, pickups, interactables


# ------------------------------------------------------------ plumbing

func _place_player() -> void:
	var spawn := GameState.consume_pending_spawn()
	if spawn_points.has(spawn):
		player.global_position = spawn_points[spawn]
	elif spawn_points.has(&"default"):
		player.global_position = spawn_points[&"default"]
	player.set_spawn_point(player.global_position)


func _apply_camera() -> void:
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = int(camera_rect.position.x)
	cam.limit_top = int(camera_rect.position.y)
	cam.limit_right = int(camera_rect.position.x + camera_rect.size.x)
	cam.limit_bottom = int(camera_rect.position.y + camera_rect.size.y)
	cam.reset_smoothing()


# ------------------------------------------------------------ builders

func solid(x: float, y: float, w: float, h: float, color: Color) -> void:
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


func decor(x: float, y: float, w: float, h: float, color: Color, z: int = -2) -> void:
	var rect := ColorRect.new()
	rect.position = Vector2(x, y)
	rect.size = Vector2(w, h)
	rect.color = color
	rect.z_index = z
	add_child(rect)


func sign_label(pos: Vector2, text: String, size: int = 16) -> void:
	var label := Label.new()
	label.position = pos
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)


func place(node: Node2D, pos: Vector2) -> Node2D:
	node.position = pos
	add_child(node)
	return node
