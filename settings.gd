# title_screen.gd
# Title screen (UI_UX_BIBLE): Continue · New Game · Load · Quit.
# "Comedy flyer meets PS1 RPG" - bold type, high contrast.

extends Control

var _menu: VBoxContainer


func _ready() -> void:
	GameState.in_game = false
	get_tree().paused = false
	_build()


func _build() -> void:
	var background := ColorRect.new()
	background.color = Color(0.07, 0.05, 0.1)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var neon := ColorRect.new()
	neon.color = Color(1, 0.25, 0.6, 0.12)
	neon.position = Vector2(0, 110)
	neon.size = Vector2(1280, 180)
	add_child(neon)

	var title := Label.new()
	title.text = "DA'HERM WARS EPISODE X"
	title.position = Vector2(0, 120)
	title.size = Vector2(1280, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1, 0.7, 0.15))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 10)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "A  N E W  D A ' H O P E"
	subtitle.position = Vector2(0, 195)
	subtitle.size = Vector2(1280, 40)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 26)
	subtitle.add_theme_color_override("font_color", Color(1, 0.3, 0.6))
	add_child(subtitle)

	var tagline := Label.new()
	tagline.text = "\"Everybody starts somewhere.\""
	tagline.position = Vector2(0, 640)
	tagline.size = Vector2(1280, 30)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_color_override("font_color", Color(0.55, 0.52, 0.55))
	add_child(tagline)

	_menu = VBoxContainer.new()
	_menu.position = Vector2(490, 300)
	_menu.size = Vector2(300, 300)
	_menu.add_theme_constant_override("separation", 14)
	add_child(_menu)
	_show_main_menu()


func _show_main_menu() -> void:
	_clear_menu()
	if SaveSystem.most_recent_slot() != "":
		_menu_button("CONTINUE", _continue_game)
	_menu_button("NEW GAME", _new_game)
	_menu_button("LOAD GAME", _show_load_menu)
	_menu_button("CREDITS", func(): get_tree().change_scene_to_file("res://scenes/levels/credits.tscn"))
	_menu_button("QUIT", func(): get_tree().quit())


func _show_load_menu() -> void:
	_clear_menu()
	for slot in SaveSystem.SLOTS:
		var label := "%s  ·  %s" % [slot.to_upper().replace("_", " "), SaveSystem.slot_summary(slot)]
		if SaveSystem.slot_exists(slot):
			_menu_button(label, _load_slot.bind(slot))
		else:
			_menu_label(label)
	_menu_button("← BACK", _show_main_menu)


func _continue_game() -> void:
	SaveSystem.load_slot(SaveSystem.most_recent_slot())


func _load_slot(slot: String) -> void:
	SaveSystem.load_slot(slot)


func _new_game() -> void:
	GameState.reset()
	# first empty manual slot, else slot_1
	GameState.active_slot = "slot_1"
	for slot in ["slot_1", "slot_2", "slot_3"]:
		if not SaveSystem.slot_exists(slot):
			GameState.active_slot = slot
			break
	GameState.in_game = true
	GameState.change_room("res://scenes/levels/homeless_district.tscn")


# ------------------------------------------------------------------ helpers

func _clear_menu() -> void:
	for child in _menu.get_children():
		child.queue_free()


func _menu_button(text: String, on_pressed: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(on_pressed)
	_menu.add_child(button)


func _menu_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
	_menu.add_child(label)
