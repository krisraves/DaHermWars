# debug_menu.gd  (AUTOLOAD: DebugMenu)
# QA TOOLKIT (SAVE_SYSTEM_SPEC: "Developer Build Only ... Never
# expose these in retail builds.")
#
# Hard-gated on OS.is_debug_build(): in an exported release build
# this autoload deletes itself before building any UI. In the
# editor / debug exports: F1 toggles the panel.
#
# Three columns:
#   ACTIONS  - give-all commands, heal, invincibility, followers
#   PRESETS  - one-click QA scenarios (the fast path to any ending)
#   WARP     - every room in the game
# Plus a live STATE readout (flags / fragments / relics / cheevos).

extends CanvasLayer

const ALL_WEAPONS := ["flame_glove", "folding_chair", "rubber_chicken", "pod_mic"]
const ALL_COSTUMES := ["street_comic", "trash_bag_tuxedo", "basketball_prophet",
	"thought_leader", "verified", "corporate_clean", "content_machine", "the_hack",
	"headliner_x", "illuminepstein_initiate", "red_carpet_elite", "the_former_winner"]
const ALL_RELICS := ["influence_relic", "sponsor_sigil", "discovery_module",
	"empathy_fragment", "brittneys_card", "stealth_upgrade", "streaming_pass",
	"follower_booster"]
const STORY_FLAGS: Array[StringName] = [&"finale_seen", &"chuckle_yucks_signed",
	&"heard_whisper", &"dark_chapter_done", &"theater_unlocked", &"cult_key",
	&"boss_tuff_defeated", &"good_ending_unlocked", &"raves_final_seen",
	&"raves_quest_given", &"raves_quest_done"]

# warp targets: label -> [scene path, spawn]
const WARPS := {
	"HOMELESS DISTRICT": ["res://scenes/levels/homeless_district.tscn", &"default"],
	"OPEN MIC ALLEY": ["res://scenes/levels/open_mic_alley.tscn", &"default"],
	"THE UNDERGROUND (boss)": ["res://scenes/levels/boss_arena.tscn", &"default"],
	"COURTSIDE KINGDOM": ["res://scenes/levels/courtside_kingdom.tscn", &"default"],
	"PODCAST WASTELAND": ["res://scenes/levels/podcast_wasteland.tscn", &"default"],
	"INFLUENCER HILLS": ["res://scenes/levels/influencer_hills.tscn", &"default"],
	"CONTENT CASTLE": ["res://scenes/levels/castle_interior.tscn", &"default"],
	"CORPORATE TOWER": ["res://scenes/levels/corporate_tower.tscn", &"default"],
	"STREAMING HQ": ["res://scenes/levels/streaming_hq.tscn", &"default"],
	"THE BOARDROOM": ["res://scenes/levels/boardroom.tscn", &"default"],
	"CELEBRITY ESTATES": ["res://scenes/levels/celebrity_estates.tscn", &"default"],
	"NUTTINGS ESTATE (duel)": ["res://scenes/levels/brittney_estate.tscn", &"default"],
	"SPECIAL ESTATES": ["res://scenes/levels/special_estates.tscn", &"default"],
	"BELOW THE ESTATES": ["res://scenes/levels/below_the_estates.tscn", &"default"],
	"WINNER'S MANOR": ["res://scenes/levels/former_winner_manor.tscn", &"default"],
	"COMEDY UNDERGROUND": ["res://scenes/levels/comedy_underground.tscn", &"default"],
	"SECRET CLUB": ["res://scenes/levels/secret_club.tscn", &"default"],
	"LOST THEATER": ["res://scenes/levels/lost_theater.tscn", &"default"],
	"VIP MARINA": ["res://scenes/levels/vip_marina.tscn", &"default"],
	"CONTENT COVE": ["res://scenes/levels/content_cove.tscn", &"default"],
	"LAUGHING PYRAMID": ["res://scenes/levels/laughing_pyramid.tscn", &"default"],
	"SCREENING ROOM": ["res://scenes/levels/screening_room.tscn", &"default"],
	"PYRAMID SUMMIT": ["res://scenes/levels/pyramid_summit.tscn", &"default"],
	"THE HEADLINER": ["res://scenes/levels/the_headliner.tscn", &"default"],
}

var _panel: PanelContainer
var _state_label: Label
var _toast_label: Label
var _open: bool = false
var _invincible: bool = false


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()  # SAVE_SYSTEM_SPEC: never in retail
		return
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_F1:
		_open = not _open
		_panel.visible = _open
		if _open:
			_refresh_state()


# ------------------------------------------------------------------ UI

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.position = Vector2(40, 40)
	_panel.custom_minimum_size = Vector2(1200, 620)
	add_child(_panel)

	var root := VBoxContainer.new()
	_panel.add_child(root)

	var title := Label.new()
	title.text = "QA TOOLKIT (F1) — debug builds only — nothing here is canon"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1, 0.7, 0.2))
	root.add_child(title)

	_toast_label = Label.new()
	_toast_label.text = ""
	_toast_label.add_theme_font_size_override("font_size", 13)
	_toast_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	root.add_child(_toast_label)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	root.add_child(columns)

	# --- ACTIONS
	var actions := VBoxContainer.new()
	columns.add_child(actions)
	_header(actions, "ACTIONS")
	_btn(actions, "GIVE ALL ABILITIES", _give_abilities)
	_btn(actions, "GIVE ALL WEAPONS", _give_weapons)
	_btn(actions, "GIVE ALL COSTUMES", _give_costumes)
	_btn(actions, "GIVE ALL RELICS", _give_relics)
	_btn(actions, "ALL GEORGES + FRAGMENTS", _give_george)
	_btn(actions, "+1000 FOLLOWERS", _give_followers)
	_btn(actions, "HEAL FULL", _heal)
	_btn(actions, "INVINCIBLE: OFF", _toggle_invincible)
	_btn(actions, "SET ALL STORY FLAGS", _give_story)
	_btn(actions, "AUTOSAVE NOW", SaveSystem.autosave)

	# --- PRESETS
	var presets := VBoxContainer.new()
	columns.add_child(presets)
	_header(presets, "QA PRESETS")
	_btn(presets, "FRESH SLICE END\n(post-finale, Alley)", _preset_slice)
	_btn(presets, "PRE-DARK CHAPTER\n(Special Estates)", _preset_dark)
	_btn(presets, "PRE-TUFF TIDDY\n(everything but the key)", _preset_tuff)
	_btn(presets, "TRUE-ENDING READY\n(Pyramid atrium, gate open)", _preset_true)

	# --- WARP
	var warp_scroll := ScrollContainer.new()
	warp_scroll.custom_minimum_size = Vector2(340, 520)
	columns.add_child(warp_scroll)
	var warps := VBoxContainer.new()
	warp_scroll.add_child(warps)
	_header(warps, "WARP")
	for label: String in WARPS.keys():
		_btn(warps, label, _warp.bind(label))

	# --- STATE readout
	var state_scroll := ScrollContainer.new()
	state_scroll.custom_minimum_size = Vector2(300, 520)
	columns.add_child(state_scroll)
	_state_label = Label.new()
	_state_label.add_theme_font_size_override("font_size", 12)
	_state_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_state_label.custom_minimum_size = Vector2(280, 0)
	state_scroll.add_child(_state_label)


func _header(parent: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(1, 0.7, 0.2))
	parent.add_child(label)


func _btn(parent: Control, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	button.pressed.connect(_refresh_state)
	parent.add_child(button)


# ------------------------------------------------------------------ actions

func _give_abilities() -> void:
	GameState.has_flame_dash = true
	GameState.has_double_jump = true
	GameState.has_infernal_mastery = true
	_toast("abilities set (re-enter room or warp to sync the player)")


func _give_weapons() -> void:
	for id in ALL_WEAPONS:
		GameState.grant_weapon(StringName(id))
	_toast("all weapons")


func _give_costumes() -> void:
	for id in ALL_COSTUMES:
		GameState.grant_costume(StringName(id))
	_toast("all costumes")


func _give_relics() -> void:
	for id in ALL_RELICS:
		GameState.grant_relic(StringName(id))
	_toast("all relics")


func _give_george() -> void:
	for flag in GameState.GEORGE_FLAGS:
		GameState.set_flag(flag)
	GameState.perfect_joke_fragments = GameState.FRAGMENTS_REQUIRED
	_toast("all Georges met, all fragments held")


func _give_followers() -> void:
	GameState.add_followers(1000)
	_toast("+1000 followers (pre-multiplier)")


func _give_story() -> void:
	for flag in STORY_FLAGS:
		GameState.set_flag(flag)
	_toast("all story flags set")


func _heal() -> void:
	for p in get_tree().get_nodes_in_group("player"):
		p.health.heal_full()
	_toast("healed")


func _toggle_invincible() -> void:
	_invincible = not _invincible
	for p in get_tree().get_nodes_in_group("player"):
		p.health.invulnerable = _invincible
	# rename the button in place
	for col in _panel.get_child(0).get_child(1).get_children():
		if col is VBoxContainer:
			for child in col.get_children():
				if child is Button and child.text.begins_with("INVINCIBLE"):
					child.text = "INVINCIBLE: %s" % ("ON" if _invincible else "OFF")
	_toast("invincible: %s (re-applies on warp via this menu only)" % _invincible)


# ------------------------------------------------------------------ presets

func _preset_slice() -> void:
	GameState.set_flag(&"finale_seen")
	GameState.set_flag(&"boss_disgraced_defeated")
	GameState.has_flame_dash = true
	GameState.add_followers(200)
	_warp_to("res://scenes/levels/open_mic_alley.tscn")


func _preset_dark() -> void:
	_preset_slice_state()
	GameState.set_flag(&"heard_whisper")
	_warp_to("res://scenes/levels/special_estates.tscn")


func _preset_tuff() -> void:
	_preset_slice_state()
	GameState.set_flag(&"heard_whisper")
	GameState.set_flag(&"dark_chapter_done")
	GameState.set_flag(&"cult_key")
	_give_weapons()
	_give_abilities()
	_warp_to("res://scenes/levels/pyramid_summit.tscn")


func _preset_true() -> void:
	_preset_slice_state()
	for flag in STORY_FLAGS:
		GameState.set_flag(flag)
	_give_abilities()
	_give_weapons()
	_give_relics()
	_give_george()
	_warp_to("res://scenes/levels/laughing_pyramid.tscn")


func _preset_slice_state() -> void:
	GameState.set_flag(&"finale_seen")
	GameState.set_flag(&"chuckle_yucks_signed")
	GameState.set_flag(&"boss_disgraced_defeated")
	GameState.has_flame_dash = true
	GameState.has_double_jump = true
	if GameState.followers < 500:
		GameState.add_followers(500)


# ------------------------------------------------------------------ misc

func _warp(label: String) -> void:
	var target: Array = WARPS[label]
	_close()
	GameState.change_room(target[0], target[1])


func _warp_to(scene: String) -> void:
	_close()
	GameState.change_room(scene, &"default")


func _close() -> void:
	_open = false
	_panel.visible = false


func _toast(text: String) -> void:
	_toast_label.text = "> " + text


func _refresh_state() -> void:
	if _state_label == null:
		return
	var flags := []
	for flag in GameState.flags.keys():
		flags.append(String(flag))
	flags.sort()
	_state_label.text = "STATE\nfollowers: %d\nfragments: %d / %d\nrelics: %s\ncostume: %s\nweapon: %s\nachievements: %d\ntrue-ending missing:\n  %s\n\nflags (%d):\n%s" % [
		GameState.followers,
		GameState.perfect_joke_fragments, GameState.FRAGMENTS_REQUIRED,
		", ".join(GameState.relics) if not GameState.relics.is_empty() else "(none)",
		GameState.costume, GameState.equipped_weapon,
		GameState.achievements.size(),
		"\n  ".join(GameState.true_ending_missing()) if not GameState.true_ending_ready() else "(READY)",
		flags.size(), "\n".join(flags)]
