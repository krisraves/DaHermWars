# hud.gd
# Combat HUD, per UI_UX_BIBLE:
#   Top left  - Health (warm red)
#   Top right - Heat meter (orange/gold)
# Follower counter joins in M5 when Followers exist.
# Placeholder rects now; PS1-flavored skin comes in the polish phase.

extends CanvasLayer

@onready var _health_fill: ColorRect = $HealthBar/Fill
@onready var _health_back: ColorRect = $HealthBar
@onready var _heat_fill: ColorRect = $HeatBar/Fill
@onready var _heat_back: ColorRect = $HeatBar

var _player: Player


var _boss_health: Health = null


func _ready() -> void:
	add_to_group("hud")
	$Banner.visible = false
	$BossBar.visible = false
	GameState.followers_changed.connect(_on_followers_changed)
	_on_followers_changed(GameState.followers)
	await get_tree().process_frame  # let the player register in its group
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.is_empty():
		return
	_player = nodes[0]
	_player.health_changed.connect(_on_health_changed)
	_player.heat_changed.connect(_on_heat_changed)
	_on_health_changed(_player.health.current, _player.health.max_health)
	_on_heat_changed(_player.heat, _player.max_heat)


func _on_health_changed(current: int, max_value: int) -> void:
	var ratio := float(current) / float(maxi(max_value, 1))
	_health_fill.size.x = (_health_back.size.x - 6.0) * ratio
	# flash the frame on damage
	var tween := create_tween()
	_health_back.modulate = Color(1.6, 1.6, 1.6)
	tween.tween_property(_health_back, "modulate", Color.WHITE, 0.2)


func _on_heat_changed(current: float, max_value: float) -> void:
	var ratio := current / maxf(max_value, 1.0)
	_heat_fill.size.x = (_heat_back.size.x - 6.0) * ratio


func show_banner(text: String) -> void:
	var banner: Label = $Banner
	banner.text = text
	banner.visible = true
	banner.modulate = Color(1, 1, 1, 0)
	banner.scale = Vector2(0.8, 0.8)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(banner, "modulate:a", 1.0, 0.25)
	tween.tween_property(banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_interval(2.6)
	tween.chain().tween_property(banner, "modulate:a", 0.0, 0.4)
	tween.chain().tween_callback(func(): banner.visible = false)


func _on_followers_changed(total: int) -> void:
	$FollowerLabel.text = "FOLLOWERS  %d" % total


func show_boss(boss_name: String, boss_health: Health) -> void:
	_boss_health = boss_health
	$BossBar/Name.text = boss_name
	$BossBar.visible = true
	_boss_health.damaged.connect(_on_boss_damaged)
	_update_boss_fill(1.0)
	_boss_health.died.connect(hide_boss)


func hide_boss() -> void:
	$BossBar.visible = false


func _on_boss_damaged(_amount: int, current: int) -> void:
	_update_boss_fill(float(current) / float(_boss_health.max_health))


func _update_boss_fill(ratio: float) -> void:
	var back: ColorRect = $BossBar
	var fill: ColorRect = $BossBar/Fill
	fill.size.x = (back.size.x - 6.0) * clampf(ratio, 0.0, 1.0)
