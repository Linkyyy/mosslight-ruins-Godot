extends Node
## Real SceneTree, CharacterBody2D, collision queries, input and native Controls.
var failures: Array[String] = []
var checks: int = 0
var started_at: int = 0
var game: Node

func _ready() -> void:
	started_at = Time.get_ticks_msec()
	call_deferred("_run")

func _process(_delta: float) -> void:
	if started_at>0 and Time.get_ticks_msec()-started_at>90000:
		push_error("Regression runner timed out")
		get_tree().quit(2)

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures.append(description)
		push_error("FAIL: "+description)

func frames(count: int = 1) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func tap(action: String, count: int = 2) -> void:
	Input.action_press(action)
	await frames(count)
	Input.action_release(action)
	await frames(1)

func _run() -> void:
	if not SaveStore.is_test_profile:
		push_error("Tests require -- --test-profile to protect the player's save")
		get_tree().quit(2)
		return
	RunState.reset_run()
	game = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game)
	await frames(3)
	check(game.menu.current=="title" and get_tree().paused,"native title pauses world")
	game.start_game(true)
	await frames(8)
	var player: MossPlayer = game.player
	check(player.is_on_floor(),"CharacterBody2D rests on native world collision")
	check(not RunState.unlocked("sword") and not RunState.unlocked("ice") and not RunState.unlocked("heal"),"fresh run starts without weapon, elements or self-heal")
	var mana: float = RunState.data.mana
	check(not player.begin_attack() and not player.begin_cast() and not RunState.heal(),"locked powers cannot execute")
	check(float(RunState.data.mana)==mana,"locked powers spend no mana")
	check(not RunState.equip("sword") and not RunState.select_element("fire"),"equipment and selector cannot bypass discovery")
	var cue: AudioStreamWAV = Audio._make_cue("hit")
	check(cue.mix_rate==22050 and cue.data.size()>1000,"original native audio cue synthesizes valid PCM")
	player.reset_motion(Vector2(530,590))
	await frames(3)
	await tap("interact")
	check(RunState.unlocked("sword") and RunState.data.weapon=="sword","real interaction input picks up sword")
	check(not RunState.discover("sword"),"same discovery cannot be collected twice")
	player.reset_motion(Vector2(430,590))
	await frames(3)
	await tap("interact")
	check(RunState.has_save and int(RunState.data.checkpoint.room)==0,"camp interaction writes native save")
	player.reset_motion(Vector2(450,590))
	await frames(3)
	var before: float = player.position.x
	Input.action_press("move_right")
	await frames(18)
	Input.action_release("move_right")
	check(player.position.x>before+45,"native horizontal acceleration moves player")
	player.reset_motion(Vector2(500,590))
	await frames(3)
	await tap("jump",4)
	check(player.position.y<570 and player.velocity.y<0,"native jump rises after input")
	await frames(40)
	check(player.is_on_floor(),"native gravity returns player to ground")
	# A press just before landing is consumed as a buffered jump.
	player.reset_motion(Vector2(550,570))
	player.velocity.y = 260
	await tap("jump",2)
	await frames(5)
	check(player.velocity.y<0,"jump buffer survives the landing boundary")
	player.reset_motion(Vector2(772,480))
	await frames(4)
	Input.action_press("move_right")
	var attempts: int = 0
	while player.is_on_floor() and attempts<20:
		await frames(1)
		attempts += 1
	await frames(2)
	Input.action_release("move_right")
	await tap("jump",1)
	check(player.velocity.y<0,"coyote time permits a jump shortly after leaving a ledge")
	RunState.discover("fire")
	RunState.discover("heal")
	player.reset_motion(Vector2(510,590))
	await frames(4)
	var target: MossEnemy = load("res://scenes/actors/enemy.tscn").instantiate()
	target.spawn_id = "test_target"
	target.position = Vector2(556,590)
	game.world.add_child(target)
	target.set_physics_process(false)
	target.hp = 50
	target.max_hp = 50
	await frames(4)
	player.attack_cooldown = 0
	player.attack_elapsed = -1
	player.combo_grace = 0
	check(player.begin_attack(),"discovered sword starts an attack")
	await frames(2)
	check(target.hp==50,"sword respects its windup")
	await frames(14)
	check(target.hp==48,"Area2D melee hits once during an active swing")
	await frames(16)
	check(target.hp==48,"same swing cannot repeatedly damage one enemy")
	check(player.begin_attack() and player.combo_stage==1,"second buffered sequence advances combo")
	await frames(24)
	player.attack_cooldown = 0
	check(player.begin_attack() and player.combo_stage==2,"third strike completes the combo")
	await frames(28)
	check(target.hp==42,"three-stage combo deals 2 + 2 + 4 damage")
	RunState.discover("bow")
	check(RunState.equip("bow"),"explored bow is equippable")
	target.position = player.position+Vector2(215,0)
	player.attack_cooldown = 0
	player.attack_elapsed = -1
	await frames(4)
	check(player.begin_attack(),"bow starts a native ranged attack")
	await frames(40)
	check(target.hp==40,"native arrow collision hits a ground enemy at standing height")
	RunState.grant("bomb")
	var bombs: int = RunState.data.inventory.bomb
	check(RunState.use_item("bomb") and RunState.data.inventory.bomb==bombs-1,"using a bomb consumes one and spawns a native projectile")
	for projectile in get_tree().get_nodes_in_group("projectiles"):
		if projectile.kind=="bomb":
			projectile.global_position = target.position-Vector2(0,10)
			projectile.motion = Vector2.ZERO
			projectile.lifetime = .05
	await frames(16)
	check(target.hp==35,"native bomb fuse explodes and deals area damage once")
	target.queue_free()
	RunState.grant("stonevest")
	RunState.equip("stonevest")
	player.invulnerability = 0
	player.guard_cooldown = 0
	RunState.data.hp = 5
	player.take_damage(1,player.position-Vector2(40,0))
	check(RunState.data.hp==5 and player.guard_cooldown>7,"armor blocks once and starts cooldown")
	player.invulnerability = 0
	player.take_damage(1,player.position-Vector2(40,0))
	check(RunState.data.hp==4,"armor cannot block repeatedly during cooldown")
	var old_mana: float = 70
	RunState.data.mana = old_mana
	check(RunState.heal() and RunState.data.hp==5 and float(RunState.data.mana)==25,"discovered heal restores health and spends 45 mana")
	RunState.data.hp = RunState.data.max_hp
	RunState.grant("potion",2)
	var potions: int = RunState.data.inventory.potion
	check(not RunState.use_item("potion") and RunState.data.inventory.potion==potions,"full health preserves consumables")
	RunState.data.hp = 1
	check(RunState.use_item("potion") and RunState.data.hp==4,"consumable heals and decrements once")
	RunState.grant("fiber",3)
	var fiber: int = RunState.data.inventory.fiber
	potions = RunState.data.inventory.potion
	check(RunState.craft("potion") and RunState.data.inventory.fiber==fiber-3 and RunState.data.inventory.potion==potions+1,"crafting atomically consumes recipe materials")
	check(RunState.assign_quick("frost",0),"consumables can be assigned to quick slots")
	game.load_region(1,Vector2(520,590))
	await frames(5)
	await tap("interact")
	check(RunState.unlocked("ice"),"water region offers ice before the hazard")
	check(game.room.apply_element("ice",Vector2(560,590)),"ice affects nearby deep water")
	check(is_instance_valid(game.room.ice_bridge) and game.room.frozen_left>13,"ice bridge is a real temporary StaticBody2D")
	game.room.frozen_left = .04
	await frames(8)
	check(not is_instance_valid(game.room.ice_bridge),"temporary ice bridge expires")
	game.load_region(2,Vector2(850,590))
	await frames(5)
	var vines: WorldObject
	for object in get_tree().get_nodes_in_group("interactables"):
		if object.object_id=="vines": vines = object
	check(vines!=null and vines.blocker.collision_layer==2,"thorn barrier starts as a native solid body")
	check(not vines.react_element("ice"),"wrong element does not open thorns")
	check(vines.react_element("fire") and bool(RunState.data.flags.vines) and RunState.owns("amber"),"fire opens thorns and grants reward")
	check(vines.blocker.collision_layer==0,"opened thorns stop blocking physics")
	check(not vines.react_element("fire"),"barrier rewards are idempotent")
	game.load_region(3,Vector2(390,590))
	await frames(4)
	await tap("interact")
	check(RunState.unlocked("lightning"),"mine offers lightning before conductive water")
	check(game.room.apply_element("lightning",Vector2(520,590)) and bool(RunState.data.flags.gate),"lightning conducts through pool to gate mechanism")
	check(RunState.owns("stonevest"),"gate reward enters inventory")
	game.load_region(4,Vector2(980,330))
	await frames(4)
	await tap("interact")
	check(RunState.completed("moonwing") and RunState.data.max_hp==6,"high chest unlocks permanent double jump and extra health")
	player.reset_motion(Vector2(320,590))
	await frames(3)
	await tap("jump",3)
	await frames(8)
	await tap("jump",2)
	check(player.jumps==2 and player.velocity.y<0,"native player performs unlocked air jump")
	await _menus_and_touch()
	await _boss_and_death()
	_save_and_migration()
	Controls.reset_inputs()
	Engine.time_scale = 1
	get_tree().paused = false
	game.queue_free()
	await frames(3)
	print("NATIVE REGRESSION: "+str(checks-failures.size())+" / "+str(checks)+" checks passed")
	for description in failures: print("FAILED: "+description)
	get_tree().quit(0 if failures.is_empty() else 1)

func _menus_and_touch() -> void:
	game.load_region(0,Vector2(430,590))
	await frames(4)
	var snapshot: String = JSON.stringify(RunState.data)
	for view in ["map","bag","equipment","journal","guide","settings","pause"]:
		game.menu.open_view(view)
		await frames(4)
		check(game.menu.current==view and game.menu.visible and get_tree().paused,"native full-screen view: "+view)
		check(game.menu.size==get_viewport().get_visible_rect().size,"view fills viewport: "+view)
		check(game.menu.body.get_child_count()==1,"view owns one active layout: "+view)
	check(JSON.stringify(RunState.data)==snapshot,"browsing every menu preserves run data")
	var old_size: Vector2i = get_tree().root.size
	for screen_size in [Vector2i(844,390),Vector2i(1280,582)]:
		get_tree().root.size = screen_size
		for view in ["map","bag","equipment","guide"]:
			game.menu.open_view(view)
			await frames(4)
			var layout: Control = game.menu.body.get_child(0)
			check(layout.get_combined_minimum_size().x<=game.menu.body.size.x+1,"layout fits landscape width: "+view+" "+str(screen_size))
			check(game.menu.size==get_viewport().get_visible_rect().size,"shell adapts to native resize: "+view)
	get_tree().root.size = old_size
	await frames(3)
	var position_before: Vector2 = game.player.position
	Input.action_press("move_right")
	await frames(5)
	check(game.player.position==position_before,"paused menu freezes native world physics")
	game.menu.close_view()
	check(not Input.is_action_pressed("move_right"),"closing menu clears held input")
	RunState.settings.touch = true
	await frames(3)
	var touch = game.hud.get_node("TouchControls")
	var stick = InputEventScreenTouch.new()
	stick.index = 11
	stick.pressed = true
	stick.position = Vector2(157,touch.size.y-110)
	touch._input(stick)
	var jump = InputEventScreenTouch.new()
	jump.index = 12
	jump.pressed = true
	jump.position = Vector2(touch.size.x-86,touch.size.y-146)
	touch._input(jump)
	check(Input.is_action_pressed("move_right") and Input.is_action_pressed("jump"),"independent touch fingers move and jump together")
	touch.release_pointer(12)
	check(Input.is_action_pressed("move_right") and not Input.is_action_pressed("jump"),"releasing action finger preserves stick")
	game.menu.open_view("bag")
	check(touch.owners.is_empty() and not Input.is_action_pressed("move_right"),"opening menu cancels captured touch pointers")
	game.menu.close_view()
	RunState.settings.touch = false
	get_tree().root.size = Vector2i(390,844)
	RunState.settings.touch = true
	await frames(4)
	check(game.orientation_paused and get_tree().paused,"portrait touch window pauses gameplay")
	get_tree().root.size = old_size
	await frames(4)
	check(not game.orientation_paused and not get_tree().paused,"return to landscape resumes active gameplay")
	RunState.settings.touch = false
	# Native map transformations and unknown-region selection.
	game.menu.open_view("map")
	await frames(3)
	var map = game.menu.body.find_children("*","MossMapView",true,false)[0]
	var zoom_before: float = map.zoom
	map.zoom_at(1.5,map.size*.5)
	check(map.zoom>zoom_before,"native map zoom changes view transform")
	map.locate()
	check(map.selected==int(RunState.data.room),"map locates current region")
	game.menu.close_view()

func _boss_and_death() -> void:
	game.load_region(5,Vector2(450,590))
	await frames(8)
	var boss: MossEnemy
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.kind=="warden": boss = enemy
	check(boss!=null and boss.active,"native boss wakes when entering arena")
	if boss:
		boss._enter(MossEnemy.State.ALERT,0)
		await frames(3)
		check(boss.state==MossEnemy.State.WINDUP,"boss telegraphs before attacking")
		boss.take_damage(100,game.player.position,"melee")
		check(bool(RunState.data.flags.get("boss",false)) and RunState.owns("thornring"),"boss defeat opens shortcut and grants relic")
	await frames(55)
	if game.menu.visible: game.menu.close_view()
	game.load_region(0,Vector2(430,590))
	await frames(4)
	RunState.equip("cloak")
	RunState.data.hp = 1
	game.player.invulnerability = 0
	game.player.take_damage(1,game.player.position-Vector2(30,0))
	check(game.menu.current=="death" and get_tree().paused,"death presents native recovery screen")
	game.menu.close_view()
	game.menu.open_view("map")
	check(game.menu.current=="death","menu navigation cannot bypass death")
	game.respawn()
	check(RunState.data.hp==RunState.data.max_hp and not get_tree().paused,"respawn returns to checkpoint and resumes")

func _save_and_migration() -> void:
	var original = RunState.data.duplicate(true)
	RunState.data.coins = 10
	check(RunState.save_run(),"atomic save succeeds")
	RunState.data.coins = 20
	check(RunState.save_run(),"second save preserves backup generation")
	var file = FileAccess.open(SaveStore.save_path,FileAccess.WRITE)
	file.store_string("corrupt save")
	file.close()
	var recovered = SaveStore.read_run()
	check(SaveStore.recovered_backup and int(recovered.get("coins",-1))==10,"corrupt primary save recovers verified backup")
	RunState.restore({"room":3,"weapon":"sword","element":"ice","inventory":{"sword":1,"cloak":1},"flags":{"vines":true,"gate":true,"bow":true,"relic":true},"quickItems":["frost","ether","bomb"]})
	check(not RunState.unlocked("sword") and not RunState.unlocked("ice") and not RunState.unlocked("heal"),"legacy defaults do not grant unearned powers")
	check(RunState.unlocked("fire") and RunState.unlocked("lightning") and RunState.unlocked("bow") and RunState.completed("moonwing"),"proven browser discoveries migrate")
	check(RunState.data.room==3 and RunState.data.quick[0]=="frost","migration preserves room and quick slots")
	RunState.restore({"version":3,"room":{},"hp":[],"mana":{},"inventory":{"sword":9,"potion":-2},"position":[{},[]],"discoveries":{"sword":{"fake":true}},"visited":[{},999,-1]})
	check(RunState.data.room==0 and RunState.data.hp==1 and RunState.data.mana==0,"malformed imported numeric fields normalize safely")
	check(not RunState.unlocked("sword") and RunState.data.inventory.potion==0,"malformed flags and negative inventory do not grant powers")
	RunState.restore(original)
	check(RunState.data.get("defeated",{})==original.get("defeated",{}),"native save preserves defeated enemies")
	RunState.save_run()
