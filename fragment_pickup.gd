# quest_db.gd
# Autoload. Quest definitions. States are DERIVED from GameState
# flags rather than stored separately - one source of truth means
# quest state can never desync from story state (and saves stay
# simple). Per QUEST_BIBLE: entries are concise, in-voice.

extends Node

enum QState { LOCKED, AVAILABLE, ACTIVE, COMPLETED }


func get_quests() -> Array:
	# returns [{name, desc, state}] in display order
	return [
		{
			"name": "OPEN MIC DREAMS",
			"desc": "Raves says 50 followers opens doors. \"Trust me.\"",
			"state": _open_mic_dreams(),
		},
		{
			"name": "THE BASEMENT PROBLEM",
			"desc": "Something's been bombing under the Chuckle Hut for ten years.",
			"state": _basement_problem(),
		},
		{
			"name": "SO IT SEEMS",
			"desc": "Georges found: %d. He can't be the same guy. Right?" % _george_count(),
			"state": _so_it_seems(),
		},
		{
			"name": "KING OF THE COURT",
			"desc": "Courtside Kingdom has a king. Kings get challenged.",
			"state": _boss_quest("res://scenes/levels/courtside_kingdom.tscn", &"boss_king_defeated"),
		},
		{
			"name": "DEAD AIR",
			"desc": "Someone in the Wasteland has been recording for ten years straight.",
			"state": _boss_quest("res://scenes/levels/podcast_wasteland.tscn", &"boss_podfather_defeated"),
		},
		{
			"name": "GOLDEN HOUR",
			"desc": "Something on the Hills schedules the sunlight.",
			"state": _boss_quest("res://scenes/levels/influencer_hills.tscn", &"boss_queen_defeated"),
		},
		{
			"name": "SYNERGY",
			"desc": "The Tower monetizes everything. Including visitors.",
			"state": _boss_quest("res://scenes/levels/corporate_tower.tscn", &"boss_brandon_defeated"),
		},
		{
			"name": "THE FEED",
			"desc": "Something in Streaming HQ decides what matters. Disagree with it.",
			"state": _boss_quest("res://scenes/levels/streaming_hq.tscn", &"boss_algorithm_defeated"),
		},
		{
			"name": "THE PATTERN",
			"desc": ("It's real. All of it. This has to stop." \
					if GameState.has_flag(&"dark_chapter_done") \
					else "Brittney mentioned an island. The graffiti mentions a pyramid. Nobody finishes the word 'Illumin—'."),
			"state": QState.ACTIVE if GameState.has_flag(&"heard_whisper") else QState.LOCKED,
		},
		{
			"name": "THE FORGOTTEN",
			"desc": "Below the Underground Club, the closed venues kept their lights. Someone is performing other people's lives.",
			"state": _boss_quest("res://scenes/levels/comedy_underground.tscn", &"boss_hack_defeated"),
		},
		{
			"name": "ONE MORE SET",
			"desc": "The Lost Theater still runs a show. Nobody alive is booked.",
			"state": _boss_quest("res://scenes/levels/lost_theater.tscn", &"boss_headliner_defeated"),
		},
		{
			"name": "THE WINNER'S HOUSE",
			"desc": "One estate answers the door. He won everything once.",
			"state": _boss_quest("res://scenes/levels/former_winner_manor.tscn", &"boss_winner_defeated"),
		},
		{
			"name": "TOUGH ROOM",
			"desc": "There's a room behind a poster. Don't punch anybody in there.",
			"state": _boss_quest("res://scenes/levels/secret_club.tscn", &"boss_crowd_defeated"),
		},
		{
			"name": "ACT SURPRISED",
			"desc": ("The machine is broken at the top. Brittney was right about everything." \
					if GameState.has_flag(&"boss_tuff_defeated") \
					else "The island is real. The finals are here. So is everything else."),
			"state": (QState.COMPLETED if GameState.has_flag(&"boss_tuff_defeated") \
					else (QState.ACTIVE if GameState.visited_rooms.has("res://scenes/levels/vip_marina.tscn") \
					else QState.LOCKED)),
		},
		{
			"name": "OPEN HOUSE",
			"desc": "A mansion in the Hills has been streaming its own foyer for four years. It locked the door behind you.",
			"state": _boss_quest("res://scenes/levels/castle_interior.tscn", &"boss_castle_defeated"),
		},
		{
			"name": "NO COMMENT",
			"desc": "Brittney wants a word. The word is apparently 'fight'.",
			"state": _boss_quest("res://scenes/levels/brittney_estate.tscn", &"brittney_duel_done"),
		},
		{
			"name": "FLASH MOB",
			"desc": "The red carpet has opinions about who counts.",
			"state": _boss_quest("res://scenes/levels/celebrity_estates.tscn", &"boss_swarm_defeated"),
		},
		{
			"name": "STILL WATCHING?",
			"desc": "Something in the boardroom has been reviewing your numbers.",
			"state": _boss_quest("res://scenes/levels/boardroom.tscn", &"boss_netflicks_defeated"),
		},
		{
			"name": "THE LAST ROOM",
			"desc": ("The biggest room there is. Raves is on the marquee. Hear him out, finish what you started, and bring everything you understand." \
					if not GameState.has_flag(&"true_ending_unlocked") \
					else "One real laugh. Then another. Then everywhere."),
			"state": (QState.COMPLETED if GameState.has_flag(&"true_ending_unlocked") \
					else (QState.ACTIVE if GameState.has_flag(&"good_ending_unlocked") \
					else QState.LOCKED)),
		},
		{
			"name": "THE COUNCIL",
			"desc": "Three chairs above the third floor. They have never once disagreed.",
			"state": (QState.COMPLETED if GameState.has_flag(&"cult_key") \
					else (QState.ACTIVE if GameState.visited_rooms.has("res://scenes/levels/laughing_pyramid.tscn") \
					else QState.LOCKED)),
		},
		{
			"name": "THE SCREENING",
			"desc": "A special has been playing to an empty room for six years.",
			"state": _boss_quest("res://scenes/levels/screening_room.tscn", &"boss_special_defeated"),
		},
		{
			"name": "THE COST OF APPLAUSE",
			"desc": "Below the estates, the lights are off on purpose.",
			"state": (QState.COMPLETED if GameState.has_flag(&"dark_chapter_done") \
					else (QState.ACTIVE if GameState.visited_rooms.has("res://scenes/levels/special_estates.tscn") \
					else QState.LOCKED)),
		},
		{
			"name": "CHUCKLE YUCKS",
			"desc": ("You're contestant #88,214. The competition has... a lot of paperwork for a comedy show." \
					if GameState.has_flag(&"chuckle_yucks_signed") \
					else "Sign up. Win. Get rich. What could go wrong?"),
			"state": _chuckle_yucks(),
		},
	]


func _open_mic_dreams() -> QState:
	if GameState.has_flag(&"raves_quest_done"):
		return QState.COMPLETED
	if GameState.has_flag(&"raves_quest_given"):
		return QState.ACTIVE
	return QState.AVAILABLE


func _basement_problem() -> QState:
	if GameState.has_flag(&"boss_disgraced_defeated"):
		return QState.COMPLETED
	if GameState.visited_rooms.has("res://scenes/levels/open_mic_alley.tscn"):
		return QState.ACTIVE
	return QState.LOCKED


func _so_it_seems() -> QState:
	if GameState.has_flag(&"george_encounter_1"):
		return QState.ACTIVE  # this quest does not complete. Obviously.
	return QState.LOCKED


func _chuckle_yucks() -> QState:
	if GameState.has_flag(&"finale_seen"):
		return QState.ACTIVE
	return QState.LOCKED


func state_label(state: QState) -> String:
	match state:
		QState.LOCKED: return "???"
		QState.AVAILABLE: return "NEW"
		QState.ACTIVE: return "ACTIVE"
		QState.COMPLETED: return "DONE"
	return ""


func _boss_quest(region_scene: String, defeat_flag: StringName) -> QState:
	if GameState.has_flag(defeat_flag):
		return QState.COMPLETED
	if GameState.visited_rooms.has(region_scene):
		return QState.ACTIVE
	return QState.LOCKED


func _george_count() -> int:
	var count := 0
	for flag in GameState.flags:
		if String(flag).begins_with("george_"):
			count += 1
	return count
