extends Node2D
## Scene coordinator. World nodes pause; native menus and lifecycle keep running.
const ROOMS = [preload("res://scenes/world/moss_garden.tscn"),preload("res://scenes/world/sunken_hall.tscn"),preload("res://scenes/world/thorn_archive.tscn"),preload("res://scenes/world/thunder_depths.tscn"),preload("res://scenes/world/moonspore_grotto.tscn"),preload("res://scenes/world/ancient_heart.tscn")]
const PROJECTILE = preload("res://scenes/actors/projectile.tscn")
var started: bool = false
var orientation_paused: bool = false
var room: MossRoom
var near: WorldObject
var transition_cooldown: float = 0.0
var trauma: float = 0.0
var hit_stop_until: int = 0
var autosave_timer: float = 0.0
@onready var world: Node2D = $World
@onready var player: MossPlayer = $World/Player
@onready var camera: Camera2D = $World/Camera
@onready var atmosphere: Node2D = $World/Atmosphere
@onready var effects: Node2D = $World/Effects
@onready var hud: Control = $HUDCanvas/HUD
@onready var menu: Control = $MenuCanvas/GameMenu
@onready var rotate: Control = $RotateCanvas/Rotate

func _ready() -> void:
	add_to_group("game")
	get_tree().auto_accept_quit = false
	menu.game = self
	hud.game = self
	player.shot.connect(spawn_projectile)
	player.element_released.connect(func(kind: String,at: Vector2): room.apply_element(kind,at))
	Events.transition_requested.connect(load_region)
	Events.player_died.connect(func(): menu.open_view("death"))
	Events.victory.connect(_show_victory)
	Events.impact.connect(_impact)
	Events.item_used.connect(_item_used)
	var rotate_center = CenterContainer.new()
	rotate.add_child(rotate_center)
	rotate_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column = UI.column(25)
	rotate_center.add_child(column)
	column.add_child(UI.texture("fullscreen",Vector2(110,110)))
	column.add_child(UI.label("将设备横过来",38))
	column.add_child(UI.label("更宽阔的遗境，等待你的探索。",22,UI.MUTED))
	rotate.visible = false
	load_region(int(RunState.data.room),Vector2(RunState.data.position[0],RunState.data.position[1]))
	menu.open_view("title")
	hud.visible = false
	if "--autostart" in OS.get_cmdline_user_args(): start_game("--fresh" in OS.get_cmdline_user_args())

func start_game(fresh: bool = false) -> void:
	if fresh: RunState.reset_run()
	started = true
	load_region(int(RunState.data.room),Vector2(RunState.data.position[0],RunState.data.position[1]))
	menu.current = ""
	menu.hide()
	hud.show()
	get_tree().paused = orientation_paused
	Controls.reset_inputs()
	hud.show_region()
	Events.notice.emit("靠近微光遗物后互动 · 从庭院旧路开始探索")
	RunState.save_run()

func load_region(id: int, spawn: Vector2) -> void:
	if id<0 or id>5: return
	near = null
	if is_instance_valid(room):
		world.remove_child(room)
		room.queue_free()
	for node in get_tree().get_nodes_in_group("projectiles"): node.queue_free()
	effects.clear()
	RunState.data.room = id
	RunState.data.position = [spawn.x,spawn.y]
	if not id in RunState.data.visited: RunState.data.visited.append(id)
	room = ROOMS[id].instantiate()
	world.add_child(room)
	player.reset_motion(spawn)
	camera.position = Vector2(_camera_target(),360)
	atmosphere.region_id = id
	transition_cooldown = .7
	RunState.changed.emit()
	hud.show_region()
	if started: RunState.save_run()

func _camera_target() -> float:
	var width: float = get_viewport_rect().size.x
	var room_width: float = GameData.region(int(RunState.data.room)).width
	return room_width*.5 if width>=room_width else clampf(player.position.x+player.facing*70,width*.5,room_width-width*.5)

func _physics_process(delta: float) -> void:
	if get_tree().paused or not started or not is_instance_valid(room): return
	transition_cooldown = maxf(0,transition_cooldown-delta)
	var data = room.definition
	if player.position.y>800:
		player.invulnerability = 0
		player.take_damage(1,player.position+Vector2(0,20),"fall")
		if int(RunState.data.hp)>0: player.reset_motion(room.safe_ground(player.position.x))
		return
	if transition_cooldown<=0:
		if player.position.x>float(data.width)-15 and int(data.right)>=0:
			load_region(int(data.right),Vector2(50,590))
			return
		if player.position.x<15 and int(data.left)>=0:
			var previous: int = int(data.left)
			load_region(previous,Vector2(float(GameData.region(previous).width)-55,590))
			return
	player.position.x = clampf(player.position.x,8,float(data.width)-8)
	camera.position.x = lerpf(camera.position.x,_camera_target(),1-exp(-delta*7))
	save_position()
	near = null
	var best: float = 92
	for object in get_tree().get_nodes_in_group("interactables"):
		if object.is_queued_for_deletion() or object.label().is_empty(): continue
		var distance: float = player.global_position.distance_to(object.global_position)
		if distance<best:
			best = distance
			near = object
	if Input.is_action_just_pressed("interact") and is_instance_valid(near): near.interact(player)
	if Input.is_action_just_pressed("cycle_weapon"): RunState.cycle_weapon()
	if Input.is_action_just_pressed("weapon_sword"): RunState.equip("sword")
	if Input.is_action_just_pressed("weapon_bow"): RunState.equip("bow")
	if Input.is_action_just_pressed("cycle_element"): RunState.cycle_element()
	for i in 3:
		if Input.is_action_just_pressed("quick_"+str(i+1)): RunState.use_item(str(RunState.data.quick[i]))
	autosave_timer += delta
	if autosave_timer>30 and player.is_on_floor():
		RunState.save_run()
		autosave_timer = 0

func _process(delta: float) -> void:
	if hit_stop_until>0 and Time.get_ticks_msec()>=hit_stop_until:
		Engine.time_scale = 1
		hit_stop_until = 0
	if not is_node_ready(): return
	trauma = maxf(0,trauma-delta*3)
	camera.offset = Vector2(randf_range(-1,1),randf_range(-1,1))*trauma*7 if bool(RunState.settings.shake) else Vector2.ZERO
	var viewport_size = get_viewport_rect().size
	atmosphere.view_size = viewport_size
	atmosphere.camera_x = camera.position.x
	atmosphere.position = Vector2(camera.position.x-viewport_size.x*.5,0)
	var portrait: bool = Controls.touch_enabled() and viewport_size.y>viewport_size.x
	if portrait and not orientation_paused:
		orientation_paused = true
		get_tree().paused = true
		Controls.reset_inputs()
		rotate.show()
	elif not portrait and orientation_paused:
		orientation_paused = false
		rotate.hide()
		get_tree().paused = menu.visible or not started

func save_position() -> void:
	if is_instance_valid(player) and int(RunState.data.hp)>0:
		RunState.data.position = [player.position.x,clampf(player.position.y,80,590)]

func _impact(_at: Vector2, _color: Color, strength: float) -> void:
	trauma = maxf(trauma,minf(1.8,strength))
	if not get_tree().paused:
		hit_stop_until = Time.get_ticks_msec()+45
		Engine.time_scale = .14

func spawn_projectile(kind: String, at: Vector2, motion: Vector2, damage: int, team: String) -> Node2D:
	var projectile = PROJECTILE.instantiate()
	projectile.configure(kind,at,motion,damage,team)
	projectile.add_to_group("projectiles")
	projectile.z_index = 10
	world.add_child(projectile)
	return projectile

func _item_used(id: String) -> void:
	if not started: return
	if menu.visible and menu.current!="death": menu.close_view()
	if id=="bomb": spawn_projectile("bomb",player.position+Vector2(0,-35),Vector2(player.facing*300,-280),5,"player")
	elif id=="frost":
		room.apply_element("ice",player.position)
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.position.distance_to(player.position)<225: enemy.take_damage(1,player.position,"ice",50)
	Events.effect.emit(player.position-Vector2(0,25),GameData.color("ice" if id=="frost" else "heal"),32,120)
	Events.sound.emit("pickup")

func respawn() -> void:
	RunState.respawn()
	load_region(int(RunState.data.room),Vector2(RunState.data.position[0],RunState.data.position[1]))
	menu.current = ""
	menu.hide()
	get_tree().paused = orientation_paused
	Controls.reset_inputs()

func _show_victory() -> void:
	await get_tree().create_timer(.7).timeout
	if started and int(RunState.data.hp)>0 and bool(RunState.data.flags.get("boss",false)):
		menu.open_view("victory")

func quit_to_title() -> void:
	save_position()
	RunState.save_run()
	started = false
	hud.hide()
	menu.open_view("title")

func toggle_fullscreen() -> void:
	if DisplayServer.get_name()=="headless": return
	var full: bool = DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
	RunState.settings.fullscreen = not full
	RunState.save_settings()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()
	if menu.visible or not started: return
	for entry in [["pause","pause"],["map","map"],["bag","bag"],["equipment","equipment"],["guide","guide"]]:
		if event.is_action_pressed(entry[0]):
			menu.open_view(entry[1])
			get_viewport().set_input_as_handled()
			return

func _notification(what: int) -> void:
	if not is_node_ready(): return
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		Controls.reset_inputs()
		if started and int(RunState.data.hp)>0:
			save_position()
			RunState.save_run()
			if not menu.visible: menu.open_view("pause")
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		if started and int(RunState.data.hp)>0:
			save_position()
			RunState.save_run()
		get_tree().quit()
