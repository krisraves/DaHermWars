# bounce_pad.gd
# Courtside Kingdom traversal (11_LEVEL_DESIGN_BIBLE: bounce pads).
# A streetball trampoline-hoop hybrid: launches the player ~360px,
# restores their air dash and air jump because momentum should
# never punish (Final Technical Rule).

class_name BouncePad
extends Area2D

@export var launch_velocity: float = -1150.0

var _visual: ColorRect


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(90, 30)
	shape.shape = rect
	add_child(shape)

	_visual = ColorRect.new()
	_visual.size = Vector2(90, 18)
	_visual.position = Vector2(-45, -9)
	_visual.color = Color(0.95, 0.5, 0.1)
	add_child(_visual)

	var base := ColorRect.new()
	base.size = Vector2(70, 10)
	base.position = Vector2(-35, 9)
	base.color = Color(0.3, 0.3, 0.34)
	add_child(base)

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null:
		return
	if player.velocity.y < -100.0:
		return  # already rising; don't eat upward momentum
	player.velocity.y = launch_velocity
	player.restore_air_moves()
	Juice.shake(2.0)
	var tween := create_tween()
	tween.tween_property(_visual, "scale:y", 0.4, 0.06)
	tween.tween_property(_visual, "scale:y", 1.0, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
