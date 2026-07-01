# burrito_pickup.gd
# A Gas Station Burrito, in the wild. Adds one to inventory.

class_name BurritoPickup
extends Area2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(46, 46)
	shape.shape = rect
	add_child(shape)
	var foil := ColorRect.new()
	foil.size = Vector2(32, 16)
	foil.position = Vector2(-16, -8)
	foil.color = Color(0.75, 0.78, 0.82)
	add_child(foil)
	var filling := ColorRect.new()
	filling.size = Vector2(8, 12)
	filling.position = Vector2(12, -6)
	filling.color = Color(0.65, 0.45, 0.2)
	add_child(filling)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	set_deferred("monitoring", false)
	GameState.burritos += 1
	Juice.float_text(global_position + Vector2(0, -34), "+1 BURRITO", Color(0.9, 0.8, 0.5))
	queue_free()
