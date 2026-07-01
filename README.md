# chuckle_kiosk.gd
# THE CHUCKLE YUCKS SIGN-UP KIOSK (Open Mic Alley, under the big
# screen). Available after the broadcast; requires 150 Followers
# ("contestant minimum"). Signing sets chuckle_yucks_signed - the
# flag that opens Influencer Hills and starts the mid-game.

class_name ChuckleKiosk
extends Interactable

const REQUIRED := 150


func _ready() -> void:
	prompt_text = "SIGN UP"
	super()
	var stand := ColorRect.new()
	stand.size = Vector2(56, 96)
	stand.position = Vector2(-28, -51)
	stand.color = Color(0.55, 0.1, 0.5)
	add_child(stand)
	var screen := ColorRect.new()
	screen.size = Vector2(44, 34)
	screen.position = Vector2(-22, -41)
	screen.color = Color(1, 0.85, 0.3)
	add_child(screen)
	var label := Label.new()
	label.text = "CHUCKLE\nYUCKS"
	label.position = Vector2(-26, -91)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	add_child(label)


func interact() -> void:
	if GameState.has_flag(&"chuckle_yucks_signed"):
		DialogueSystem.start_simple("KIOSK", ["CONTESTANT #88,214 — STATUS: REGISTERED. GOOD LUCK!*\n(*outcome statistically predetermined)"])
		return
	if not GameState.has_flag(&"finale_seen"):
		DialogueSystem.start_simple("KIOSK", ["REGISTRATION OPENS AFTER THE ANNOUNCEMENT.\n(The screen shows a countdown to something.)"])
		return
	if GameState.followers < REQUIRED:
		DialogueSystem.start_simple("KIOSK", ["CONTESTANT MINIMUM: %d FOLLOWERS. YOU HAVE: %d.\nHAVE YOU CONSIDERED BEING MORE VISIBLE?" % [REQUIRED, GameState.followers]])
		return
	DialogueSystem.start([
		{"speaker": "KIOSK", "text": "WELCOME, APPLICANT. BY SIGNING YOU AGREE TO TERMS (847 PAGES), IMAGE RIGHTS (PERPETUAL), AND CLAUSE 13 (REDACTED)."},
		{"speaker": "DA'HERM", "text": "What's Clause 13?"},
		{"speaker": "KIOSK", "text": "GREAT QUESTION! SIGNING..."},
		{"speaker": "DA'HERM", "text": "Wait—"},
		{"speaker": "KIOSK", "text": "CONGRATULATIONS, CONTESTANT #88,214."},
	])
	DialogueSystem.finished.connect(_signed, CONNECT_ONE_SHOT)


func _signed() -> void:
	GameState.set_flag(&"chuckle_yucks_signed")
	SaveSystem.autosave()
	for hud in get_tree().get_nodes_in_group("hud"):
		hud.show_banner("CHUCKLE YUCKS — REGISTERED\nThe Hills are open to contestants. Somewhere, a list updated.")
