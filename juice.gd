# achievements.gd  (AUTOLOAD: Achievements)
# ACHIEVEMENTS.md: "Achievements should feel like jokes, memories,
# and discoveries. Not chores."
#
# Lightweight polling design: every second, check definitions
# against GameState; unlock -> banner + persist. No signal surgery
# across twelve systems; fourteen cheap checks at 1Hz.

extends Node

# [id, title, sub-line, check]
var _defs: Array = []
var _first_poll: bool = true


func _ready() -> void:
	_defs = [
		["a_new_dahope", "A NEW DA'HOPE", "Complete the prologue.",
			func(): return GameState.has_flag(&"finale_seen")],
		["chuckle_yucks", "CHUCKLE YUCKS", "Sign the application. Skim Clause 13.",
			func(): return GameState.has_flag(&"chuckle_yucks_signed")],
		["the_machine", "THE MACHINE", "Hear the whisper.",
			func(): return GameState.has_flag(&"heard_whisper")],
		["cost_of_applause", "THE COST OF APPLAUSE", "See what it runs on.",
			func(): return GameState.has_flag(&"dark_chapter_done")],
		["headliner", "HEADLINER", "Defeat Tuff Tiddy.",
			func(): return GameState.has_flag(&"boss_tuff_defeated")],
		["laughter_protected", "LAUGHTER IS WORTH PROTECTING", "The True Ending.",
			func(): return GameState.has_flag(&"true_ending_unlocked")],
		["so_it_seems", "SO IT SEEMS", "Meet George once.",
			func(): return _george_count() >= 1],
		["hes_everywhere", "HE'S EVERYWHERE", "Meet George ten times.",
			func(): return _george_count() >= 10],
		["are_you_seeing_this", "ARE YOU SEEING THIS?", "Find every George encounter.",
			func(): return _george_count() >= GameState.GEORGE_FLAGS.size()],
		["trust_me", "TRUST ME", "Complete your first Raves quest.",
			func(): return GameState.has_flag(&"raves_quest_done")],
		["that_could_have_been_me", "THAT COULD HAVE BEEN ME", "Defeat Ravager Prime.",
			func(): return GameState.has_flag(&"boss_ravager_defeated")],
		["fashion_icon", "FASHION ICON", "Unlock ten costumes.",
			func(): return GameState.costumes_owned.size() >= 10],
		["content_creator", "CONTENT CREATOR", "Acquire the Pod Mic.",
			func(): return GameState.weapons_owned.has("pod_mic")],
		["perfect_joke", "THE PERFECT JOKE", "Assemble all fragments.",
			func(): return GameState.has_flag(&"perfect_joke_assembled")],
		["probably_nothing", "PROBABLY NOTHING", "It's probably nothing.",
			func(): return GameState.has_flag(&"george_encounter_1")],
		["no_comment", "NO COMMENT", "Win a fight nobody loses.",
			func(): return GameState.has_flag(&"brittney_duel_done")],
		["made_it", "MADE IT", "Join the system.",
			func(): return GameState.has_flag(&"bad_ending_unlocked")],
		["special_boy", "SPECIAL BOY", "Receive the comedy special.",
			func(): return GameState.has_flag(&"special_received")],
	]
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_poll)
	add_child(timer)


func _poll() -> void:
	for def: Array in _defs:
		if GameState.achievements.has(def[0]):
			continue
		var check: Callable = def[3]
		if check.call():
			_unlock(def, not _first_poll)
	_first_poll = false


func _unlock(def: Array, with_banner: bool = true) -> void:
	GameState.achievements.append(def[0])
	if not with_banner:
		return  # first poll after load: persist quietly, no burst
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("ACHIEVEMENT — %s\n%s" % [def[1], def[2]])


func _george_count() -> int:
	var count := 0
	for flag in GameState.GEORGE_FLAGS:
		if GameState.has_flag(flag):
			count += 1
	return count
