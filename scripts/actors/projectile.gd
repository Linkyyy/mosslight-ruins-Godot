extends Node2D
var kind: String = "arrow"
var motion: Vector2 = Vector2.ZERO
var damage: int = 2
var team: String = "player"
var lifetime: float = 2.0
var clock: float = 0.0
var trail: PackedVector2Array = []
var hit_ids: Dictionary = {}

func configure(type: String, at: Vector2, velocity_value: Vector2, amount: int, faction: String) -> void:
	kind = type
	position = at
	motion = velocity_value
	damage = amount
	team = faction
	lifetime = 1.15 if kind=="bomb" else 2.2

func _physics_process(delta: float) -> void:
	lifetime -= delta
	clock += delta
	if lifetime<=0:
		if kind=="bomb": _explode()
		queue_free()
		return
	if kind=="bomb": motion.y += 1050*delta
	elif kind=="spore": motion.y += 55*delta
	var next = global_position+motion*delta
	var mask: int = 2 if kind=="bomb" else (6+8 if team=="player" else 3)
	var query = PhysicsRayQueryParameters2D.create(global_position,next,mask)
	query.collide_with_areas = true
	var collision = get_world_2d().direct_space_state.intersect_ray(query)
	if not collision.is_empty():
		global_position = collision.position
		if kind=="bomb":
			motion = motion.bounce(collision.normal)*.43
			global_position += collision.normal*3
			if motion.length()<35: motion = Vector2.ZERO
		else:
			var body: Node = collision.collider
			if body.has_method("take_damage"):
				body.take_damage(damage,global_position-motion.normalized()*20,kind,180)
				Events.impact.emit(global_position,GameData.color(kind),.5)
			elif body.has_method("react_element"):
				body.react_element(kind)
			elif body.get_parent() and body.get_parent().has_method("react_element"):
				body.get_parent().react_element(kind)
			Events.effect.emit(global_position,GameData.color(kind),12,90)
			queue_free()
	else:
		global_position = next
	trail.append(global_position)
	if trail.size()>8: trail.remove_at(0)
	queue_redraw()

func _explode() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.global_position.distance_to(global_position)<155:
			enemy.take_damage(5,global_position,"bomb",340)
	var room = get_tree().get_first_node_in_group("room")
	if room: room.apply_element("fire",global_position,true)
	Events.effect.emit(global_position,GameData.color("fire"),60,260)
	Events.impact.emit(global_position,GameData.color("fire"),1.6)
	Events.sound.emit("boom")

func _draw() -> void:
	var color = GameData.color(kind)
	if kind=="spore": color = Color("a9bd8b")
	if trail.size()>1:
		var local = PackedVector2Array()
		for point in trail: local.append(to_local(point))
		draw_polyline(local,Color(color,.3),2 if kind=="arrow" else 5,true)
	if kind=="arrow":
		var direction = motion.normalized()
		draw_line(-direction*17,direction*12,Color("e8e3bc"),2,true)
		draw_line(direction*12,(direction*3).rotated(.5),Color("e8e3bc"),2,true)
	elif kind=="bomb":
		draw_circle(Vector2.ZERO,9,Color("7d8962"))
		draw_arc(Vector2.ZERO,7,0,TAU,16,Color("d5d5a8"),1.5,true)
		draw_line(Vector2(5,-7),Vector2(10,-14),Color("d5c292"),2,true)
		draw_circle(Vector2(10,-14),2+sin(clock*28),Color("f2c084"))
	elif kind=="wave":
		draw_colored_polygon(PackedVector2Array([Vector2(-23,8),Vector2(-10,-12),Vector2(0,-2),Vector2(9,-23),Vector2(24,8)]),Color("c0bb85"))
	else:
		for i in range(4,0,-1): draw_circle(Vector2.ZERO,4+i*4,Color(color,.035))
		draw_circle(Vector2.ZERO,6,color)
		if kind=="ice": draw_polyline(PackedVector2Array([Vector2(0,-12),Vector2(7,0),Vector2(0,12),Vector2(-7,0),Vector2(0,-12)]),color,2,true)
		if kind=="lightning": draw_polyline(PackedVector2Array([Vector2(-20,2),Vector2(-8,-7),Vector2(-2,7),Vector2(12,-5),Vector2(20,0)]),color,2,true)
