extends Node
## Optional authoring helper: regenerate the six editable scenes from GameData.
## This overwrites scene layout edits. It never runs as part of normal gameplay.
const DATA = preload("res://scripts/core/game_data.gd")
const ROOM = preload("res://scripts/world/room.gd")
const PLATFORM = preload("res://scenes/world/platform.tscn")
const OBJECT = preload("res://scenes/world/interactable.tscn")
const ENEMY = preload("res://scenes/actors/enemy.tscn")
const NAMES = ["moss_garden","sunken_hall","thorn_archive","thunder_depths","moonspore_grotto","ancient_heart"]

func _ready() -> void:
	call_deferred("_bake")

func _bake() -> void:
	for id in 6:
		var root = Node2D.new()
		root.name = NAMES[id].to_pascal_case()
		root.set_script(ROOM)
		root.region_id = id
		var data: Dictionary = DATA.REGIONS[id]
		var geometry = _group(root,"Geometry")
		var objects = _group(root,"Objects")
		var enemies = _group(root,"Enemies")
		for i in data.floor.size():
			var entry: Array = data.floor[i]
			_platform(root,geometry,Vector2(entry[0],590),Vector2(entry[1],300),"Ground"+str(i))
		for i in data.platforms.size():
			var entry: Array = data.platforms[i]
			_platform(root,geometry,Vector2(entry[0],entry[1]),Vector2(entry[2],18),"Ledge"+str(i))
		for i in data.objects.size():
			var entry: Array = data.objects[i]
			var object = OBJECT.instantiate()
			object.object_id = entry[0]
			object.position = Vector2(entry[1],entry[2])
			object.name = str(entry[0]).to_pascal_case()+str(i)
			objects.add_child(object)
			object.owner = root
		if data.has("camp"):
			var camp = OBJECT.instantiate()
			camp.object_id = "camp"
			camp.name = "Campfire"
			camp.position = Vector2(data.camp,590)
			objects.add_child(camp)
			camp.owner = root
		for i in data.enemies.size():
			var entry: Array = data.enemies[i]
			var enemy = ENEMY.instantiate()
			enemy.kind = entry[1]
			enemy.spawn_id = "%d_%d" % [id,i]
			enemy.position = Vector2(entry[0],580)
			enemy.name = "Enemy"+str(i)
			enemies.add_child(enemy)
			enemy.owner = root
		var scene = PackedScene.new()
		assert(scene.pack(root)==OK)
		var path = "res://scenes/world/"+NAMES[id]+".tscn"
		assert(ResourceSaver.save(scene,path)==OK)
		print("Baked "+path)
		root.free()
	get_tree().quit()

func _group(root: Node, title: String) -> Node2D:
	var group = Node2D.new()
	group.name = title
	root.add_child(group)
	group.owner = root
	return group

func _platform(root: Node, group: Node, at: Vector2, size: Vector2, title: String) -> void:
	var platform = PLATFORM.instantiate()
	platform.position = at
	platform.size = size
	platform.name = title
	group.add_child(platform)
	platform.owner = root
