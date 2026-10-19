class_name MossRoom
extends Node2D
## Six editor-selectable region scenes use shared, read-only design data.
@export_range(0,5) var region_id: int = 0
const PLATFORM = preload("res://scenes/world/platform.tscn")
const OBJECT = preload("res://scenes/world/interactable.tscn")
const ENEMY = preload("res://scenes/actors/enemy.tscn")
var definition: Dictionary
var ice_bridge: MossTerrain
var frozen_left: float = 0
var clock: float = 0

func _ready() -> void:
	add_to_group("room")
	definition = GameData.region(region_id)
	# Committed scenes have editable native child instances. The fallback also
	# allows a designer or a test to instantiate a room from its data alone.
	if not has_node("Geometry"):
		for segment in definition.floor: _platform(Vector2(segment[0],590),Vector2(segment[1],300))
		for platform in definition.platforms: _platform(Vector2(platform[0],platform[1]),Vector2(platform[2],18))
	if not has_node("Objects"):
		for entry in definition.objects:
			var object: WorldObject = OBJECT.instantiate()
			object.object_id = entry[0]
			object.position = Vector2(entry[1],entry[2])
			add_child(object)
		if definition.has("camp"):
			var camp: WorldObject = OBJECT.instantiate()
			camp.object_id = "camp"
			camp.position = Vector2(definition.camp,590)
			add_child(camp)
	if not has_node("Enemies"):
		for i in definition.enemies.size():
			var entry: Array = definition.enemies[i]
			var enemy: MossEnemy = ENEMY.instantiate()
			enemy.kind = entry[1]
			enemy.spawn_id = "%d_%d" % [region_id,i]
			enemy.position = Vector2(entry[0],580)
			add_child(enemy)

func _platform(at: Vector2, size: Vector2, ice: bool = false) -> MossTerrain:
	var platform: MossTerrain = PLATFORM.instantiate()
	platform.position = at
	platform.size = size
	platform.ice = ice
	add_child(platform)
	return platform

func _physics_process(delta: float) -> void:
	clock += delta
	if frozen_left>0:
		frozen_left -= delta
		if is_instance_valid(ice_bridge):
			ice_bridge.modulate.a = .5+absf(sin(clock*12))*.5 if frozen_left<3 else 1.0
			if frozen_left<=0:
				ice_bridge.queue_free()
				ice_bridge = null
	queue_redraw()

func freeze_water(seconds: float = 14) -> bool:
	if not definition.has("pool"): return false
	frozen_left = seconds
	if not is_instance_valid(ice_bridge):
		var pool: Array = definition.pool
		ice_bridge = _platform(Vector2(pool[0]-4,590),Vector2(pool[1]-pool[0]+8,18),true)
		Events.effect.emit(Vector2((pool[0]+pool[1])*.5,585),GameData.color("ice"),35,170)
	return true

func apply_element(element: String, at: Vector2, blast: bool = false) -> bool:
	var affected: bool = false
	if definition.has("pool"):
		var pool: Array = definition.pool
		var near_pool: bool = at.x>=pool[0]-270 and at.x<=pool[1]+270 and absf(at.y-590)<180
		if near_pool and element=="ice":
			affected = freeze_water()
		if near_pool and element=="lightning":
			affected = true
			Events.effect.emit(Vector2((pool[0]+pool[1])*.5,580),GameData.color("lightning"),50,220)
			for object in get_tree().get_nodes_in_group("interactables"):
				if is_ancestor_of(object) and object.object_id=="conductor": object.react_element("lightning")
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if enemy.global_position.x>pool[0]-100 and enemy.global_position.x<pool[1]+100:
					enemy.take_damage(3,at,"lightning",130)
	if blast:
		for object in get_tree().get_nodes_in_group("interactables"):
			if is_ancestor_of(object) and object.global_position.distance_to(at)<175:
				affected = object.react_element(element) or affected
	return affected

func safe_ground(x: float) -> Vector2:
	if definition.has("pool"):
		var pool: Array = definition.pool
		if x>pool[0]-20 and x<pool[1]+20:
			x = float(pool[0])-65 if x<(pool[0]+pool[1])*.5 else float(pool[1])+65
	return Vector2(clampf(x,45,definition.width-45),590)

func _draw() -> void:
	if definition.is_empty() or not definition.has("pool"): return
	var pool: Array = definition.pool
	draw_rect(Rect2(pool[0],598,pool[1]-pool[0],150),Color("326a7299"))
	var points = PackedVector2Array()
	for x in range(int(pool[0]),int(pool[1])+5,8):
		points.append(Vector2(x,596+sin(x*.035+clock*2)*2))
	draw_polyline(points,Color("86bab599"),2,true)
	for i in 9:
		var x = lerpf(pool[0],pool[1],float(i)/9)
		draw_circle(Vector2(x,625+sin(clock+i)*13),1.6,Color("9dc5b940"))
	if frozen_left>0:
		draw_string(UI.font(),Vector2((pool[0]+pool[1])*.5-40,566),str(ceili(frozen_left))+" s",HORIZONTAL_ALIGNMENT_CENTER,80,19,Color("d0e7d5"))
