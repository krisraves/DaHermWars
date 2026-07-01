# weapon_pickup.gd
# Generic weapon pickup, driven by WeaponDB. Adding a new weapon to
# the world: WeaponDB entry + one of these with weapon_id set.

class_name WeaponPickup
extends Area2D

@export var weapon_id: StringName = &"folding_chair"
@export var auto_equip: bool = true


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(60, 60)
	shape.shape = rect
	add_child(shape)

	var data := WeaponDB.get_weapon(weapon_id)
	var icon := ColorRect.new()
	icon.size = Vector2(34, 34)
	icon.position = Vector2(-17, -17)
	icon.color = data["flash_color"]
	add_child(icon)

	var glow := ColorRect.new()
	glow.size = Vector2(46, 46)
	glow.position = Vector2(-23, -23)
	glow.color = Color(1, 1, 1, 0.18)
	glow.z_index = -1
	add_child(glow)

	body_entered.connect(_on_body_entered)
	var tween := create_tween().set_loops()
	tween.tween_property(self, "position:y", position.y - 6.0, 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", position.y, 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	set_deferred("monitoring", false)
	GameState.grant_weapon(weapon_id)
	if auto_equip:
		GameState.equip_weapon(weapon_id)
	var data := WeaponDB.get_weapon(weapon_id)
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("WEAPON — %s\n%s" % [data["name"], data["desc"]])
	Juice.hitstop(0.15, 0.03)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.25)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)
