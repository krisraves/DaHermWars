# game_state.gd
# Autoload. Single source of truth for all progression, now fully
# serializable (SAVE_SYSTEM_SPEC). SaveSystem turns this into JSON.
#
# Canon rules enforced here:
# - Followers ACCUMULATED, never spent (01_GAME_DESIGN_BIBLE)
# - Fragments are a COUNT; the joke itself is never stored
# - Alignment is tracked, never judged (COMEDY_ALIGNMENT_SYSTEM:
#   "The game critiques methods. Not people.")

extends Node

signal followers_changed(total: int)
signal flag_set(flag: StringName)
signal loadout_changed

# ---- progression ----------------------------------------------------
var followers: int = 0
var has_flame_dash: bool = false
var has_double_jump: bool = false
var has_infernal_mastery: bool = false  # Flame Glove tier 8 (07_ABILITIES)
var perfect_joke_fragments: int = 0

# ---- inventory --------------------------------------------------------
var costume: StringName = &"street_comic"
var costumes_owned: Array = ["street_comic"]
var equipped_weapon: StringName = &"flame_glove"
var weapons_owned: Array = ["flame_glove"]
var burritos: int = 1
var relics: Array = []  # Gas Station Burrito (ITEM_DATABASE: cheap healing)

# ---- comedy alignment (seed) -------------------------------------------
var alignment: Dictionary = {
	"observational": 0, "crowd_work": 0, "shock": 0, "hack": 0, "industry": 0,
}

# ---- story flags ----------------------------------------------------------
var flags: Dictionary = {}
var achievements: Array = []  # unlocked achievement ids (ACHIEVEMENTS.md)

# ---- world knowledge --------------------------------------------------------
var visited_rooms: Array = []
var circuit_nodes: Array = []  # [{name, scene, spawn}]

# ---- carry-over player state -------------------------------------------------
var health: int = 100
var max_health: int = 100
var heat: float = 0.0

# ---- position / meta ------------------------------------------------------------
var current_room: String = ""
var pending_spawn: StringName = &"default"
var respawn_room: String = "res://scenes/levels/homeless_district.tscn"
var respawn_spawn: StringName = &"default"
var play_time: float = 0.0
var active_slot: String = "slot_1"
var in_game: bool = false


func _process(delta: float) -> void:
	if in_game and not get_tree().paused:
		play_time += delta


# ------------------------------------------------------------------ progression

func add_followers(amount: int) -> void:
	var gained := amount
	if costume == &"trash_bag_tuxedo":
		gained = int(ceil(amount * 1.1))
	if costume == &"red_carpet_elite":
		gained = int(ceil(amount * 1.2))
	if relics.has("influence_relic"):
		gained = int(ceil(gained * 1.25))
	if relics.has("brittneys_card"):
		gained = int(ceil(gained * 1.15))  # people take her name seriously
	if relics.has("follower_booster"):
		gained = int(ceil(gained * 1.25))  # the Castle's growth strategy
	followers += gained
	followers_changed.emit(followers)


func set_flag(flag: StringName) -> void:
	flags[flag] = true
	flag_set.emit(flag)


func has_flag(flag: StringName) -> bool:
	return flags.get(flag, false)


func add_fragment() -> void:
	perfect_joke_fragments += 1


func add_alignment(track: String, points: int = 1) -> void:
	if alignment.has(track):
		alignment[track] += points


# ------------------------------------------------------------------ inventory

func grant_relic(id: StringName) -> void:
	if not relics.has(String(id)):
		relics.append(String(id))


func has_relic(id: StringName) -> bool:
	return relics.has(String(id))


func grant_weapon(id: StringName) -> void:
	if not weapons_owned.has(String(id)):
		weapons_owned.append(String(id))
	loadout_changed.emit()


func grant_costume(id: StringName) -> void:
	if not costumes_owned.has(String(id)):
		costumes_owned.append(String(id))
	loadout_changed.emit()


func equip_weapon(id: StringName) -> void:
	if weapons_owned.has(String(id)):
		equipped_weapon = id
		loadout_changed.emit()


func equip_costume(id: StringName) -> void:
	if costumes_owned.has(String(id)):
		costume = id
		loadout_changed.emit()
		for p in get_tree().get_nodes_in_group("player"):
			p.apply_costume()


func use_burrito() -> bool:
	if burritos <= 0:
		return false
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return false
	var player = players[0]
	if player.health.current >= player.health.max_health:
		return false
	burritos -= 1
	player.health.heal(40)
	health = player.health.current
	player.health_changed.emit(player.health.current, player.health.max_health)
	return true


# ------------------------------------------------------------------ world

func mark_room_visited(scene_path: String) -> bool:
	# returns true on FIRST visit (autosave trigger)
	if visited_rooms.has(scene_path):
		return false
	visited_rooms.append(scene_path)
	return true


func register_circuit_node(node_name: String, scene: String, spawn: StringName) -> void:
	for node in circuit_nodes:
		if node["scene"] == scene:
			return
	circuit_nodes.append({"name": node_name, "scene": scene, "spawn": String(spawn)})


func set_respawn(room: String, spawn: StringName) -> void:
	respawn_room = room
	respawn_spawn = spawn


func change_room(scene_path: String, spawn: StringName = &"default") -> void:
	pending_spawn = spawn
	get_tree().call_deferred("change_scene_to_file", scene_path)


func consume_pending_spawn() -> StringName:
	var s := pending_spawn
	pending_spawn = &"default"
	return s


# ------------------------------------------------------------------ save plumbing

func reset() -> void:
	followers = 0
	has_flame_dash = false
	has_double_jump = false
	has_infernal_mastery = false
	perfect_joke_fragments = 0
	achievements = []
	costume = &"street_comic"
	costumes_owned = ["street_comic"]
	equipped_weapon = &"flame_glove"
	weapons_owned = ["flame_glove"]
	burritos = 1
	relics = []
	alignment = {"observational": 0, "crowd_work": 0, "shock": 0, "hack": 0, "industry": 0}
	flags = {}
	visited_rooms = []
	circuit_nodes = []
	health = 100
	max_health = 100
	heat = 0.0
	current_room = ""
	pending_spawn = &"default"
	respawn_room = "res://scenes/levels/homeless_district.tscn"
	respawn_spawn = &"default"
	play_time = 0.0


func to_dict() -> Dictionary:
	return {
		"save_version": 1,
		"play_time": play_time,
		"followers": followers,
		"has_flame_dash": has_flame_dash,
		"has_double_jump": has_double_jump,
		"has_infernal_mastery": has_infernal_mastery,
		"achievements": achievements,
		"perfect_joke_fragments": perfect_joke_fragments,  # count ONLY
		"costume": String(costume),
		"costumes_owned": costumes_owned,
		"equipped_weapon": String(equipped_weapon),
		"weapons_owned": weapons_owned,
		"burritos": burritos,
		"relics": relics,
		"alignment": alignment,
		"flags": flags,
		"visited_rooms": visited_rooms,
		"circuit_nodes": circuit_nodes,
		"health": health,
		"max_health": max_health,
		"heat": heat,
		"respawn_room": respawn_room,
		"respawn_spawn": String(respawn_spawn),
	}


func from_dict(data: Dictionary) -> void:
	reset()
	play_time = data.get("play_time", 0.0)
	followers = int(data.get("followers", 0))
	has_flame_dash = data.get("has_flame_dash", false)
	has_infernal_mastery = data.get("has_infernal_mastery", false)
	achievements = data.get("achievements", [])
	has_double_jump = data.get("has_double_jump", false)
	perfect_joke_fragments = int(data.get("perfect_joke_fragments", 0))
	costume = StringName(data.get("costume", "street_comic"))
	costumes_owned = data.get("costumes_owned", ["street_comic"])
	equipped_weapon = StringName(data.get("equipped_weapon", "flame_glove"))
	weapons_owned = data.get("weapons_owned", ["flame_glove"])
	burritos = int(data.get("burritos", 0))
	relics = data.get("relics", [])
	alignment = data.get("alignment", alignment)
	flags = data.get("flags", {})
	visited_rooms = data.get("visited_rooms", [])
	circuit_nodes = data.get("circuit_nodes", [])
	health = int(data.get("health", 100))
	max_health = int(data.get("max_health", 100))
	heat = float(data.get("heat", 0.0))
	respawn_room = data.get("respawn_room", respawn_room)
	respawn_spawn = StringName(data.get("respawn_spawn", "default"))
	followers_changed.emit(followers)


# ------------------------------------------------------- THE TRUE ENDING
# (03_STORY_BIBLE) Requirements: every George encounter, every Perfect
# Joke fragment, the Empathy Fragment, Infernal Mastery, the Good
# Ending behind you, and Raves' answer heard. RULE 12: the fragments
# are a COUNT. The Joke itself is never written down. Not even here.

const GEORGE_FLAGS: Array[StringName] = [
	&"george_encounter_1", &"george_courtside", &"george_wasteland",
	&"george_hills", &"george_tower", &"george_hq", &"george_below",
	&"george_underground", &"george_theater", &"george_marina",
	&"george_cove", &"george_pyramid", &"george_celebrity",
]
const FRAGMENTS_REQUIRED: int = 16


func true_ending_missing() -> Array[String]:
	var missing: Array[String] = []
	var georges := 0
	for flag in GEORGE_FLAGS:
		if has_flag(flag):
			georges += 1
	if georges < GEORGE_FLAGS.size():
		missing.append("A man you haven't met yet. (%d of %d)" % [georges, GEORGE_FLAGS.size()])
	if perfect_joke_fragments < FRAGMENTS_REQUIRED:
		missing.append("Pieces of something you don't understand yet. (%d of %d)" % [perfect_joke_fragments, FRAGMENTS_REQUIRED])
	if not has_relic(&"empathy_fragment"):
		missing.append("A room you haven't won over. (the small one. underground.)")
	if not has_infernal_mastery:
		missing.append("A fire you haven't finished learning.")
	if not has_flag(&"good_ending_unlocked"):
		missing.append("A summit you haven't reached.")
	if not has_flag(&"raves_final_seen"):
		missing.append("A friend you haven't heard out.")
	return missing


func true_ending_ready() -> bool:
	return true_ending_missing().is_empty()
