class_name TravelerArt
extends RefCounted
## Original vector rig. The same rig drives gameplay and the equipment portrait.

static func draw_rig(canvas: CanvasItem, origin: Vector2, zoom: float, pose: Dictionary) -> void:
	var clock: float = pose.get("clock",0.0)
	var facing: float = pose.get("facing",1.0)
	var speed: float = pose.get("speed",0.0)
	var air: bool = pose.get("air",false)
	var hurt: float = pose.get("hurt",0.0)
	var landing: float = pose.get("landing",0.0)
	var phase: float = clock*13.0
	var stride: float = sin(phase)*minf(1,absf(speed)/220)
	var bob: float = absf(sin(phase))*2.5*minf(1,absf(speed)/220) + sin(clock*2.3)*0.7
	var ink = Color("e7e9c6").lerp(Color.WHITE,clampf(hurt*5,0,1))
	var tunic = Color("587d64").lerp(Color("ecedcb"),clampf(hurt*4,0,0.8))
	canvas.draw_set_transform(origin,0,Vector2(zoom,zoom*0.24))
	canvas.draw_circle(Vector2.ZERO,23,Color(0.015,0.07,0.06,0.45))
	canvas.draw_set_transform(origin+Vector2(0,-bob)*zoom,0,Vector2(facing*zoom*(1+landing*0.18),zoom*(1-landing*0.14)))
	# Feet move independently; the root remains tied to the native physics body.
	var left_foot = Vector2(-9+stride*9,-2-(maxf(0,stride)*7 if not air else 7))
	var right_foot = Vector2(9-stride*9,-2-(maxf(0,-stride)*7 if not air else 2))
	canvas.draw_line(Vector2(-8,-27),left_foot,Color("284f43"),8,true)
	canvas.draw_line(Vector2(8,-27),right_foot,Color("24483f"),8,true)
	canvas.draw_line(left_foot-Vector2(4,0),left_foot+Vector2(7,0),ink,5,true)
	canvas.draw_line(right_foot-Vector2(4,0),right_foot+Vector2(7,0),ink,5,true)
	# A three-segment scarf trails behind the current motion.
	var scarf_wave: float = sin(clock*8)*3+minf(1,absf(speed)/250)*5
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-8,-57),Vector2(-35,-59+scarf_wave),Vector2(-49,-48+scarf_wave*1.4),Vector2(-31,-49),Vector2(-50,-32+scarf_wave),Vector2(-23,-42),Vector2(-5,-49)]),Color("c18b5d"))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-16,-54),Vector2(13,-54),Vector2(23,-14),Vector2(-20,-13),Vector2(-26,-24)]),tunic)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-16,-54),Vector2(-4,-42),Vector2(-18,-15),Vector2(-26,-24)]),Color("3b6450"))
	canvas.draw_line(Vector2(-21,-25),Vector2(21,-25),Color("c0b683"),3,true)
	canvas.draw_rect(Rect2(-2,-28,5,7),Color("e6d9a8"))
	var arm_back = Vector2(-23-stride*5,-31+stride*5)
	canvas.draw_line(Vector2(-16,-50),arm_back,ink,6,true)
	var hand = Vector2(20,-32)
	if pose.get("casting",false): hand = Vector2(29,-45)
	canvas.draw_line(Vector2(13,-50),hand,ink,6,true)
	# Face, moss cap, eyes and a small wind-driven leaf.
	canvas.draw_circle(Vector2(0,-70),20,ink)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-21,-69),Vector2(-20,-88),Vector2(-8,-99),Vector2(13,-96),Vector2(25,-78),Vector2(13,-81),Vector2(5,-88),Vector2(-15,-87),Vector2(-17,-69)]),Color("6c8951"))
	canvas.draw_line(Vector2(-5,-97),Vector2(-3+sin(clock*2)*2,-113),Color("b4cf7c"),3,true)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-3,-110),Vector2(9+sin(clock*2)*2,-120),Vector2(20,-115),Vector2(9,-104)]),Color("b4cf7c"))
	var blinking: bool = fmod(clock,4.2)>4.05
	for x in [3.0,14.0]:
		canvas.draw_line(Vector2(x,-73),Vector2(x,-72 if blinking else -67),Color("294c3e"),2.5,true)
	canvas.draw_line(Vector2(7,-61),Vector2(11,-61),Color("809575"),1,true)
	canvas.draw_line(Vector2(-17,-52),Vector2(19,-52),Color("ce9765"),8,true)
	var weapon: String = pose.get("weapon","")
	var attack: float = pose.get("attack",-1.0)
	if weapon == "sword":
		var angle: float = -0.25
		if attack >= 0:
			angle = lerpf(-2.2,1.8,smoothstep(0.1,0.8,attack))
		var blade = PackedVector2Array()
		for point in [Vector2(-2,0),Vector2(-2,-42),Vector2(2,-52),Vector2(6,-42),Vector2(3,0)]:
			blade.append(hand+point.rotated(angle))
		canvas.draw_colored_polygon(blade,Color("ecebc7"))
		canvas.draw_line(hand+Vector2(-8,0).rotated(angle),hand+Vector2(10,0).rotated(angle),Color("ae9f69"),3,true)
		canvas.draw_line(hand,hand+Vector2(0,12).rotated(angle),Color("847747"),4,true)
	elif weapon == "bow":
		canvas.draw_arc(hand+Vector2(0,-8),23,-1.3,1.3,14,Color("c0c18a"),3,true)
		canvas.draw_line(hand+Vector2(6,-30),hand+Vector2(6,14),Color("e0dfb9"),1,true)
	if pose.get("casting",false):
		var color: Color = pose.get("cast_color",Color("c0dfda"))
		canvas.draw_circle(hand,10+sin(clock*19)*2,Color(color,0.15))
		canvas.draw_arc(hand,14,clock*3,clock*3+4.5,20,color,1.5,true)
	canvas.draw_set_transform(Vector2.ZERO)
