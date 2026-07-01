# settings.gd  (AUTOLOAD: Settings)
# Accessibility & comfort options (12_CLAUDE_DEVELOPMENT_RULES /
# roadmap Phase 13+15). Persisted to user://settings.cfg, separate
# from saves: comfort settings belong to the PLAYER, not the run.

extends Node

const PATH := "user://settings.cfg"

var screen_shake: bool = true
var hit_pause: bool = true      # the Juice.hitstop freeze-frames
var reduced_flash: bool = false  # caps full-screen flash effects


func _ready() -> void:
	_load()
	_apply()


func toggle(setting: StringName) -> void:
	match setting:
		&"screen_shake": screen_shake = not screen_shake
		&"hit_pause": hit_pause = not hit_pause
		&"reduced_flash": reduced_flash = not reduced_flash
	_apply()
	_save()


func _apply() -> void:
	Juice.screen_shake_enabled = screen_shake
	Juice.hitstop_enabled = hit_pause


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	screen_shake = cfg.get_value("comfort", "screen_shake", true)
	hit_pause = cfg.get_value("comfort", "hit_pause", true)
	reduced_flash = cfg.get_value("comfort", "reduced_flash", false)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("comfort", "screen_shake", screen_shake)
	cfg.set_value("comfort", "hit_pause", hit_pause)
	cfg.set_value("comfort", "reduced_flash", reduced_flash)
	cfg.save(PATH)
