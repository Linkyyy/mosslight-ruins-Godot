@tool
class_name WorldObject
extends Area2D
@export var object_id: String = "sword"
var clock: float = 0
var blocker: StaticBody2D
var icon: Texture2D

func _ready() -> void:
	if Engine.is_editor_hint():
		var preview_icon = str(GameData.ITEMS.get(object_id,{}).get("icon","bag"))
		icon = load("res://assets/icons/"+preview_icon+".svg")
		queue_redraw()
		return
	add_to_group("interactables")
	collision_layer = 8 if object_id=="conductor" else 0
	collision_mask = 0
	if object_id in ["vines","gate"]:
		blocker = StaticBody2D.new()
		blocker.collision_layer = 2
		blocker.collision_mask = 0
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(22,260)
		collision.shape = shape
		collision.position = Vector2(0,-130)
		blocker.add_child(collision)
		add_child(blocker)
	var icon_name = str(GameData.ITEMS.get(object_id,{}).get("icon","bag"))
	icon = load("res://assets/icons/"+icon_name+".svg")
	RunState.changed.connect(_sync)
	_sync()

func _sync() -> void:
	if object_id in ["vines","gate"]:
		var resolved: bool = bool(RunState.data.flags.get(object_id,false))
		if is_instance_valid(blocker): blocker.set_collision_layer_value(2,not resolved)
	elif (GameData.ITEMS.has(object_id) or GameData.SUPPLIES.has(object_id)) and RunState.completed(object_id):
		queue_free()
	queue_redraw()

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func label() -> String:
	if object_id=="camp": return "休息 · 恢复并记录旅程"
	if object_id=="portal_grotto": return "进入月孢洞窟"
	if object_id=="portal_garden": return "返回苔息庭院"
	if object_id=="portal_return": return "沿根脉返回庭院" if bool(RunState.data.flags.get("boss",false)) else "根脉仍在沉睡"
	if object_id=="vines": return "荆棘 · 需要火焰" if not bool(RunState.data.flags.get("vines",false)) else ""
	if object_id=="gate": return "石门 · 需要鸣雷机关" if not bool(RunState.data.flags.get("gate",false)) else ""
	if object_id=="conductor": return "让雷电沿水面传导" if not bool(RunState.data.flags.get("gate",false)) else "灵石已苏醒"
	return "拾取 · "+str(GameData.ITEMS.get(object_id,{}).get("name","旧日行囊"))

func interact(_player: MossPlayer) -> void:
	if object_id=="camp":
		RunState.rest_at(int(RunState.data.room),global_position)
		Events.effect.emit(global_position-Vector2(0,28),Color("dce0af"),35,110)
	elif object_id=="portal_grotto": Events.transition_requested.emit(4,Vector2(145,590))
	elif object_id=="portal_garden": Events.transition_requested.emit(0,Vector2(970,380))
	elif object_id=="portal_return":
		if bool(RunState.data.flags.get("boss",false)): Events.transition_requested.emit(0,Vector2(430,590))
		else: Events.notice.emit("唤醒古树之心后，这条根脉才会回应")
	elif object_id in ["vines","gate","conductor"]:
		if not label().is_empty(): Events.notice.emit(label())
	elif RunState.discover(object_id):
		Events.effect.emit(global_position-Vector2(0,35),GameData.color(object_id),45,180)

func react_element(element: String) -> bool:
	if object_id=="vines" and element=="fire" and RunState.set_flag("vines"):
		Events.notice.emit("荆棘化为余烬 · 获得余烬琥珀")
		Events.effect.emit(global_position-Vector2(0,110),GameData.color("fire"),65,220)
		return true
	if object_id=="conductor" and element=="lightning" and RunState.set_flag("gate"):
		Events.notice.emit("鸣雷机关已唤醒 · 获得根石护甲")
		Events.effect.emit(global_position-Vector2(0,40),GameData.color("lightning"),60,230)
		Events.sound.emit("discovery")
		return true
	return false

func _draw() -> void:
	var color = GameData.color(object_id)
	var bob: float = sin(clock*2.3+position.x)*3
	var resolved: bool = _flag(object_id)
	if object_id=="camp":
		for side in [-1,1]: draw_line(Vector2(side*17,0),Vector2(-side*12,-10),Color("8d7954"),5,true)
		for i in range(7,0,-1): draw_circle(Vector2(0,-22),i*8,Color(.9,.72,.36,.012))
		draw_colored_polygon(PackedVector2Array([Vector2(-13,-5),Vector2(-9,-22),Vector2(-1,-42+bob),Vector2(4,-17),Vector2(10,-30),Vector2(14,-10),Vector2(5,-3)]),Color("e8c384"))
		draw_line(Vector2(0,-7),Vector2(1,-25),Color("fff0bb"),5,true)
	elif object_id in ["vines","gate"]:
		if resolved:
			draw_line(Vector2(-13,0),Vector2(-17,-22),Color("66805b"),4,true)
			draw_line(Vector2(14,0),Vector2(20,-30),Color("66805b"),3,true)
			return
		color = Color("86a16a") if object_id=="vines" else Color("9486a9")
		for i in 4:
			var x: float = -13+i*8
			draw_polyline(PackedVector2Array([Vector2(x,0),Vector2(x-12,-80),Vector2(x+10,-160),Vector2(x,-270)]),color,5,true)
		for y in range(20,260,32):
			draw_line(Vector2(-18,-y),Vector2(19,-y-15),color.lightened(.1),3,true)
			if object_id=="vines": draw_colored_polygon(PackedVector2Array([Vector2(10,-y),Vector2(31,-y-9),Vector2(21,-y+9)]),color)
	elif object_id=="conductor":
		color = Color("d5bee9") if _flag("gate") else Color("827995")
		draw_colored_polygon(PackedVector2Array([Vector2(-18,0),Vector2(-13,-47),Vector2(0,-61),Vector2(15,-48),Vector2(20,0)]),Color("3f4550"))
		draw_colored_polygon(PackedVector2Array([Vector2(0,-55),Vector2(9,-36),Vector2(0,-17),Vector2(-9,-36)]),color)
	elif object_id.begins_with("portal"):
		draw_arc(Vector2(0,-40),39,PI,TAU,30,Color("9bb68b88"),7,true)
		draw_line(Vector2(-39,-40),Vector2(-39,0),Color("688a71"),7,true)
		draw_line(Vector2(39,-40),Vector2(39,0),Color("688a71"),7,true)
		for i in 5:
			var a: float = clock+i*1.26
			draw_circle(Vector2(cos(a)*22,-38+sin(a)*24),1.7,Color("c6dcb1aa"))
	else:
		if GameData.SUPPLIES.has(object_id): color = Color("dfcea2")
		draw_line(Vector2(-22,0),Vector2(22,0),Color("708365"),3,true)
		for i in range(6,0,-1): draw_circle(Vector2(0,-37+bob),i*8,Color(color,.012))
		if icon: draw_texture_rect(icon,Rect2(-17,-55+bob,34,34),false,color)
		for i in 3:
			var a: float = clock*.7+i*TAU/3
			draw_circle(Vector2(cos(a)*27,-37+sin(a)*17),1.2,color)

func _flag(id: String) -> bool:
	return false if Engine.is_editor_hint() else bool(RunState.data.flags.get(id,false))
