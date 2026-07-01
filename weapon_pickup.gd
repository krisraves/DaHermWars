# relic_pickup.gd
# Relics: permanent passive upgrades (ITEM_DATABASE).
# INFLUENCE RELIC (+25% Followers) · SPONSOR SIGIL (+20 max HP,
# "the benefits package") · DISCOVERY MODULE (Follower orbs home in).

class_name RelicPickup
extends Area2D

@export var relic_id: StringName = &"influence_relic"
@export var display_name: String = "INFLUENCE RELIC"
@export var desc_text: String = "+25% Follower gain."
@export var relic_color: Color = Color(0.5, 0.9, 1.0)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(60, 60)
	shape.shape = rect
	add_child(shape)

	var gem := ColorRect.new()
	gem.size = Vector2(26, 26)
	gem.position = Vector2(-13, -13)
	gem.rotation = 0.785
	gem.color = relic_color
	add_child(gem)
	var halo := ColorRect.new()
	halo.size = Vector2(44, 44)
	halo.position = Vector2(-22, -22)
	halo.rotation = 0.785
	halo.color = Color(relic_color.r, relic_color.g, relic_color.b, 0.25)
	halo.z_index = -1
	add_child(halo)

	body_entered.connect(_on_body_entered)
	var tween := create_tween().set_loops()
	tween.tween_property(self, "rotation_degrees", 8.0, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "rotation_degrees", -8.0, 0.8).set_trans(Tween.TRANS_SINE)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null:
		return
	set_deferred("monitoring", false)
	GameState.grant_relic(relic_id)

	if relic_id == &"sponsor_sigil":
		GameState.max_health += 20
		player.health.max_health = GameState.max_health
		player.health.heal_full()
		GameState.health = player.health.current
		player.health_changed.emit(player.health.current, player.health.max_health)

	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("RELIC — %s\n%s" % [display_name, desc_text])
	Juice.hitstop(0.2, 0.02)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2.2, 2.2), 0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(queue_free)
