# follower_orb.gd
# A small cluster of Followers, floating in the world. Dropped by
# defeated enemies, hidden on rooftops. Per AUDIO_BIBLE: collection
# should feel satisfying - pop tween + float text for now.

class_name FollowerOrb
extends Area2D

@export var value: int = 5


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 40)
	shape.shape = rect
	add_child(shape)

	var glow := ColorRect.new()
	glow.size = Vector2(22, 22)
	glow.position = Vector2(-11, -11)
	glow.color = Color(0.35, 0.85, 1.0, 0.9)
	add_child(glow)

	var core := ColorRect.new()
	core.size = Vector2(10, 10)
	core.position = Vector2(-5, -5)
	core.color = Color(0.9, 1.0, 1.0)
	add_child(core)

	body_entered.connect(_on_body_entered)

	var tween := create_tween().set_loops()
	tween.tween_property(self, "position:y", position.y - 8.0, 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", position.y + 0.0, 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _physics_process(delta: float) -> void:
	# DISCOVERY MODULE relic: the feed comes to you
	if not GameState.has_relic(&"discovery_module"):
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player: Node2D = players[0]
	if global_position.distance_to(player.global_position) < 300.0:
		global_position = global_position.move_toward(player.global_position, 460.0 * delta)


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	set_deferred("monitoring", false)
	GameState.add_followers(value)
	Juice.float_text(global_position + Vector2(0, -30), "+%d" % value, Color(0.4, 0.9, 1.0))
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)
