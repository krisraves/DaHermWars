# juice.gd
# Autoload. Combat feedback: hitstop + screen shake.
# Small, centralized, and toggleable (UI_UX_BIBLE requires a
# screen shake toggle for accessibility - the flag lives here now
# so the options menu just flips it later).

extends Node

var screen_shake_enabled: bool = true
var hitstop_enabled: bool = true

var _hitstop_active: bool = false
var _shake_strength: float = 0.0
var _shake_decay: float = 14.0


func hitstop(duration: float = 0.05, scale: float = 0.05) -> void:
	if not hitstop_enabled:
		return
	if _hitstop_active:
		return
	_hitstop_active = true
	Engine.time_scale = scale
	# ignore_time_scale = true so the timer runs in real time
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_hitstop_active = false


func shake(strength: float = 6.0) -> void:
	if not screen_shake_enabled:
		return
	_shake_strength = maxf(_shake_strength, strength)


func _process(delta: float) -> void:
	if _shake_strength <= 0.01:
		_shake_strength = 0.0
	else:
		_shake_strength = lerpf(_shake_strength, 0.0, _shake_decay * delta)


func get_shake_offset() -> Vector2:
	if _shake_strength <= 0.0:
		return Vector2.ZERO
	return Vector2(
		randf_range(-_shake_strength, _shake_strength),
		randf_range(-_shake_strength, _shake_strength)
	)


func float_text(pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos + Vector2(-60, 0)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	get_tree().current_scene.add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - 50.0, 1.1)
	tween.tween_property(label, "modulate:a", 0.0, 1.1).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)


func dust(pos: Vector2) -> void:
	# small landing/impact puff: three motes that drift and fade
	var scene := get_tree().current_scene
	if scene == null:
		return
	for i in 3:
		var mote := ColorRect.new()
		mote.size = Vector2(8, 6)
		mote.position = pos + Vector2(-16.0 + 12.0 * i, -4.0)
		mote.color = Color(0.85, 0.82, 0.75, 0.7)
		scene.add_child(mote)
		var tween := mote.create_tween()
		tween.set_parallel(true)
		tween.tween_property(mote, "position", mote.position + Vector2(randf_range(-22.0, 22.0), -14.0), 0.3)
		tween.tween_property(mote, "color:a", 0.0, 0.3)
		tween.chain().tween_callback(mote.queue_free)
