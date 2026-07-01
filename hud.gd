# hurtbox.gd
# Generic damage receiver. The owning body connects to hit_received
# and decides what damage means for it (i-frames, armor, etc).

class_name Hurtbox
extends Area2D

signal hit_received(hitbox: Hitbox)


func receive_hit(hitbox: Hitbox) -> void:
	hit_received.emit(hitbox)
