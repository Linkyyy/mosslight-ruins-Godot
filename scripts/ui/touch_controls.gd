extends Control
## Pointer ownership prevents one finger releasing another finger's action.
var owners: Dictionary = {}
var held: Dictionary = {}
var stick_id: int = -1
var stick_offset: Vector2 = Vector2.ZERO
var enabled: bool = false
var actions: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	Controls.reset_requested.connect(clear)
	resized.connect(queue_redraw)

func _process(_delta: float) -> void:
	enabled = Controls.touch_enabled() and not get_tree().paused
	visible = enabled
	if not enabled and not owners.is_empty(): clear()
	queue_redraw()

func _layout() -> void:
	var safe: Vector4 = UI.safe_insets()
	var right: float = size.x-safe.z
	var bottom: float = size.y-safe.w
	actions = {"jump":[Vector2(right-86,bottom-146),64.0,"jump"],"attack":[Vector2(right-205,bottom-90),55.0,"sword"],"cast":[Vector2(right-326,bottom-105),43.0,"fire"],"dash":[Vector2(right-205,bottom-220),43.0,"dash"],"interact":[Vector2(right-86,bottom-280),40.0,"hand"]}

func _stick_center() -> Vector2:
	var safe: Vector4 = UI.safe_insets()
	return Vector2(114+safe.x,size.y-110-safe.w)

func _input(event: InputEvent) -> void:
	if not enabled: return
	_layout()
	if event is InputEventScreenTouch:
		if event.pressed:
			var p: Vector2 = event.position
			if stick_id<0 and p.distance_to(_stick_center())<108:
				stick_id = event.index
				owners[event.index] = "stick"
				_move_stick(p)
				get_viewport().set_input_as_handled()
			else:
				for action in actions:
					if p.distance_to(actions[action][0])<actions[action][1]+8:
						owners[event.index] = action
						held[action] = int(held.get(action,0))+1
						Input.action_press(action)
						get_viewport().set_input_as_handled()
						break
		else:
			release_pointer(event.index)
	elif event is InputEventScreenDrag and event.index==stick_id:
		_move_stick(event.position)
		get_viewport().set_input_as_handled()

func _move_stick(at: Vector2) -> void:
	stick_offset = (at-_stick_center()).limit_length(48)
	Input.action_release("move_left")
	Input.action_release("move_right")
	if absf(stick_offset.x)>7:
		Input.action_press("move_left" if stick_offset.x<0 else "move_right",minf(1,absf(stick_offset.x)/30))

func release_pointer(id: int) -> void:
	if not owners.has(id): return
	var action: String = owners[id]
	owners.erase(id)
	if action=="stick":
		stick_id = -1
		stick_offset = Vector2.ZERO
		Input.action_release("move_left")
		Input.action_release("move_right")
	else:
		held[action] = maxi(0,int(held.get(action,0))-1)
		if int(held[action])==0: Input.action_release(action)

func clear() -> void:
	for id in owners.keys(): release_pointer(id)
	owners.clear()
	held.clear()

func _draw() -> void:
	if not enabled: return
	_layout()
	var center = _stick_center()
	draw_circle(center,92,Color("1d47344d"))
	draw_arc(center,92,0,TAU,64,Color("dfdfb65c"),1.5,true)
	draw_circle(center+stick_offset,35,Color("b4c89955"))
	draw_arc(center+stick_offset,35,0,TAU,32,Color("e4e5bd88"),1.5,true)
	for action in actions:
		var entry: Array = actions[action]
		var locked: bool = (action=="attack" and not RunState.unlocked(str(RunState.data.weapon))) or (action=="cast" and not RunState.unlocked(str(RunState.data.element)))
		var center_action: Vector2 = entry[0]
		var radius: float = entry[1]
		draw_circle(center_action,radius,Color("9eae7177") if int(held.get(action,0))>0 else Color("294f3c88"))
		draw_arc(center_action,radius,0,TAU,40,Color("dce2b73d") if locked else Color("dce2b780"),1.5,true)
		var image = UI.icon(entry[2])
		draw_texture_rect(image,Rect2(center_action-Vector2(18,18),Vector2(36,36)),false,Color(1,1,1,.3 if locked else .95))
