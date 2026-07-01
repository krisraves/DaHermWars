# true_gate.gd
# THE DOOR TO THE HEADLINER (03_STORY_BIBLE: secret final arena).
# Before the Good Ending, there is no door here. After it, the door
# is a mirror: it lists what you haven't understood yet. When
# nothing is missing, the Perfect Joke assembles - as a COUNT, as a
# feeling, never as text (RULE 12) - and the door admits you.

class_name TrueGate
extends Interactable

func _init() -> void:
	prompt_text = "[E] ???"


func _ready() -> void:
	super()
	var slab := ColorRect.new()
	slab.size = Vector2(90, 130)
	slab.position = Vector2(-45, -130)
	slab.color = Color(0.05, 0.04, 0.07)
	add_child(slab)
	var seam := ColorRect.new()
	seam.size = Vector2(4, 110)
	seam.position = Vector2(-2, -120)
	seam.color = Color(0.85, 0.7, 0.3, 0.25)
	add_child(seam)
	if not GameState.has_flag(&"good_ending_unlocked"):
		slab.color = Color(0.12, 0.1, 0.16)  # just wall, honest
		seam.visible = false


func interact() -> void:
	if not GameState.has_flag(&"good_ending_unlocked"):
		DialogueSystem.start_simple("", [
			"(There is no door here.)",
			"(There is very specifically no door here.)"])
		return
	var missing := GameState.true_ending_missing()
	if not missing.is_empty():
		var lines := ["(The seam glows. The door is a mirror - it shows what you haven't understood yet:)"]
		for item in missing:
			lines.append("- " + item)
		DialogueSystem.start_simple("", lines)
		return
	if GameState.has_flag(&"perfect_joke_assembled"):
		_enter()
		return
	GameState.set_flag(&"perfect_joke_assembled")
	SaveSystem.autosave()
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("THE PERFECT JOKE — ASSEMBLED\nYou understand it now. (We don't. We never will.)")
	DialogueSystem.start_simple("", [
		"(Fifteen fragments settle into place somewhere behind your ribs.)",
		"(It isn't words. It was never going to be words.)",
		"(The door opens.)"])
	DialogueSystem.finished.connect(_enter, CONNECT_ONE_SHOT)


func _enter() -> void:
	GameState.change_room("res://scenes/levels/the_headliner.tscn", &"default")
