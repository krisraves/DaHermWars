# npc_base.gd
# Base NPC: an Interactable with a code-built body and simple
# looping dialogue. Per NPC_BIBLE: no generic quest dispensers -
# even the base class requires a name and a voice (lines).
# Specific characters (George, Raves) extend this with logic.

class_name NPCBase
extends Interactable

@export var npc_name: String = "PEDESTRIAN"
var counts_for_thought_leader: bool = true
@export var lines: Array[String] = []
@export var body_color: Color = Color(0.5, 0.45, 0.5)
@export var accent_color: Color = Color(0.35, 0.3, 0.35)
@export var body_size: Vector2 = Vector2(34, 76)
@export var round_head: bool = false  # wider, softer top (shape language)

var _line_index: int = 0


func _ready() -> void:
	super()
	_build_visual()


func _build_visual() -> void:
	var visual := Node2D.new()
	visual.name = "Visual"
	add_child(visual)

	var body := ColorRect.new()
	body.size = body_size
	body.position = -body_size * 0.5
	body.color = body_color
	visual.add_child(body)

	var head_w := body_size.x * (1.3 if round_head else 0.85)
	var head := ColorRect.new()
	head.size = Vector2(head_w, body_size.y * 0.28)
	head.position = Vector2(-head_w * 0.5, -body_size.y * 0.5)
	head.color = accent_color
	visual.add_child(head)

	var tag := Label.new()
	tag.text = npc_name
	tag.position = Vector2(-body_size.x, -body_size.y * 0.5 - 26.0)
	tag.add_theme_font_size_override("font_size", 12)
	tag.add_theme_color_override("font_color", Color(0.75, 0.72, 0.68))
	tag.add_theme_color_override("font_outline_color", Color.BLACK)
	tag.add_theme_constant_override("outline_size", 3)
	visual.add_child(tag)


func interact() -> void:
	if lines.is_empty():
		return
	# THOUGHT LEADER (08_COSTUMES): people quote you. Conversation pays.
	# (Not George. George is not engagement.)
	if GameState.costume == &"thought_leader" and counts_for_thought_leader:
		GameState.add_followers(2)
		Juice.float_text(global_position + Vector2(0, -80), "+2 (they'll quote that)", Color(0.4, 0.9, 1.0))
	# one line per talk, cycling - keeps NPCs snackable
	DialogueSystem.start_simple(npc_name, [lines[_line_index]])
	_line_index = (_line_index + 1) % lines.size()
