# ending_bad.gd
# THE BAD ENDING. He gets everything he asked for in the prologue.
# That is the entire problem. RULE 25 note: the GAME ends with hope
# - this ROUTE doesn't, and the save lives on so the player can
# walk it back. The contrast is the point.

extends Control

const BEATS := [
	"The special drops at midnight.",
	"Number one in forty territories by morning. The laugh track is perfect. It was recorded years ago.",
	"The followers arrive in waves. He stops reading the names.",
	"He gets the seat at the table. The table is very long. Nobody at it looks at anybody.",
	"He never finds out what was under the estates.",
	"He stops asking.",
	"That was the deal. Nobody ever says it out loud.",
	"",
	"Years later, a janitor sweeps the studio between takes.",
	"Da'Herm doesn't recognize him.",
	"That's the worst part.",
	"",
	"DA'HERM WARS EPISODE X: A NEW DA'HOPE",
	"— THE BAD ENDING —",
	"",
	"(your save remembers the summit. you can still walk back up.)",
]

var _label: Label
var _index: int = 0
var _done: bool = false


func _ready() -> void:
	GameState.set_flag(&"special_received")
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.03)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color(0.75, 0.72, 0.68))
	add_child(_label)

	var hint := Label.new()
	hint.text = "[JUMP] continue"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.position += Vector2(-180, -50)
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	add_child(hint)

	_show_beat()


func _show_beat() -> void:
	_label.text = BEATS[_index]
	_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_label, "modulate:a", 1.0, 0.7)


func _unhandled_input(event: InputEvent) -> void:
	if _done or not event.is_action_pressed("jump"):
		return
	_index += 1
	if _index >= BEATS.size():
		_done = true
		get_tree().change_scene_to_file("res://scenes/levels/title_screen.tscn")
		return
	_show_beat()
