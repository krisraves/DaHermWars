# busk_spot.gd
# Street busking - the slice's opening tone beat made interactive.
# Every set earns a few Followers and one canon heckle from the
# RECURRING WORLD JOKE pool ("everyone thinks they could do comedy").

class_name BuskSpot
extends Interactable

const HECKLES := [
	"My cousin's funnier.",
	"I could do comedy.",
	"You got Venmo?",
	"...keep it together, man.",
	"Is this part of the show?",
]

@export var followers_per_set: int = 8
@export var uses: int = 5


func _ready() -> void:
	prompt_text = "[E] BUSK"
	detect_size = Vector2(100, 110)
	super()
	_build_visual()


func _build_visual() -> void:
	var crate := ColorRect.new()
	crate.size = Vector2(56, 30)
	crate.position = Vector2(-28, -30)
	crate.color = Color(0.5, 0.36, 0.2)
	add_child(crate)

	var hat := ColorRect.new()
	hat.size = Vector2(26, 10)
	hat.position = Vector2(44, -10)
	hat.color = Color(0.25, 0.22, 0.28)
	add_child(hat)


func interact() -> void:
	if uses <= 0:
		DialogueSystem.start_simple("", ["(This corner has heard enough of your material.)"])
		return
	uses -= 1
	# CONTENT MACHINE (08_COSTUMES): quantity over quality.
	# Double the numbers; the respect cost is tracked in alignment.
	if GameState.costume == &"content_machine":
		GameState.add_followers(followers_per_set * 2)
		GameState.add_alignment("hack")
	else:
		GameState.add_followers(followers_per_set)
		GameState.add_alignment("crowd_work")
	Juice.float_text(global_position + Vector2(0, -70), HECKLES.pick_random(), Color(0.85, 0.8, 0.7))
	Juice.float_text(global_position + Vector2(0, -100), "+%d FOLLOWERS" % followers_per_set, Color(0.4, 0.9, 1.0))


func _prompt_enabled() -> bool:
	return uses > 0
