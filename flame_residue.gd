# george_npc.gd
# GEORGE. Encounter #1 (13_VERTICAL_SLICE_SPEC, canon dialogue).
#
# Rules enforced (12_CLAUDE_DEVELOPMENT_RULES 9-11):
# - Never explained. Never glows. Dialogue box identical to everyone's.
# - "So it seems" used once, here, where canon places it.
# - The fragment banner does not explain what a fragment is.
#   The player "does not understand its importance" - by design.
# - Visual: circles/soft forms (09_ART_BIBLE) -> round_head, warm color.

class_name GeorgeNPC
extends NPCBase

# Regional Georges: set encounter_flag + first_dialogue per placement.
# "So it seems" stays in Encounter #1 ONLY (Rule 11: sacred, sparing).
@export var encounter_flag: StringName = &"george_encounter_1"

func _init() -> void:
	counts_for_thought_leader = false

@export var first_dialogue: Array = []


func _ready() -> void:
	# (03_STORY_BIBLE, the final scene) George leaves. The player
	# never sees him again. Anywhere.
	if GameState.has_flag(&"true_ending_unlocked"):
		queue_free()
		return
	npc_name = "GEORGE"
	body_color = Color(0.78, 0.7, 0.58)
	accent_color = Color(0.88, 0.8, 0.7)
	body_size = Vector2(44, 70)  # round face, large belly
	round_head = true
	if lines.is_empty():
		lines = ["Nice night.", "Hm."]
	super()


func interact() -> void:
	if not GameState.has_flag(encounter_flag):
		var dialogue := first_dialogue
		if dialogue.is_empty():
			dialogue = [
				{"speaker": "DA'HERM", "text": "You got any money?"},
				{"speaker": "GEORGE", "text": "No."},
				{"speaker": "DA'HERM", "text": "Helpful."},
				{"speaker": "GEORGE", "text": "So it seems."},
			]
		DialogueSystem.start(dialogue)
		DialogueSystem.finished.connect(_on_first_encounter_done, CONNECT_ONE_SHOT)
	else:
		super()


func _on_first_encounter_done() -> void:
	GameState.set_flag(encounter_flag)
	GameState.add_fragment()
	GameState.add_alignment("observational", 2)
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("???\n(He gave you... something? Probably nothing.)")
