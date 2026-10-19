extends Node
## One input map for keyboard, gamepad and independent touch pointers.
signal reset_requested
const ACTIONS = ["move_left","move_right","jump","attack","cast","dash","interact","heal","cycle_element","cycle_weapon","weapon_sword","weapon_bow","quick_1","quick_2","quick_3","pause","map","bag","equipment","guide","fullscreen"]

func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bindings = {"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE,KEY_W,KEY_UP],"attack":[KEY_J],"cast":[KEY_K],"dash":[KEY_SHIFT],"interact":[KEY_E],"heal":[KEY_R],"cycle_element":[KEY_Q],"cycle_weapon":[KEY_TAB],"weapon_sword":[KEY_1],"weapon_bow":[KEY_2],"quick_1":[KEY_3],"quick_2":[KEY_4],"quick_3":[KEY_5],"pause":[KEY_ESCAPE],"map":[KEY_M],"bag":[KEY_B],"equipment":[KEY_I],"guide":[KEY_H],"fullscreen":[KEY_F,KEY_F11]}
	for action in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action,0.2)
		for key in bindings[action]:
			var event = InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action,event)
	var buttons = {"jump":JOY_BUTTON_A,"attack":JOY_BUTTON_X,"cast":JOY_BUTTON_Y,"dash":JOY_BUTTON_B,"interact":JOY_BUTTON_RIGHT_SHOULDER,"cycle_element":JOY_BUTTON_LEFT_SHOULDER,"pause":JOY_BUTTON_START,"map":JOY_BUTTON_BACK,"heal":JOY_BUTTON_DPAD_UP}
	for action in buttons:
		var event = InputEventJoypadButton.new()
		event.button_index = buttons[action]
		if not InputMap.action_has_event(action,event): InputMap.action_add_event(action,event)
	for direction in [-1.0,1.0]:
		var event = InputEventJoypadMotion.new()
		event.axis = JOY_AXIS_LEFT_X
		event.axis_value = direction
		var action: String = "move_left" if direction < 0 else "move_right"
		if not InputMap.action_has_event(action,event): InputMap.action_add_event(action,event)

func reset_inputs() -> void:
	for action in ACTIONS:
		Input.action_release(action)
	reset_requested.emit()

func touch_enabled() -> bool:
	return DisplayServer.is_touchscreen_available() or bool(RunState.settings.touch) or "--mobile-preview" in OS.get_cmdline_user_args()
