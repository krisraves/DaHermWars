# ending_good.gd
# THE GOOD ENDING (03_STORY_BIBLE): Tuff Tiddy falls. The
# Illuminepsteins lose power. The machine is damaged. Not destroyed.
# Final message: truth matters. (The TRUE ending - M11 - asks more.)

extends Control

const BEATS := [
	"The Pyramid goes quiet for the first time in a century.",
	"The broadcast cuts out mid-sponsorship.",
	"Across Out East, screens fail. People look up. Some of them look at each other.",
	"The machine is damaged.",
	"Not destroyed.",
	"",
	"DA'HERM WARS EPISODE X: A NEW DA'HOPE",
	"— THE GOOD ENDING —",
	"",
	"Somewhere on the island, a janitor keeps sweeping.",
	"There are fragments still out there. Someone is still waiting in the front row.",
]

var _label: Label
var _index: int = 0
var _done: bool = false


func _ready() -> void:
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
	_label.add_theme_color_override("font_color", Color(0.85, 0.83, 0.8))
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
