# player_camera.gd
# Smooth-follow camera with directional lookahead.
# The camera leads in the direction Da'Herm faces so the player
# always sees where they're going - critical for a Metroidvania.

extends Camera2D

@export var lookahead_distance: float = 90.0
@export var lookahead_speed: float = 3.5
@export var vertical_offset: float = -30.0

var _current_lookahead: float = 0.0

@onready var _player: Player = get_parent() as Player


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 6.0
	# Camera limits for the M1 test room. Region scenes will set
	# these per-room once room streaming exists (see TECHNICAL_ARCHITECTURE).
	limit_left = -200
	limit_right = 4400
	limit_top = -1400
	limit_bottom = 900


func _process(delta: float) -> void:
	if _player == null:
		return
	var target := lookahead_distance * float(_player.facing)
	_current_lookahead = lerpf(_current_lookahead, target, lookahead_speed * delta)
	offset = Vector2(_current_lookahead, vertical_offset) + Juice.get_shake_offset()
