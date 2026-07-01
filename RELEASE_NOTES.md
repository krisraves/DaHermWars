# flame_residue.gd
# INFERNAL MASTERY (07_ABILITIES tier 8: "Full Flame Glove
# awakening. Required for True Ending content.") Where Tuff Tiddy
# dissolved, something of the cult's stolen fire remains. The glove
# wants it back.

class_name FlameResidue
extends Interactable

func _init() -> void:
	prompt_text = "[E] THE RESIDUE"


func _ready() -> void:
	super()
	var pool := ColorRect.new()
	pool.size = Vector2(110, 12)
	pool.position = Vector2(-55, -12)
	pool.color = Color(0.15, 0.1, 0.18)
	add_child(pool)
	var flame := ColorRect.new()
	flame.size = Vector2(22, 34)
	flame.position = Vector2(-11, -44)
	flame.color = Color(1, 0.45, 0.15)
	add_child(flame)


func interact() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	DialogueSystem.start_simple("", [
		"(Where he dissolved, something still burns. It isn't his. It never was.)",
		"(The glove pulls toward it like it's owed.)",
		"(You let it collect.)"])
	DialogueSystem.finished.connect(_grant.bind(players[0]), CONNECT_ONE_SHOT)


func _grant(player: Player) -> void:
	player.grant_ability(&"infernal_mastery")
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("INFERNAL MASTERY\nFull Flame Glove awakening. +6 Flame damage. The dash answers faster.")
	Juice.shake(5.0)
	queue_free()
