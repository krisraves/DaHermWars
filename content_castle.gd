# flame_dash_pickup.gd
# The first Flame Glove upgrade pickup. Grants Flame Dash on contact,
# fires the unlock banner, and disappears.
# Future Flame Glove tiers (Barrier Burn, Inferno Slam...) will reuse
# this exact pattern with a different ability StringName.

extends Area2D

@export var ability: StringName = &"flame_dash"
@export var banner_text: String = "FLAME DASH — FLAME GLOVE TIER 2\nSHIFT or K. One air dash per jump.\nRemember every gap you couldn't cross."

@onready var _glow: ColorRect = $Glow


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# idle pulse so it reads as important from across the room
	var tween := create_tween().set_loops()
	tween.tween_property(_glow, "modulate:a", 0.3, 0.6)
	tween.tween_property(_glow, "modulate:a", 0.9, 0.6)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null:
		return
	player.grant_ability(ability)

	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner(banner_text)

	Juice.hitstop(0.25, 0.02)
	Juice.shake(8.0)

	set_deferred("monitoring", false)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2.5, 2.5), 0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(queue_free)
