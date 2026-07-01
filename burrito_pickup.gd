# input_setup.gd
# Autoload. Registers all input actions at runtime.
# Keyboard + gamepad, no manual InputMap editing required.

extends Node


func _ready() -> void:
	_action("move_left",
		[_key(KEY_A), _key(KEY_LEFT),
		_joy_axis(JOY_AXIS_LEFT_X, -1.0),
		_joy_btn(JOY_BUTTON_DPAD_LEFT)])

	_action("move_right",
		[_key(KEY_D), _key(KEY_RIGHT),
		_joy_axis(JOY_AXIS_LEFT_X, 1.0),
		_joy_btn(JOY_BUTTON_DPAD_RIGHT)])

	_action("jump",
		[_key(KEY_SPACE), _key(KEY_Z),
		_joy_btn(JOY_BUTTON_A)])

	_action("dash",
		[_key(KEY_SHIFT), _key(KEY_K),
		_joy_btn(JOY_BUTTON_B),
		_joy_btn(JOY_BUTTON_RIGHT_SHOULDER)])

	_action("attack",
		[_key(KEY_J), _key(KEY_X),
		_joy_btn(JOY_BUTTON_X)])

	_action("crouch",
		[_key(KEY_S), _key(KEY_DOWN),
		_joy_axis(JOY_AXIS_LEFT_Y, 1.0),
		_joy_btn(JOY_BUTTON_DPAD_DOWN)])

	_action("interact",
		[_key(KEY_E), _key(KEY_UP),
		_joy_btn(JOY_BUTTON_Y),
		_joy_btn(JOY_BUTTON_DPAD_UP)])

	_action("reset",
		[_key(KEY_R), _joy_btn(JOY_BUTTON_BACK)])

	_action("pause",
		[_key(KEY_ESCAPE), _key(KEY_P),
		_joy_btn(JOY_BUTTON_START)])

	_action("toggle_debug",
		[_key(KEY_F1)])


func _action(action_name: String, events: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.3)
	for ev in events:
		InputMap.action_add_event(action_name, ev)


func _key(keycode: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	return ev


func _joy_btn(button: JoyButton) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	return ev


func _joy_axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	return ev
