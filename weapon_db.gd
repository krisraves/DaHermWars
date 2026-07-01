# dialogue_system.gd
# Autoload (CanvasLayer). Minimal dialogue presenter.
# Per UI_UX_BIBLE: large readable text, speaker name, advances quickly.
# Per DIALOGUE_BIBLE: lines are short and punchy - this UI is built
# for one-liners, not walls of text.
# Per GEORGE RULE: George's dialogue box looks exactly like everyone
# else's. No special effects. This system has no special cases.
#
# Pauses the tree while active. Advance: E / Space / J.

extends CanvasLayer

signal finished

var active: bool = false

var _entries: Array = []
var _index: int = 0
var _accept_after: int = 0

var _panel: ColorRect
var _name_label: Label
var _text_label: Label
var _hint_label: Label


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func start(entries: Array) -> void:
	# entries: Array of {"speaker": String, "text": String}
	if entries.is_empty():
		return
	_entries = entries
	_index = 0
	active = true
	get_tree().paused = true
	_panel.visible = true
	_show_current()


func start_simple(speaker: String, lines: Array) -> void:
	var entries: Array = []
	for line in lines:
		entries.append({"speaker": speaker, "text": line})
	start(entries)


func _show_current() -> void:
	var entry: Dictionary = _entries[_index]
	_name_label.text = entry.get("speaker", "")
	_text_label.text = entry.get("text", "")
	_accept_after = Time.get_ticks_msec() + 180  # debounce so one press = one line


func _input(event: InputEvent) -> void:
	if not active:
		return
	if Time.get_ticks_msec() < _accept_after:
		return
	if event.is_action_pressed("interact") \
			or event.is_action_pressed("jump") \
			or event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		_advance()


func _advance() -> void:
	_index += 1
	if _index >= _entries.size():
		_end()
	else:
		_show_current()


func _end() -> void:
	active = false
	_panel.visible = false
	get_tree().paused = false
	finished.emit()


# ------------------------------------------------------------------ ui

func _build_ui() -> void:
	_panel = ColorRect.new()
	_panel.visible = false
	_panel.color = Color(0.06, 0.05, 0.09, 0.92)
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -520.0
	_panel.offset_right = 520.0
	_panel.offset_top = -190.0
	_panel.offset_bottom = -30.0
	add_child(_panel)

	_name_label = Label.new()
	_name_label.position = Vector2(24, 12)
	_name_label.add_theme_font_size_override("font_size", 24)
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.15))
	_panel.add_child(_name_label)

	_text_label = Label.new()
	_text_label.position = Vector2(24, 52)
	_text_label.size = Vector2(992, 90)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", 26)
	_text_label.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88))
	_panel.add_child(_text_label)

	_hint_label = Label.new()
	_hint_label.text = "E ▸"
	_hint_label.position = Vector2(975, 125)
	_hint_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	_panel.add_child(_hint_label)
