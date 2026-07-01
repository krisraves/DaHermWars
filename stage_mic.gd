# raves_npc.gd
# RAVES SUPREME - best friend, quest giver, future final boss.
# Voice (DIALOGUE_BIBLE): charismatic, salesman energy, "Trust me."
# Quest (13_VERTICAL_SLICE_SPEC): earn enough Followers to perform
# at Open Mic Alley. The door checks the number; Raves sells the dream.

class_name RavesNPC
extends NPCBase

const QUEST_TARGET := 50


func _ready() -> void:
	npc_name = "RAVES SUPREME"
	body_color = Color(0.85, 0.78, 0.25)  # knockoff luxury
	accent_color = Color(0.2, 0.18, 0.22)
	body_size = Vector2(36, 80)
	super()


func interact() -> void:
	# POST-TRUE-ENDING: he came back down. (RULE 7: Raves lives.)
	if GameState.has_flag(&"true_ending_unlocked"):
		DialogueSystem.start([
			{"speaker": "RAVES", "text": "Open mic Tuesday. Eight people showed. ZERO of them followed me anywhere."},
			{"speaker": "DA'HERM", "text": "How'd the set go?"},
			{"speaker": "RAVES", "text": "Terrible. One guy laughed once. For REAL, though. I been chasing that laugh for three days."},
			{"speaker": "RAVES", "text": "...This is your fault, by the way. Thanks."},
		])
		return
	# THE OFFER: after the summit falls, the big room needs a body.
	# This conversation is a TRUE ENDING requirement - hear him out.
	if GameState.has_flag(&"good_ending_unlocked"):
		if not GameState.has_flag(&"raves_final_seen"):
			DialogueSystem.start([
				{"speaker": "RAVES", "text": "THERE he is! The man who fired the boss! Yo - I got NEWS."},
				{"speaker": "RAVES", "text": "They offered me the Headliner. The BIG room, D. Infinite seats."},
				{"speaker": "DA'HERM", "text": "Raves. The people who ran that room--"},
				{"speaker": "RAVES", "text": "Are GONE. You cleared them out! Somebody has to take the stage. Why not me? Why not US?"},
				{"speaker": "DA'HERM", "text": "...Us?"},
				{"speaker": "RAVES", "text": "(already walking) Come watch, D. I'm finally gonna be somebody."},
			])
			DialogueSystem.finished.connect(_mark_final_seen, CONNECT_ONE_SHOT)
			return
		DialogueSystem.start_simple("", ["(He's gone. The corner where Raves used to hold court is just a corner.)",
			"(Somewhere under the island, a very big room is filling up.)"])
		return
	if GameState.has_flag(&"dark_chapter_done"):
		DialogueSystem.start([
			{"speaker": "RAVES SUPREME", "text": "Yo. You good? You don't look good."},
			{"speaker": "DA'HERM", "text": "Raves. The competition. It's not what we thought."},
			{"speaker": "RAVES SUPREME", "text": "It's our SHOT, man. Whatever you saw - that's above our pay grade."},
			{"speaker": "DA'HERM", "text": "It has to stop."},
			{"speaker": "RAVES SUPREME", "text": "...You're scaring me. We're THIS close."},
		])
		return
	if GameState.has_flag(&"chuckle_yucks_signed"):
		DialogueSystem.start([
			{"speaker": "RAVES SUPREME", "text": "You SIGNED? We're in. We are IN. I already told three people I know you."},
			{"speaker": "DA'HERM", "text": "You do know me."},
			{"speaker": "RAVES SUPREME", "text": "Yeah but now it's WORTH something. Trust me."},
		])
		return
	if GameState.has_flag(&"finale_seen") and GameState.has_flag(&"raves_quest_done"):
		DialogueSystem.start([
			{"speaker": "RAVES SUPREME", "text": "Chuckle Yucks, baby. The kiosk's right there. Sign. SIGN."},
			{"speaker": "DA'HERM", "text": "What's the catch?"},
			{"speaker": "RAVES SUPREME", "text": "Catch? It's a comedy competition run by a billionaire for free. ...Okay when I say it out loud—  sign anyway."},
		])
		return
	if not GameState.has_flag(&"raves_quest_given"):
		DialogueSystem.start([
			{"speaker": "RAVES SUPREME", "text": "Yo. YO. Big things. Open Mic Alley. That's THE room."},
			{"speaker": "DA'HERM", "text": "The door guy hates me."},
			{"speaker": "RAVES SUPREME", "text": "The door guy hates BROKE. Get 50 followers and watch his whole personality change."},
			{"speaker": "DA'HERM", "text": "Fifty? People barely look at me."},
			{"speaker": "RAVES SUPREME", "text": "Busk. Hustle. Shake down some open micers. Trust me."},
		])
		DialogueSystem.finished.connect(_mark_quest_given, CONNECT_ONE_SHOT)
	elif GameState.followers < QUEST_TARGET:
		DialogueSystem.start([
			{"speaker": "RAVES SUPREME", "text": "%d followers? That's a start. It's not a NUMBER number, but it's a start." % GameState.followers},
		])
	elif not GameState.has_flag(&"raves_quest_done"):
		GameState.set_flag(&"raves_quest_done")
		DialogueSystem.start([
			{"speaker": "RAVES SUPREME", "text": "SEE? Numbers. The door respects you now. Doors are honest like that."},
			{"speaker": "DA'HERM", "text": "That's the saddest true thing you've ever said."},
			{"speaker": "RAVES SUPREME", "text": "We're gonna be rich."},
		])
	else:
		DialogueSystem.start_simple(npc_name, ["Open Mic Alley. Go. I'll catch up - I know a guy."])


func _mark_quest_given() -> void:
	GameState.set_flag(&"raves_quest_given")


func _mark_final_seen() -> void:
	GameState.set_flag(&"raves_final_seen")
	SaveSystem.autosave()
