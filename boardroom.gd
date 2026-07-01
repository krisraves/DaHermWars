# ending_george.gd
# GEORGE'S FINAL SCENE (03_STORY_BIBLE - dialogue verbatim).
# RULE 10: ordinary. No glow. No reveal. A man, a swept floor,
# and the only other sanctioned "So it seems" in the entire game
# (RULE 11: canon explicitly scripts it here).
# Afterward, the player never sees him again.

extends Node2D

var _george: Node2D


func _ready() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(1480, 920)
	bg.position = Vector2(-100, -100)
	bg.color = Color(0.05, 0.05, 0.07)
	bg.z_index = -10
	add_child(bg)

	var floor_rect := ColorRect.new()
	floor_rect.size = Vector2(1480, 120)
	floor_rect.position = Vector2(-100, 600)
	floor_rect.color = Color(0.1, 0.1, 0.12)
	add_child(floor_rect)

	# outside the Headliner. a side door. a streetlight that works.
	var light := ColorRect.new()
	light.size = Vector2(8, 220)
	light.position = Vector2(640, 380)
	light.color = Color(0.3, 0.3, 0.32)
	add_child(light)
	var lamp := ColorRect.new()
	lamp.size = Vector2(40, 16)
	lamp.position = Vector2(624, 368)
	lamp.color = Color(0.9, 0.85, 0.6)
	add_child(lamp)

	# Da'Herm
	var daherm := ColorRect.new()
	daherm.size = Vector2(36, 76)
	daherm.position = Vector2(420, 524)
	daherm.color = Color(0.85, 0.3, 0.25)
	add_child(daherm)

	# George. A broom. That's it.
	_george = Node2D.new()
	_george.position = Vector2(820, 600)
	var body := ColorRect.new()
	body.size = Vector2(44, 70)
	body.position = Vector2(-22, -70)
	body.color = Color(0.78, 0.7, 0.58)
	_george.add_child(body)
	var broom := ColorRect.new()
	broom.size = Vector2(6, 78)
	broom.position = Vector2(30, -78)
	broom.color = Color(0.5, 0.4, 0.3)
	_george.add_child(broom)
	add_child(_george)

	get_tree().create_timer(1.2).timeout.connect(_scene)


func _scene() -> void:
	DialogueSystem.start([
		{"speaker": "", "text": "(Outside, by the side door. George is sweeping. Of course he is.)"},
		{"speaker": "DA'HERM", "text": "Was there ever a Perfect Joke?"},
		{"speaker": "", "text": "(George smiles. A long pause.)"},
		{"speaker": "GEORGE", "text": "So it seems."},
		{"speaker": "DA'HERM", "text": "That's not an answer."},
		{"speaker": "GEORGE", "text": "Neither is laughter."},
	])
	DialogueSystem.finished.connect(_george_leaves, CONNECT_ONE_SHOT)


func _george_leaves() -> void:
	# he just walks off. ordinary. the player never sees him again.
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_george, "position:x", _george.position.x + 700.0, 6.0)
	tween.tween_property(_george, "modulate:a", 0.0, 6.0)
	tween.chain().tween_interval(1.0)
	tween.chain().tween_callback(_roll_true_ending)


func _roll_true_ending() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/ending_true.tscn")
