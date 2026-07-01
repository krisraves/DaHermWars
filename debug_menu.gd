# save_system.gd
# Autoload. Disk persistence per SAVE_SYSTEM_SPEC:
# - JSON format, 3 manual slots + 1 autosave slot
# - Every file stores save_version; loads validate + repair
# - Autosave on: first region visit, boss defeat, ability unlock
# - Never autosaves during dialogue (spec: never during cutscenes)
# - The Perfect Joke is never in any file. Only the fragment count.
#
# North star (spec): "The player should trust the save system
# completely."

extends Node

const SAVE_DIR := "user://saves/"
const SAVE_VERSION := 1
const SLOTS := ["slot_1", "slot_2", "slot_3", "auto"]


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


# ------------------------------------------------------------------ write

func save_to(slot: String) -> bool:
	var data := GameState.to_dict()
	data["saved_at_unix"] = int(Time.get_unix_time_from_system())
	var file := FileAccess.open(_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: cannot open %s for writing" % _path(slot))
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


func save_active() -> bool:
	return save_to(GameState.active_slot)


func autosave() -> void:
	if DialogueSystem.active:
		return  # spec: never during dialogue/cutscenes
	save_to("auto")


# ------------------------------------------------------------------ read

func slot_exists(slot: String) -> bool:
	return FileAccess.file_exists(_path(slot))


func read_slot(slot: String) -> Dictionary:
	if not slot_exists(slot):
		return {}
	var file := FileAccess.open(_path(slot), FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		push_warning("SaveSystem: %s is corrupt" % slot)
		return {}
	return _validate(parsed)


func load_slot(slot: String) -> bool:
	var data := read_slot(slot)
	if data.is_empty():
		return false
	GameState.from_dict(data)
	GameState.active_slot = slot if slot != "auto" else "slot_1"
	GameState.in_game = true
	GameState.change_room(GameState.respawn_room, GameState.respawn_spawn)
	return true


func slot_summary(slot: String) -> String:
	var data := read_slot(slot)
	if data.is_empty():
		return "— EMPTY —"
	var minutes := int(data.get("play_time", 0.0)) / 60
	return "%d followers · %d:%02d · %s" % [
		int(data.get("followers", 0)), minutes / 60, minutes % 60,
		_room_display(data.get("respawn_room", "")),
	]


func most_recent_slot() -> String:
	var best := ""
	var best_time := -1
	for slot in SLOTS:
		var data := read_slot(slot)
		if data.is_empty():
			continue
		var t := int(data.get("saved_at_unix", 0))
		if t > best_time:
			best_time = t
			best = slot
	return best


# ------------------------------------------------------------------ internals

func _validate(data: Dictionary) -> Dictionary:
	# Version gate + field repair (spec: "Repair missing values").
	var version := int(data.get("save_version", 0))
	if version > SAVE_VERSION:
		push_warning("SaveSystem: save from a newer version; loading best-effort")
	# from_dict() supplies defaults for anything missing, so validation
	# here only needs to reject non-dict payloads (done by caller) and
	# obviously broken respawn rooms:
	var room: String = data.get("respawn_room", "")
	if room == "" or not ResourceLoader.exists(room):
		data["respawn_room"] = "res://scenes/levels/homeless_district.tscn"
		data["respawn_spawn"] = "default"
	return data


func _path(slot: String) -> String:
	return SAVE_DIR + slot + ".json"


func _room_display(path: String) -> String:
	return path.get_file().get_basename().capitalize()
