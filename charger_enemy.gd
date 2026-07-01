# boo_projectile.gd
# A "BOO" falling from the dark above the stage. Audience
# disapproval, weaponized. Built entirely in code.

class_name BooProjectile
extends Area2D

@export var fall_speed: float = 340.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(func(_b): _pop())
	get_tree().create_timer(4.0).timeout.connect(queue_free)

	var label := Label.new()
	label.text = "BOO"
	label.position = Vector2(-22, -16)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.85, 0.3, 0.9))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	add_child(label)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(44, 30)
	shape.shape = rect
	add_child(shape)

	var hitbox := Hitbox.new()
	hitbox.collision_layer = 32
	hitbox.collision_mask = 64
	hitbox.damage = 6
	hitbox.knockback_strength = 180.0
	hitbox.knockback_lift = -120.0
	var hshape := CollisionShape2D.new()
	var hrect := RectangleShape2D.new()
	hrect.size = Vector2(44, 30)
	hshape.shape = hrect
	hitbox.add_child(hshape)
	add_child(hitbox)
	hitbox.hit_landed.connect(func(_h): _pop())


func _physics_process(delta: float) -> void:
	global_position.y += fall_speed * delta


func _pop() -> void:
	queue_free()
