# beam_hazard.gd
# The Laughing Pyramid attacks its own guests (BOSS_021: the building
# IS a boss). A wall emitter that drops spotlight strikes near the
# player on a cycle whenever they're in range.

class_name BeamHazard
extends Node2D

@export var interval: float = 2.2
@export var trigger_range: float = 420.0
@export var floor_y: float = 660.0

var _timer: float = 1.0


func _ready() -> void:
	var eye := ColorRect.new()
	eye.size = Vector2(26, 14)
	eye.position = Vector2(-13, -7)
	eye.color = Color(1, 0.9, 0.45)
	add_child(eye)


func _physics_process(delta: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player: Node2D = players[0]
	if absf(player.global_position.x - global_position.x) > trigger_range:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = interval
	var beam := TentacleStrike.new()
	beam.warn_time = 0.55
	beam.active_time = 0.2
	beam.column_height = 440.0
	beam.position = Vector2(player.global_position.x, floor_y)
	get_tree().current_scene.add_child(beam)
