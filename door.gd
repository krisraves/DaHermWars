# player.gd
# Da'Herm controller - MILESTONE 3 (movement + combat + FLAME DASH)
#
# FLAME DASH (Flame Glove Tier 2, 01_GAME_DESIGN_BIBLE):
# horizontal burst, crosses gaps, damages enemies.
# First major traversal upgrade - the Metroidvania loop starts here.
#
# DESIGN CALL (logged for review): the Design Bible lists Heat as the
# resource for "mobility powers," but gating a core traversal tool
# behind a combat-generated resource would block exploration when the
# player needs it most. Per Rule 24 (avoid outdated frustration) and
# the Final Technical Rule (control quality first), the dash is
# cooldown-based and free; it GENERATES Heat when it hits enemies.
# Heat spending moves to combat specials (later milestones).
#
# Dash rules:
#   - Unlocked via pickup (has_flame_dash, per TECHNICAL_ARCHITECTURE
#     ability flags). Locked at game start.
#   - Ground dash: cooldown only.
#   - ONE air dash; restored on landing or wall slide.
#   - Brief i-frames during the dash (it's made of fire; trades hit
#     trades into style).
#   - Dashing through enemies deals damage + builds Heat.

extends CharacterBody2D
class_name Player

signal health_changed(current: int, max_value: int)
signal heat_changed(current: float, max_value: float)
signal ability_unlocked(ability: StringName)
signal player_died

enum State { IDLE, RUN, JUMP, FALL, WALL_SLIDE, PUNCH, DASH, HURT, DEAD }

# ------------------------------------------------------------------ tuning

@export_group("Run")
@export var run_speed: float = 340.0
@export var ground_accel: float = 3200.0
@export var ground_friction: float = 3000.0
@export var air_accel: float = 2100.0
@export var air_friction: float = 700.0

@export_group("Jump")
@export var jump_velocity: float = -700.0
@export var jump_cut_multiplier: float = 0.45
@export var gravity_up: float = 1850.0
@export var gravity_down: float = 2700.0
@export var apex_gravity_scale: float = 0.6
@export var apex_threshold: float = 90.0
@export var max_fall_speed: float = 1150.0
@export var coyote_time: float = 0.10
@export var jump_buffer_time: float = 0.12

@export_group("Wall")
@export var wall_slide_speed: float = 110.0
@export var wall_jump_velocity: Vector2 = Vector2(400.0, -580.0)
@export var wall_jump_lock_time: float = 0.13

@export_group("Flame Punch")
@export var punch_duration: float = 0.16
@export var punch_cooldown: float = 0.10

@export_group("Flame Dash")
@export var has_flame_dash: bool = false
@export var dash_speed: float = 800.0
@export var dash_time: float = 0.18
@export var dash_cooldown: float = 0.40
@export var dash_end_speed: float = 360.0

@export_group("Double Jump")
@export var has_double_jump: bool = false
@export var air_jump_scale: float = 0.92

@export_group("Combat")
@export var hurt_stun_time: float = 0.25
@export var invuln_time: float = 0.9
@export var max_heat: float = 100.0
@export var heat_per_hit: float = 12.0

# ------------------------------------------------------------------ state

var state: State = State.IDLE
var facing: int = 1
var heat: float = 0.0

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _wall_lock_timer: float = 0.0
var _punch_timer: float = 0.0
var _punch_cd_timer: float = 0.0
var _dash_timer: float = 0.0
var _dash_cd_timer: float = 0.0
var _dash_dir: int = 1
var _air_dash_available: bool = true
var _air_jump_available: bool = true
var combo: int = 0
var _suppress_timer: float = 0.0
var _jump_mult: float = 1.0
var _air_accel_mult: float = 1.0
var _afterimage_timer: float = 0.0
var _hurt_timer: float = 0.0
var _invuln_timer: float = 0.0
var _was_on_floor: bool = true
var _squash_impulse: Vector2 = Vector2.ONE
var _spawn_position: Vector2

@onready var health: Health = $Health
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _visual: Node2D = $Visual
@onready var _punch_flash: ColorRect = $Visual/PunchFlash
@onready var _hitbox: Hitbox = $Hitbox
@onready var _hitbox_shape: CollisionShape2D = $Hitbox/HitboxShape
@onready var _dash_hitbox: Hitbox = $DashHitbox
@onready var _dash_shape: CollisionShape2D = $DashHitbox/Shape
@onready var _debug_label: Label = $DebugLabel

# ------------------------------------------------------------------ lifecycle

func _ready() -> void:
	add_to_group("player")
	_spawn_position = global_position
	# pull persistent state across room transitions
	has_flame_dash = GameState.has_flame_dash
	has_double_jump = GameState.has_double_jump
	health.max_health = GameState.max_health
	health.current = clampi(GameState.health, 1, GameState.max_health)
	heat = GameState.heat
	apply_costume()
	_hurtbox.hit_received.connect(_on_hit_received)
	_hitbox.hit_landed.connect(_on_weapon_hit)
	_dash_hitbox.hit_landed.connect(_on_dash_hit)
	health.died.connect(_on_died)
	health_changed.emit(health.current, health.max_health)
	heat_changed.emit(heat, max_heat)


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	# STREAMING PASS (Netflicks): always buffering. Heat trickles back.
	if GameState.has_relic(&"streaming_pass") and heat < max_heat:
		heat = minf(max_heat, heat + 6.0 * delta)
		heat_changed.emit(heat, max_heat)

	if Input.is_action_just_pressed("reset"):
		respawn()
	if Input.is_action_just_pressed("toggle_debug"):
		_debug_label.visible = not _debug_label.visible

	if state == State.DEAD:
		return

	var input_x := Input.get_axis("move_left", "move_right")
	var input_locked := _wall_lock_timer > 0.0 or _hurt_timer > 0.0
	if input_locked:
		input_x = 0.0

	var dashing := _dash_timer > 0.0

	if not dashing:
		_apply_gravity(delta)
		_handle_horizontal(input_x, delta, input_locked)
		if _hurt_timer <= 0.0:
			_handle_jump_input()
			_handle_wall_slide(input_x)
			_handle_punch_input()
			_handle_dash_input(input_x)
	else:
		_run_dash(delta)

	var fall_speed := velocity.y
	move_and_slide()

	# landing feel: squash + dust on any real fall (Phase 13 polish)
	if is_on_floor() and not _was_on_floor and fall_speed > 420.0:
		_squash(Vector2(1.22, 0.78))
		Juice.dust(global_position + Vector2(0, 38))
	_was_on_floor = is_on_floor()
	_squash_impulse = _squash_impulse.lerp(Vector2.ONE, minf(1.0, 11.0 * delta))

	if is_on_floor():
		_coyote_timer = coyote_time
		_air_dash_available = true
		_air_jump_available = true

	_update_state(input_x)
	_update_visual()
	_update_debug()


# ------------------------------------------------------------------ flame dash

func grant_ability(ability: StringName) -> void:
	match ability:
		&"flame_dash":
			has_flame_dash = true
			GameState.has_flame_dash = true
		&"double_jump":
			has_double_jump = true
			GameState.has_double_jump = true
		&"infernal_mastery":
			# Flame Glove tier 8: the full awakening. The cult's stolen
			# fire, taken back. (+6 Flame damage, dash recovers faster)
			GameState.has_infernal_mastery = true
	ability_unlocked.emit(ability)
	SaveSystem.autosave()  # spec: autosave on ability unlock


func _handle_dash_input(input_x: float) -> void:
	if not has_flame_dash:
		return
	if not Input.is_action_just_pressed("dash"):
		return
	if _dash_cd_timer > 0.0:
		return
	if not is_on_floor() and not _air_dash_available:
		return
	_start_dash(input_x)


func _start_dash(input_x: float) -> void:
	_dash_dir = int(signf(input_x)) if absf(input_x) > 0.01 else facing
	facing = _dash_dir
	_dash_timer = dash_time
	var cd := dash_cooldown
	if GameState.has_infernal_mastery:
		cd *= 0.6  # the flame answers faster now
	_dash_cd_timer = dash_time + cd
	if not is_on_floor():
		_air_dash_available = false

	velocity = Vector2(dash_speed * _dash_dir, 0.0)

	# cancel any punch in progress
	_punch_timer = 0.0
	_set_punch_active(false)

	_dash_hitbox.monitoring_changed_rearm()
	_dash_hitbox.set_deferred("monitoring", true)
	_dash_shape.set_deferred("disabled", false)
	_afterimage_timer = 0.0
	Juice.shake(2.0)


func _run_dash(delta: float) -> void:
	velocity.x = dash_speed * _dash_dir
	velocity.y = 0.0

	_afterimage_timer -= delta
	if _afterimage_timer <= 0.0:
		_spawn_afterimage()
		_afterimage_timer = 0.035

	if _dash_timer <= 0.0:
		_end_dash()


func _end_dash() -> void:
	velocity.x = dash_end_speed * _dash_dir  # keep momentum, drop the burst
	_dash_hitbox.set_deferred("monitoring", false)
	_dash_shape.set_deferred("disabled", true)


func _spawn_afterimage() -> void:
	var ghost := ColorRect.new()
	ghost.size = Vector2(36, 84)
	ghost.position = global_position - Vector2(18, 42)
	ghost.color = Color(1.0, 0.5, 0.08, 0.55)
	ghost.z_index = -1
	get_tree().current_scene.add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tween.tween_callback(ghost.queue_free)


# ------------------------------------------------------------------ movement

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var g := gravity_down if velocity.y > 0.0 else gravity_up
	if absf(velocity.y) < apex_threshold:
		g *= apex_gravity_scale
	if state == State.WALL_SLIDE:
		velocity.y = minf(velocity.y + g * delta, wall_slide_speed)
	else:
		velocity.y = minf(velocity.y + g * delta, max_fall_speed)


func _handle_horizontal(input_x: float, delta: float, input_locked: bool) -> void:
	var accel := ground_accel if is_on_floor() else air_accel * _air_accel_mult
	var friction := ground_friction if is_on_floor() else air_friction
	if _hurt_timer > 0.0:
		friction *= 0.4

	if absf(input_x) > 0.01 and not input_locked:
		velocity.x = move_toward(velocity.x, input_x * run_speed, accel * delta)
		facing = 1 if input_x > 0.0 else -1
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


func _handle_jump_input() -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time

	if _jump_buffer_timer > 0.0:
		if state == State.WALL_SLIDE:
			_do_wall_jump()
		elif _coyote_timer > 0.0:
			_do_jump()
		elif has_double_jump and _air_jump_available:
			_do_air_jump()

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier


func _do_jump() -> void:
	velocity.y = jump_velocity * _jump_mult
	_squash(Vector2(0.82, 1.18))
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0


func _do_air_jump() -> void:
	# AIR CROSSOVER - the King's footwork, executed with a flame burst
	velocity.y = jump_velocity * air_jump_scale * _jump_mult
	_air_jump_available = false
	_jump_buffer_timer = 0.0
	_spawn_afterimage()
	Juice.shake(1.5)


func apply_suppression(duration: float) -> void:
	_suppress_timer = duration
	Juice.float_text(global_position + Vector2(0, -80), "VISIBILITY LIMITED", Color(0.4, 1, 0.8))


func restore_air_moves() -> void:
	_air_dash_available = true
	_air_jump_available = true


func _do_wall_jump() -> void:
	var away := -_wall_direction()
	velocity.x = away * wall_jump_velocity.x
	velocity.y = wall_jump_velocity.y
	facing = away
	_jump_buffer_timer = 0.0
	_wall_lock_timer = wall_jump_lock_time


func _handle_wall_slide(input_x: float) -> void:
	if is_on_floor() or velocity.y < 0.0:
		return
	if not is_on_wall_only():
		return
	var wall_dir := _wall_direction()
	if wall_dir == 0:
		return
	if signf(input_x) == float(wall_dir):
		facing = -wall_dir
		_air_dash_available = true  # wall contact restores air moves
		_air_jump_available = true
		if velocity.y > wall_slide_speed:
			velocity.y = wall_slide_speed


func _wall_direction() -> int:
	if not is_on_wall():
		return 0
	return -int(signf(get_wall_normal().x))


# ------------------------------------------------------------------ flame punch

func _handle_punch_input() -> void:
	if Input.is_action_just_pressed("attack") \
			and _punch_cd_timer <= 0.0 and _punch_timer <= 0.0:
		# attack stats come from the equipped weapon (WeaponDB)
		var weapon := WeaponDB.get_weapon(GameState.equipped_weapon)
		_punch_timer = weapon["swing_time"]
		_punch_cd_timer = weapon["swing_time"] + weapon["cooldown"]
		_hitbox.damage = weapon["damage"] \
				+ (mini(combo, 12) if weapon.get("combo_scaling", false) else 0)
		if GameState.costume == &"headliner_x":  # forgotten greatness
			_hitbox.damage += 2
		# THE HACK (08_COSTUMES liberty): stolen technique, non-Flame only
		if GameState.costume == &"the_hack" and GameState.equipped_weapon != &"flame_glove":
			_hitbox.damage += 3
		if GameState.costume == &"the_former_winner":
			_hitbox.damage += 3  # (08_COSTUMES: "boss damage" approximated flat - logged)
		if GameState.has_infernal_mastery and GameState.equipped_weapon == &"flame_glove":
			_hitbox.damage += 6  # INFERNAL MASTERY (07_ABILITIES tier 8)
		if _suppress_timer > 0.0:  # THE ALGORITHM limited your reach
			_hitbox.damage = maxi(1, _hitbox.damage / 2)
		var kb_scale: float = randf_range(0.4, 1.9) if weapon["random_knockback"] else 1.0
		_hitbox.knockback_strength = weapon["knockback"] * kb_scale
		_hitbox.knockback_lift = weapon["lift"]
		_punch_flash.color = weapon["flash_color"]
		_set_punch_active(true)

	if _punch_timer <= 0.0:
		_set_punch_active(false)


func _set_punch_active(active: bool) -> void:
	_punch_flash.visible = active
	if active:
		_hitbox.monitoring_changed_rearm()
		_hitbox_shape.position.x = absf(_hitbox_shape.position.x) * facing
	_hitbox.set_deferred("monitoring", active)
	_hitbox_shape.set_deferred("disabled", not active)


func _on_weapon_hit(_hurtbox: Hurtbox) -> void:
	combo += 1
	var weapon := WeaponDB.get_weapon(GameState.equipped_weapon)
	if weapon.get("combo_scaling", false) and combo % 5 == 0:
		Juice.float_text(global_position + Vector2(0, -70), "COMBO ×%d" % combo, Color(0.4, 1, 0.9))
	# Only Flame weapons generate Heat (01_GAME_DESIGN_BIBLE).
	if weapon["heat_gain"]:
		_gain_heat()
	Juice.hitstop(0.05)
	Juice.shake(4.0)


func _on_dash_hit(_hurtbox: Hurtbox) -> void:
	_gain_heat()  # the dash IS the Flame Glove
	Juice.hitstop(0.05)
	Juice.shake(4.0)


func _gain_heat() -> void:
	heat = minf(max_heat, heat + heat_per_hit)
	GameState.heat = heat
	heat_changed.emit(heat, max_heat)


# ------------------------------------------------------------------ taking hits

func _on_hit_received(hitbox: Hitbox) -> void:
	if _invuln_timer > 0.0 or state == State.DEAD:
		return
	if _dash_timer > 0.0:
		return  # dash i-frames: you are briefly made of fire
	health.take_damage(hitbox.damage)
	GameState.health = health.current
	health_changed.emit(health.current, health.max_health)
	if health.is_dead:
		return
	combo = 0  # the Pod Mic forgets you when you get hit
	velocity = hitbox.knockback_from(hitbox.global_position, global_position)
	_hurt_timer = hurt_stun_time
	_invuln_timer = invuln_time
	_punch_timer = 0.0
	_set_punch_active(false)
	Juice.hitstop(0.07)
	Juice.shake(7.0)


func _on_died() -> void:
	state = State.DEAD
	player_died.emit()
	velocity = Vector2.ZERO
	_set_punch_active(false)
	_end_dash()
	_dash_timer = 0.0
	Juice.shake(10.0)
	var tween := create_tween()
	tween.tween_property(_visual, "rotation_degrees", -90.0 * facing, 0.3)
	tween.tween_interval(0.8)
	tween.tween_callback(respawn)


# ------------------------------------------------------------------ state & visuals

func _update_state(input_x: float) -> void:
	if state == State.DEAD:
		return
	var new_state := state
	if _hurt_timer > 0.0:
		new_state = State.HURT
	elif _dash_timer > 0.0:
		new_state = State.DASH
	elif _punch_timer > 0.0:
		new_state = State.PUNCH
	elif is_on_floor():
		new_state = State.RUN if absf(velocity.x) > 10.0 else State.IDLE
	elif is_on_wall_only() and velocity.y > 0.0 \
			and signf(input_x) == float(_wall_direction()) and _wall_direction() != 0:
		new_state = State.WALL_SLIDE
	else:
		new_state = State.JUMP if velocity.y < 0.0 else State.FALL
	state = new_state


func _update_visual() -> void:
	_visual.scale.x = float(facing) * _squash_impulse.x
	match state:
		State.JUMP:
			_visual.scale.y = 1.06
		State.FALL:
			_visual.scale.y = 0.96
		State.DASH:
			_visual.scale.y = 0.85  # squash into the burst
		_:
			_visual.scale.y = 1.0
	_visual.scale.y *= _squash_impulse.y

	if _invuln_timer > 0.0:
		_visual.modulate.a = 0.35 if fmod(_invuln_timer, 0.16) < 0.08 else 1.0
	else:
		_visual.modulate.a = 1.0

	if state == State.HURT:
		_visual.modulate = Color(1, 0.4, 0.4, _visual.modulate.a)
	elif state == State.DASH:
		_visual.modulate = Color(1.4, 0.9, 0.5, _visual.modulate.a)
	else:
		_visual.modulate = Color(1, 1, 1, _visual.modulate.a)


func _update_debug() -> void:
	if not _debug_label.visible:
		return
	_debug_label.text = "%s\nHP %d/%d  Heat %d\nvel (%d, %d)  dash %s" % [
		State.keys()[state], health.current, health.max_health, int(heat),
		velocity.x, velocity.y,
		("READY" if _dash_cd_timer <= 0.0 else "cd") if has_flame_dash else "LOCKED"
	]


# ------------------------------------------------------------------ misc

func _tick_timers(delta: float) -> void:
	_coyote_timer = maxf(0.0, _coyote_timer - delta)
	_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)
	_wall_lock_timer = maxf(0.0, _wall_lock_timer - delta)
	_punch_timer = maxf(0.0, _punch_timer - delta)
	_punch_cd_timer = maxf(0.0, _punch_cd_timer - delta)
	_dash_timer = maxf(0.0, _dash_timer - delta)
	_dash_cd_timer = maxf(0.0, _dash_cd_timer - delta)
	_hurt_timer = maxf(0.0, _hurt_timer - delta)
	_invuln_timer = maxf(0.0, _invuln_timer - delta)


func respawn() -> void:
	health.heal_full()
	GameState.health = health.max_health
	# died (or reset) in a different room than the checkpoint? travel there.
	if GameState.respawn_room != GameState.current_room and GameState.respawn_room != "":
		GameState.change_room(GameState.respawn_room, GameState.respawn_spawn)
		return
	var room := get_parent() as RoomBase
	if room != null and room.spawn_points.has(GameState.respawn_spawn) \
			and GameState.respawn_room == GameState.current_room:
		global_position = room.spawn_points[GameState.respawn_spawn]
	else:
		global_position = _spawn_position
	velocity = Vector2.ZERO
	health_changed.emit(health.current, health.max_health)
	_visual.rotation_degrees = 0.0
	_invuln_timer = 1.0
	_hurt_timer = 0.0
	_dash_timer = 0.0
	_end_dash()
	state = State.IDLE


func set_spawn_point(pos: Vector2) -> void:
	_spawn_position = pos


# ------------------------------------------------------------------ costume

func apply_costume() -> void:
	var body: ColorRect = $Visual/Body
	var hood: ColorRect = $Visual/Hood
	var bowtie: ColorRect = $Visual/Bowtie
	_jump_mult = 1.0
	_air_accel_mult = 1.0
	match GameState.costume:
		&"trash_bag_tuxedo":
			body.color = Color(0.1, 0.1, 0.14)     # glossy trash-bag black
			hood.color = Color(0.06, 0.06, 0.09)
			bowtie.visible = true
		&"basketball_prophet":
			body.color = Color(0.1, 0.55, 0.55)    # teal jersey
			hood.color = Color(0.95, 0.5, 0.1)     # orange headband
			bowtie.visible = false
			_jump_mult = 1.06                       # 08_COSTUMES: jump height
			_air_accel_mult = 1.35                  # + air control
		&"thought_leader":
			body.color = Color(0.35, 0.35, 0.4)    # the turtleneck
			hood.color = Color(0.12, 0.12, 0.14)
			bowtie.visible = false
		&"verified":
			body.color = Color(0.92, 0.95, 1.0)    # platform white
			hood.color = Color(0.2, 0.55, 0.95)    # checkmark blue
			bowtie.visible = false
		&"corporate_clean":
			body.color = Color(0.16, 0.22, 0.34)   # the navy suit
			hood.color = Color(0.85, 0.85, 0.88)
			bowtie.visible = true                   # it's a tie. squint.
		&"the_hack":
			body.color = Color(0.45, 0.35, 0.55)   # the coat that was always his
			hood.color = Color(0.25, 0.2, 0.3)
			bowtie.visible = false
		&"headliner_x":
			body.color = Color(0.7, 0.75, 0.9)     # the ghost's cut
			hood.color = Color(0.5, 0.55, 0.75)
			bowtie.visible = true
		&"red_carpet_elite":
			body.color = Color(0.75, 0.12, 0.2)   # the carpet, worn
			hood.color = Color(0.95, 0.85, 0.5)
			bowtie.visible = true
		&"the_former_winner":
			body.color = Color(0.55, 0.5, 0.42)   # a champion's blazer, faded
			hood.color = Color(0.8, 0.7, 0.35)
			bowtie.visible = false
		&"illuminepstein_initiate":
			body.color = Color(0.35, 0.25, 0.45)   # outer-circle robes
			hood.color = Color(0.55, 0.45, 0.2)
			bowtie.visible = false
		&"content_machine":
			body.color = Color(0.85, 0.2, 0.6)     # engagement magenta
			hood.color = Color(0.2, 0.05, 0.15)
			bowtie.visible = false
		_:
			body.color = Color(0.82, 0.45, 0.18)
			hood.color = Color(0.28, 0.3, 0.36)
			bowtie.visible = false


func _exit_tree() -> void:
	GameState.health = health.current
	GameState.heat = heat


func _squash(to: Vector2) -> void:
	# feed the per-frame visual system an impulse; it decays in
	# _physics_process. (A tween here would be stomped every frame
	# by _update_visual's own scale writes - caught in self-audit.)
	_squash_impulse = to
