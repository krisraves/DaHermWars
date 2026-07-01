# costume_pickup.gd
# THE TRASH BAG TUXEDO (08_COSTUMES) - the slice's one costume.
# "Looking successful with no money."
# Per Rule 14: costumes change gameplay (+10% Followers, applied in
# GameState), appearance (player recolor + bowtie), and identity.
# Full wardrobe/equip menu is M5; M4 auto-equips on pickup.

extends Area2D

@export var costume_id: StringName = &"trash_bag_tuxedo"
@export var display_name: String = "TRASH BAG TUXEDO"
@export var bonus_text: String = "+10%% Follower gain. \"That's either genius or mental illness.\""
@export var garment_color: Color = Color(0.1, 0.1, 0.13)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(60, 70)
	shape.shape = rect
	add_child(shape)

	var bag := ColorRect.new()
	bag.size = Vector2(40, 48)
	bag.position = Vector2(-20, -24)
	bag.color = garment_color
	add_child(bag)

	var tie := ColorRect.new()
	tie.size = Vector2(14, 8)
	tie.position = Vector2(-7, -32)
	tie.color = Color(0.95, 0.95, 0.95)
	add_child(tie)

	var shine := ColorRect.new()
	shine.size = Vector2(10, 16)
	shine.position = Vector2(-16, -20)
	shine.color = Color(0.4, 0.4, 0.5, 0.8)
	add_child(shine)

	body_entered.connect(_on_body_entered)

	var tween := create_tween().set_loops()
	tween.tween_property(self, "modulate", Color(1.4, 1.4, 1.4), 0.6)
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.6)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null:
		return
	set_deferred("monitoring", false)
	GameState.grant_costume(costume_id)
	GameState.equip_costume(costume_id)

	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("COSTUME — %s\n%s" % [display_name, bonus_text])

	Juice.hitstop(0.2, 0.02)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(queue_free)
