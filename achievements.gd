# credits.gd
# Roadmap Phase 15 requires credits. The project's own mission
# statement IS the credits: "A lost PS1 Metroidvania, written by
# stand-up comics, powered by hip hop, built around the idea that
# laughter is worth protecting."

extends Control

const BEATS := [
	"DA'HERM WARS EPISODE X: A NEW DA'HOPE",
	"",
	"WRITTEN BY\nstand-up comics, allegedly",
	"DESIGNED BY\nMetroidvania veterans, in spirit",
	"POWERED BY\nhip hop (pending audio assets)",
	"PIXEL ART BY\n(this space reserved - the ColorRects were placeholders\nand they knew it the whole time)",
	"",
	"STARRING",
	"DA'HERM\nas himself, eventually",
	"RAVES SUPREME\nwho was always somebody",
	"BRITTNEY NUTTINGS\nwho knew exactly why",
	"TUFF TIDDY\nwho was never funny. but was ridiculous.\nthat's almost something.",
	"and GEORGE\nas George",
	"",
	"NO HECKLERS WERE PERMANENTLY DEFEATED\nDURING THE MAKING OF THIS GAME.\n(one was made to laugh. that counts double.)",
	"",
	"EVERYONE DESERVES THE OPPORTUNITY AND CIRCUMSTANCES\nTHAT ALLOW THEM TO LAUGH.",
	"",
	"thank you for playing.\nso it seems.",
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
	tween.tween_property(_label, "modulate:a", 1.0, 0.6)


func _unhandled_input(event: InputEvent) -> void:
	if _done or not event.is_action_pressed("jump"):
		return
	_index += 1
	if _index >= BEATS.size():
		_done = true
		get_tree().change_scene_to_file("res://scenes/levels/title_screen.tscn")
		return
	_show_beat()
