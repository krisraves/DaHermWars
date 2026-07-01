# special_estates.gd
# REGION 09: SPECIAL ESTATES (11_LEVEL_DESIGN_BIBLE / REG_009)
# "The hidden cost of fame." Purpose: narrative setup for the
# Dark Chapter. Visual rule: Beautiful. Quiet. Uncomfortable.
#
# Deliberately, this region has ZERO enemies, near-zero color, and
# almost nobody home. The discomfort is the content. The SERVICE
# ENTRANCE at the east end goes below.
#
# [DESIGN NOTE - logged liberty] No costume here, breaking the
# every-region-has-a-costume rule on purpose: a collectible reward
# inside the dark chapter's doorstep would fight the tone. This and
# the chapter below are the canon's single sanctioned exception zone.

extends RoomBase

const IVORY := Color(0.62, 0.6, 0.56)
const HEDGE := Color(0.3, 0.34, 0.28)
const DUSK := Color(0.45, 0.42, 0.46)


func _build() -> void:
	spawn_points = {
		&"default": Vector2(150, 560),       # from Influencer Hills
		&"from_below": Vector2(2950, 560),   # back out of the service elevator
		&"from_manor": Vector2(1720, 560),
		&"from_dock": Vector2(2300, 560),
	}
	camera_rect = Rect2(-280, -900, 3760, 2200)
	kill_y = 1200.0

	solid(-280, -700, 80, 1560, IVORY.darkened(0.4))
	solid(3400, -700, 80, 1560, IVORY.darkened(0.4))
	solid(-200, 660, 3600, 200, IVORY.darkened(0.15))

	# ---- the estates: three facades, lights off ------------------------
	for x in [600.0, 1500.0, 2400.0]:
		decor(x, 240, 320, 420, IVORY)
		decor(x + 40.0, 300, 70, 90, DUSK.darkened(0.3))   # dark windows
		decor(x + 200.0, 300, 70, 90, DUSK.darkened(0.3))
		decor(x + 120.0, 540, 80, 120, IVORY.darkened(0.25))  # the door nobody answers

	# hedges, trimmed by someone you never see
	for x in [420.0, 1100.0, 1340.0, 2000.0, 2240.0, 2900.0]:
		decor(x, 580, 120, 80, HEDGE)

	# the fountain
	decor(1050, 500, 200, 24, IVORY.darkened(0.1))
	decor(1130, 420, 40, 80, IVORY.darkened(0.05))
	sign_label(Vector2(1060, 460), "(The fountain runs for no one.)", 12)

	sign_label(Vector2(300, 520), "SPECIAL ESTATES — PRIVATE", 13)
	sign_label(Vector2(1700, 600), "(No mailboxes. No names.)", 12)
	sign_label(Vector2(2600, 600), "(Every lawn is perfect. Every light is off.)", 12)

	# ---- the way down ----------------------------------------------------
	decor(3000, 460, 140, 200, IVORY.darkened(0.35))
	sign_label(Vector2(3010, 420), "SERVICE ENTRANCE\nSTAFF ONLY", 12)


func _populate() -> void:
	# west: back to the Hills terrace
	var west := Door.new()
	west.door_label = "← THE HILLS"
	west.target_scene = "res://scenes/levels/influencer_hills.tscn"
	west.target_spawn = &"from_estates"
	place(west, Vector2(60, 605))

	# the only person outside
	var staff := NPCBase.new()
	staff.npc_name = "STAFF"
	staff.body_color = Color(0.5, 0.5, 0.52)
	staff.lines = [
		"The families are never home.",
		"We're paid not to ask. It's very good pay.",
		"You should go back the way you came.",
	]
	place(staff, Vector2(1900, 615))

	# save: THE QUIET ROOM - a members' lounge, empty
	var save := SavePoint.new()
	save.club_name = "THE QUIET ROOM"
	save.spawn_id = &"save"
	place(save, Vector2(800, 595))
	spawn_points[&"save"] = Vector2(750, 560)
	place(CircuitPhone.new(), Vector2(930, 615))

	# THE PRIVATE DOCK: the boat to the island. Your kiosk registration
	# was the invitation. The finals are not on the mainland.
	var dock := Door.new()
	dock.door_label = "THE PRIVATE DOCK"
	dock.target_scene = "res://scenes/levels/vip_marina.tscn"
	dock.target_spawn = &"default"
	dock.required_flag = &"dark_chapter_done"
	dock.flag_gate_line = "(A gilded boat. The pilot checks a list, then looks through you. Not yet. Something hasn't happened yet.)"
	place(dock, Vector2(2350, 605))

	# the one estate whose door opens: THE WINNER'S
	var manor := Door.new()
	manor.door_label = "THE WINNER'S ESTATE"
	manor.target_scene = "res://scenes/levels/former_winner_manor.tscn"
	manor.target_spawn = &"default"
	place(manor, Vector2(1660, 605))

	# the service entrance: down
	var down := Door.new()
	down.door_label = "SERVICE ENTRANCE"
	down.target_scene = "res://scenes/levels/below_the_estates.tscn"
	down.target_spawn = &"default"
	place(down, Vector2(3050, 605))
