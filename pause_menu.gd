# hitbox.gd
# Generic attack hitbox. Carries damage + knockback data.
# Attach to an Area2D, enable it during active attack frames.
# Combat pipeline (TECHNICAL_ARCHITECTURE):
# Input -> Attack -> Hit Detection -> Damage -> Knockback -> State Update

class_name Hitbox
extends Area2D

signal hit_landed(hurtbox: Hurtbox)

@export var damage: int = 10
@export var knockback_strength: float = 280.0
@export var knockback_lift: float = -160.0

# Tracks targets already hit this activation so one swing = one hit.
var _hit_this_swing: Array[Hurtbox] = []


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	# Re-arm whenever the hitbox is toggled on.
	monitoring_changed_rearm()


func monitoring_changed_rearm() -> void:
	_hit_this_swing.clear()


func _on_area_entered(area: Area2D) -> void:
	var hurtbox := area as Hurtbox
	if hurtbox == null or hurtbox in _hit_this_swing:
		return
	_hit_this_swing.append(hurtbox)
	hurtbox.receive_hit(self)
	hit_landed.emit(hurtbox)


func knockback_from(source_global_pos: Vector2, target_global_pos: Vector2) -> Vector2:
	var dir := signf(target_global_pos.x - source_global_pos.x)
	if dir == 0.0:
		dir = 1.0
	return Vector2(dir * knockback_strength, knockback_lift)
