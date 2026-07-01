# brittney_npc.gd
# BRITTNEY NUTTINGS (04_CHARACTER_BIBLE): The Self-Aware Product.
# "Knows she isn't especially funny. Knows exactly why she's famous."
# Mid-game cameo in the Corporate Tower lobby. Her first conversation
# plants the story turn: the first credible Illuminepstein whisper
# (flag: heard_whisper). She never explains. She can't.

class_name BrittneyNPC
extends NPCBase


func _ready() -> void:
	npc_name = "BRITTNEY NUTTINGS"
	body_color = Color(0.95, 0.8, 0.85)
	accent_color = Color(0.9, 0.7, 0.2)
	body_size = Vector2(34, 80)
	lines = [
		"No, I'm not funny. That doesn't stop people from buying tickets.",
		"They focus-grouped my laugh. The real one tested poorly.",
		"Good luck in Chuckle Yucks. I mean that in every direction.",
	]
	super()


func interact() -> void:
	if not GameState.has_flag(&"heard_whisper"):
		DialogueSystem.start([
			{"speaker": "BRITTNEY NUTTINGS", "text": "You're the busker. Congratulations on the numbers."},
			{"speaker": "DA'HERM", "text": "You watch the numbers?"},
			{"speaker": "BRITTNEY NUTTINGS", "text": "Everyone in this building is a number. Mine's just bigger."},
			{"speaker": "DA'HERM", "text": "That's bleak."},
			{"speaker": "BRITTNEY NUTTINGS", "text": "(quieter) When you get to the island... act surprised."},
			{"speaker": "DA'HERM", "text": "What island?"},
			{"speaker": "BRITTNEY NUTTINGS", "text": "(smiling exactly the right amount) Good luck in Chuckle Yucks."},
		])
		DialogueSystem.finished.connect(_mark_whisper, CONNECT_ONE_SHOT)
	else:
		super()


func _mark_whisper() -> void:
	GameState.set_flag(&"heard_whisper")
	GameState.add_alignment("observational")
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("...what island?")
