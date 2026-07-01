# training_dummy.gd
# "THE PERFECT AUDIENCE MEMBER (practice edition)"
# Never reacts. Never attacks. Never dies.
# Exists so combat feel can be tested in isolation:
# hitstop, knockback, flash, heat gain - all visible on a target
# that doesn't fight back.

extends EnemyBase


func _ready() -> void:
	super()
	invulnerable = true


func _ai(delta: float) -> void:
	# Just stands there. Completely unimpressed.
	velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
