# pause_menu.gd
# Autoload (CanvasLayer). The pause menu, per UI_UX_BIBLE:
# tabs, opens fast, readable, stays out of the way.
# Tabs: STATUS · GEAR (weapons/costumes/items) · QUESTS · MAP · SYSTEM
# Toggle: ESC / P / Start. Q/E or click to switch tabs.

extends CanvasLayer

const TABS := ["STATUS", "GEAR", "QUESTS", "MAP", "SYSTEM"]

# map screen layout: scene path -> [grid pos, display name, color key]
const MAP_LAYOUT := {
	"res://scenes/levels/homeless_district.tscn": [Vector2(0, 1), "HOMELESS DISTRICT"],
	"res://scenes/levels/open_mic_alley.tscn": [Vector2(1, 1), "OPEN MIC ALLEY"],
	"res://scenes/levels/boss_arena.tscn": [Vector2(1, 2), "THE UNDERGROUND"],
	"res://scenes/levels/courtside_kingdom.tscn": [Vector2(-1, 1), "COURTSIDE KINGDOM"],
	"res://scenes/levels/podcast_wasteland.tscn": [Vector2(-2, 1), "PODCAST WASTELAND"],
	"res://scenes/levels/influencer_hills.tscn": [Vector2(-1, 0), "INFLUENCER HILLS"],
	"res://scenes/levels/corporate_tower.tscn": [Vector2(2, 0), "CORPORATE MEDIA TOWER"],
	"res://scenes/levels/streaming_hq.tscn": [Vector2(2, -1), "STREAMING HQ"],
	"res://scenes/levels/special_estates.tscn": [Vector2(-2, 0), "SPECIAL ESTATES"],
	"res://scenes/levels/below_the_estates.tscn": [Vector2(-2, 1), "BELOW"],
	"res://scenes/levels/comedy_underground.tscn": [Vector2(1, 3), "COMEDY UNDERGROUND"],
	"res://scenes/levels/lost_theater.tscn": [Vector2(2, 3), "LOST THEATER"],
	"res://scenes/levels/former_winner_manor.tscn": [Vector2(-3, 0), "WINNER'S ESTATE"],
	"res://scenes/levels/secret_club.tscn": [Vector2(1, 4), "???"],
	"res://scenes/levels/vip_marina.tscn": [Vector2(-3, -1), "VIP MARINA"],
	"res://scenes/levels/content_cove.tscn": [Vector2(-3, -2), "CONTENT COVE"],
	"res://scenes/levels/laughing_pyramid.tscn": [Vector2(-3, -3), "LAUGHING PYRAMID"],
	"res://scenes/levels/screening_room.tscn": [Vector2(-2, -3), "SCREENING ROOM"],
	"res://scenes/levels/pyramid_summit.tscn": [Vector2(-3, -4), "THE SUMMIT"],
	"res://scenes/levels/the_headliner.tscn": [Vector2(-2, -4), "THE HEADLINER"],
	"res://scenes/levels/celebrity_estates.tscn": [Vector2(0, -2), "CELEBRITY ESTATES"],
	"res://scenes/levels/brittney_estate.tscn": [Vector2(1, -2), "NUTTINGS ESTATE"],
	"res://scenes/levels/boardroom.tscn": [Vector2(-1, -3), "THE BOARDROOM"],
	"res://scenes/levels/castle_interior.tscn": [Vector2(0, -1), "CONTENT CASTLE"],
}

var is_open: bool = false
var _tab: int = 0

var _root: ColorRect
var _tab_buttons: Array = []
var _content: VBoxContainer


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and GameState.in_game \
			and not DialogueSystem.active \
			and (is_open or not get_tree().paused):
		toggle()
		get_viewport().set_input_as_handled()
	elif is_open and event.is_action_pressed("move_left"):
		_set_tab((_tab - 1 + TABS.size()) % TABS.size())
	elif is_open and event.is_action_pressed("move_right"):
		_set_tab((_tab + 1) % TABS.size())


func toggle() -> void:
	is_open = not is_open
	_root.visible = is_open
	get_tree().paused = is_open
	if is_open:
		_set_tab(_tab)


func close() -> void:
	if is_open:
		toggle()


# ------------------------------------------------------------------ tabs

func _set_tab(index: int) -> void:
	_tab = index
	for i in _tab_buttons.size():
		_tab_buttons[i].modulate = Color(1, 0.7, 0.2) if i == _tab else Color(0.6, 0.6, 0.65)
	for child in _content.get_children():
		child.queue_free()
	match TABS[_tab]:
		"STATUS": _fill_status()
		"GEAR": _fill_gear()
		"QUESTS": _fill_quests()
		"MAP": _fill_map()
		"SYSTEM": _fill_system()


func _fill_status() -> void:
	_line("DA'HERM — STREET COMIC", Color(1, 0.7, 0.2))
	_line("Health  %d / %d" % [GameState.health, GameState.max_health])
	_line("Heat  %d / 100" % int(GameState.heat))
	_line("Followers  %d" % GameState.followers)
	_line("???  %d  (probably nothing)" % GameState.perfect_joke_fragments)
	_line("")
	_line("COMEDY ALIGNMENT", Color(1, 0.7, 0.2))
	for track in GameState.alignment:
		_line("  %s  %d" % [track.capitalize(), GameState.alignment[track]])
	if not GameState.relics.is_empty():
		_line("")
		_line("RELICS", Color(1, 0.7, 0.2))
		for relic in GameState.relics:
			_line("  " + String(relic).replace("_", " ").to_upper())
	var minutes := int(GameState.play_time) / 60
	_line("")
	_line("Play time  %d:%02d" % [minutes / 60, minutes % 60], Color(0.6, 0.6, 0.65))


func _fill_gear() -> void:
	_line("WEAPONS", Color(1, 0.7, 0.2))
	for id in GameState.weapons_owned:
		var weapon := WeaponDB.get_weapon(StringName(id))
		var equipped := StringName(id) == GameState.equipped_weapon
		_button("%s %s — %s" % ["▶" if equipped else "  ", weapon["name"], weapon["desc"]],
			_equip_weapon.bind(StringName(id)))
	_line("")
	_line("COSTUMES", Color(1, 0.7, 0.2))
	for id in GameState.costumes_owned:
		var equipped := StringName(id) == GameState.costume
		_button("%s %s" % ["▶" if equipped else "  ", id.capitalize()],
			_equip_costume.bind(StringName(id)))
	_line("")
	_line("ITEMS", Color(1, 0.7, 0.2))
	_button("  GAS STATION BURRITO ×%d — heal 40. Probably chicken." % GameState.burritos,
		_eat_burrito)


func _fill_quests() -> void:
	_line("QUEST LOG", Color(1, 0.7, 0.2))
	for quest in QuestDB.get_quests():
		if quest["state"] == QuestDB.QState.LOCKED:
			continue
		_line("[%s] %s" % [QuestDB.state_label(quest["state"]), quest["name"]],
			Color(0.5, 0.9, 0.5) if quest["state"] == QuestDB.QState.COMPLETED else Color(0.95, 0.9, 0.8))
		_line("    %s" % quest["desc"], Color(0.65, 0.62, 0.6))


func _fill_map() -> void:
	_line("OUT EAST — KNOWN AREAS", Color(1, 0.7, 0.2))
	_line("(blue: explored · gold: you are here)", Color(0.6, 0.6, 0.65))
	for path in MAP_LAYOUT:
		if not GameState.visited_rooms.has(path):
			continue
		var here := path == GameState.current_room
		_line("%s %s" % ["◆" if here else "■", MAP_LAYOUT[path][1]],
			Color(1, 0.75, 0.2) if here else Color(0.35, 0.6, 0.95))
	_line("")
	_line("COMEDY CIRCUIT NODES: %d" % GameState.circuit_nodes.size(), Color(0.6, 0.6, 0.65))


func _fill_system() -> void:
	_line("SYSTEM", Color(1, 0.7, 0.2))
	_button("  SAVE GAME (%s)" % GameState.active_slot.to_upper(), _save_now)
	_button("  QUIT TO TITLE", _quit_to_title)
	_button("  CLOSE MENU", close)
	_line("")
	_line("COMFORT", Color(1, 0.7, 0.2))
	_button("  SCREEN SHAKE: %s" % ("ON" if Settings.screen_shake else "OFF"),
			_toggle_setting.bind(&"screen_shake"))
	_button("  HIT PAUSE: %s" % ("ON" if Settings.hit_pause else "OFF"),
			_toggle_setting.bind(&"hit_pause"))
	_button("  REDUCED FLASH: %s" % ("ON" if Settings.reduced_flash else "OFF"),
			_toggle_setting.bind(&"reduced_flash"))
	_line("")
	_line("Saves live at the Comedy Club too —\nperforming a set saves your run.", Color(0.6, 0.6, 0.65))


# ------------------------------------------------------------------ actions

func _toggle_setting(setting: StringName) -> void:
	Settings.toggle(setting)
	_set_tab(_tab)


func _equip_weapon(id: StringName) -> void:
	GameState.equip_weapon(id)
	_set_tab(_tab)


func _equip_costume(id: StringName) -> void:
	GameState.equip_costume(id)
	_set_tab(_tab)


func _eat_burrito() -> void:
	if GameState.use_burrito():
		Juice.shake(2.0)
	_set_tab(_tab)


func _save_now() -> void:
	if SaveSystem.save_active():
		_line("Saved.", Color(0.5, 0.9, 0.5))


func _quit_to_title() -> void:
	close()
	GameState.in_game = false
	SaveSystem.autosave()
	GameState.change_room("res://scenes/levels/title_screen.tscn")


# ------------------------------------------------------------------ ui builders

func _build_ui() -> void:
	_root = ColorRect.new()
	_root.visible = false
	_root.color = Color(0.05, 0.04, 0.08, 0.96)
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var title := Label.new()
	title.text = "PAUSED — DA'HERM WARS EP. X"
	title.position = Vector2(60, 30)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 0.7, 0.2))
	_root.add_child(title)

	var tab_row := HBoxContainer.new()
	tab_row.position = Vector2(60, 90)
	tab_row.add_theme_constant_override("separation", 26)
	_root.add_child(tab_row)
	for i in TABS.size():
		var button := Button.new()
		button.text = TABS[i]
		button.flat = true
		button.add_theme_font_size_override("font_size", 22)
		button.pressed.connect(_set_tab.bind(i))
		tab_row.add_child(button)
		_tab_buttons.append(button)

	var hint := Label.new()
	hint.text = "A/D: switch tab · ESC: resume"
	hint.position = Vector2(60, 660)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	_root.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(60, 140)
	scroll.size = Vector2(1160, 500)
	_root.add_child(scroll)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 8)
	scroll.add_child(_content)


func _line(text: String, color: Color = Color(0.92, 0.9, 0.86)) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	_content.add_child(label)


func _button(text: String, on_pressed: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(on_pressed)
	_content.add_child(button)
