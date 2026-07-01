# ending_true.gd
# THE TRUE ENDING (03_STORY_BIBLE). The audience awakens. The cycle
# breaks. Da'Herm's final line, verbatim. RULE 12 holds to the last:
# the audience never hears the Joke. Neither do we.

extends Control

const BEATS := [
	"In the Headliner, the applause stops.",
	"For the first time in the building's history, somebody laughs because they want to.",
	"Then somebody else. It spreads like the opposite of a fire alarm.",
	"The follower counters over the exits flicker, read zero, and go dark. Nobody checks them.",
	"Out East, the screens stay off. People are busy.",
	"Raves does an open mic on a Tuesday. Eight people. One real laugh. He's chasing it.",
	"Brittney tells the whole story to a room with no cameras in it. They believe her.",
	"Nobody sees the janitor again. The floors stay clean anyway.",
	"",
	"Da'Herm stands at the back of a small room with a wobbly mic stand,",
	"watching a nervous kid bomb, recover, and land one.",
	"",
	"\"Everyone deserves the opportunity and circumstances that allow them to laugh.\"",
	"",
	"He never tells anyone the Joke.",
	"It wasn't for telling.",
	"",
	"DA'HERM WARS EPISODE X: A NEW DA'HOPE",
	"— THE TRUE ENDING —",
	"",
	"(thank you for the laugh. the real one.)",
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
	_label.add_theme_color_override("font_color", Color(0.88, 0.86, 0.82))
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
