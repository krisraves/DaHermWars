# fragment_pickup.gd
# A Perfect Joke fragment as a physical pickup. Stores a COUNT and
# nothing else (RULE 12 / SAVE_SYSTEM_SPEC: never store the joke).
# The banner does not explain what a fragment is. Nothing does.

class_name FragmentPickup
extends Area2D

@export var taken_flag: StringName = &""  # set on pickup, checked by rooms


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(50, 50)
	shape.shape = rect
	add_child(shape)
	var shard := ColorRect.new()
	shard.size = Vector2(18, 18)
	shard.position = Vector2(-9, -9)
	shard.rotation = 0.785
	shard.color = Color(0.95, 0.92, 0.8)
	add_child(shard)
	body_entered.connect(_on_body_entered)
	var tween := create_tween().set_loops()
	tween.tween_property(shard, "modulate:a", 0.55, 0.9)
	tween.tween_property(shard, "modulate:a", 1.0, 0.9)


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	set_deferred("monitoring", false)
	GameState.add_fragment()
	if taken_flag != &"":
		GameState.set_flag(taken_flag)
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("??? (%d)\nIt doesn't look like anything. It feels like the middle of a sentence." % GameState.perfect_joke_fragments)
	queue_free()
