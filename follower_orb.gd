# weapon_db.gd
# Autoload. Data-driven weapon registry (TECHNICAL_ARCHITECTURE:
# "data-driven resources", "avoid hardcoded content").
# Adding a weapon to the game = adding an entry here + a pickup.
#
# Descriptions are in-character per UI_UX_BIBLE: "Descriptions
# should be funny."

extends Node

const WEAPONS := {
	&"flame_glove": {
		"name": "FLAME GLOVE",
		"desc": "Weapon, key, and life choice. Generates Heat.",
		"damage": 10,
		"swing_time": 0.16,
		"cooldown": 0.10,
		"knockback": 300.0,
		"lift": -170.0,
		"random_knockback": false,
		"heat_gain": true,
		"flash_color": Color(1, 0.62, 0.08, 0.85),
	},
	&"folding_chair": {
		"name": "FOLDING CHAIR",
		"desc": "The universal language of poor decisions. High stagger.",
		"damage": 17,
		"swing_time": 0.26,
		"cooldown": 0.34,
		"knockback": 480.0,
		"lift": -240.0,
		"random_knockback": false,
		"heat_gain": false,
		"flash_color": Color(0.75, 0.78, 0.85, 0.9),
	},
	&"pod_mic": {
		"name": "POD MIC",
		"desc": "'Borrowed' equipment. Feeds on momentum - damage grows with your combo.",
		"damage": 8,
		"swing_time": 0.14,
		"cooldown": 0.08,
		"knockback": 280.0,
		"lift": -160.0,
		"random_knockback": false,
		"heat_gain": false,
		"combo_scaling": true,
		"flash_color": Color(0.35, 0.9, 1.0, 0.9),
	},
	&"rubber_chicken": {
		"name": "RUBBER CHICKEN",
		"desc": "Low damage. High comedy. Physics has given up.",
		"damage": 6,
		"swing_time": 0.12,
		"cooldown": 0.05,
		"knockback": 300.0,
		"lift": -160.0,
		"random_knockback": true,  # nobody knows where they'll land
		"heat_gain": false,
		"flash_color": Color(1, 0.9, 0.2, 0.9),
	},
}


func get_weapon(id: StringName) -> Dictionary:
	return WEAPONS.get(id, WEAPONS[&"flame_glove"])


func display_name(id: StringName) -> String:
	return get_weapon(id)["name"]
