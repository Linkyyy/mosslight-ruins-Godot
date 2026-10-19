@tool
class_name MossEnemy
extends CharacterBody2D
## Explicit, telegraphed state machine; status effects interrupt the same states.
enum State {PATROL, ALERT, WINDUP, ATTACK, RECOVER, STUN, DEAD}
@export_enum("crawler","spore","warden") var kind: String = "crawler"
@export var spawn_id: String = ""
var state: State = State.PATROL
var hp: int = 6
var max_hp: int = 6
var facing: int = -1
var clock: float = 0
var timer: float = 0
var hurt_time: float = 0
var freeze_time: float = 0
var burn_time: float = 0
var burn_tick: float = 0
var home_x: float = 0
var hit_player: bool = false
var active: bool = false
var pattern: int = 0
var fired: bool = false
var player: MossPlayer

func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	if bool(RunState.data.get("defeated",{}).get(spawn_id,false)) or (kind=="warden" and bool(RunState.data.flags.get("boss",false))):
		queue_free()
		return
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player") as MossPlayer
	home_x = position.x
	max_hp = 54 if kind=="warden" else (7 if kind=="spore" else 6)
	hp = max_hp
	if kind=="warden":
		var shape = RectangleShape2D.new()
		shape.size = Vector2(88,118)
		$Collision.shape = shape
		$Collision.position.y = -59
	floor_snap_length = 10

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	clock += delta
	hurt_time = maxf(0,hurt_time-delta)
	if state==State.DEAD:
		timer -= delta
		modulate.a = maxf(0,timer/.55)
		scale = Vector2(1+(1-timer/.55)*.22, maxf(.05,timer/.55))
		if timer<=0: queue_free()
		return
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as MossPlayer
		return
	if burn_time>0:
		burn_time -= delta
		burn_tick -= delta
		if burn_tick<=0:
			burn_tick = .65
			take_damage(1,global_position-Vector2(facing,0),"burn",0)
	if state==State.DEAD: return
	if freeze_time>0:
		freeze_time -= delta
		velocity.x = move_toward(velocity.x,0,delta*700)
		velocity.y += 1650*delta
		move_and_slide()
		queue_redraw()
		return
	timer -= delta
	var dx: float = player.global_position.x-global_position.x
	var distance: float = absf(dx)
	var dy: float = absf(player.global_position.y-global_position.y)
	if kind=="warden":
		_boss_tick(delta,dx,distance)
	else:
		_small_tick(delta,dx,distance,dy)
	velocity.y = minf(1000,velocity.y+1650*delta)
	move_and_slide()
	if state==State.ATTACK and not hit_player and dy<80 and distance<(85 if kind=="warden" else 43):
		hit_player = player.take_damage(1,global_position,"enemy",280)
	if global_position.y>820:
		global_position = Vector2(home_x,560)
		velocity = Vector2.ZERO
	queue_redraw()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): queue_redraw()

func _small_tick(delta: float, dx: float, distance: float, dy: float) -> void:
	match state:
		State.PATROL:
			velocity.x = facing*38
			if absf(position.x-home_x)>95 or _at_ledge(): facing *= -1
			if distance<300 and dy<160:
				facing = 1 if dx>0 else -1
				_enter(State.ALERT,.38)
		State.ALERT:
			facing = 1 if dx>0 else -1
			velocity.x = move_toward(velocity.x,0,delta*900)
			if timer<=0: _enter(State.WINDUP,.62 if kind=="spore" else .48)
		State.WINDUP:
			velocity.x = 0
			if timer<=0:
				_enter(State.ATTACK,.42)
				if kind=="spore":
					var aim = (player.global_position+Vector2(0,-25)-(global_position+Vector2(0,-28))).normalized()*300
					_fire("spore",aim,1)
		State.ATTACK:
			velocity.x = facing*(65 if kind=="spore" else 310)
			if _at_ledge(): velocity.x = 0
			if timer<=0: _enter(State.RECOVER,.85)
		State.RECOVER:
			velocity.x = move_toward(velocity.x,0,delta*800)
			if timer<=0:
				if distance<310 and dy<160: _enter(State.ALERT,.2)
				else: _enter(State.PATROL,1)
		State.STUN:
			velocity.x = move_toward(velocity.x,0,delta*450)
			if timer<=0: _enter(State.RECOVER,.35)

func _boss_tick(delta: float, dx: float, distance: float) -> void:
	if not active:
		velocity.x = 0
		if player.global_position.x>410:
			active = true
			_enter(State.ALERT,1.2)
			Events.notice.emit("根骸守卫 · 留意它的蓄力")
			Events.boss_health.emit(hp,max_hp)
		return
	match state:
		State.PATROL, State.ALERT:
			facing = 1 if dx>0 else -1
			velocity.x = move_toward(velocity.x,0,delta*1000)
			if timer<=0:
				pattern = (pattern+1)%3
				_enter(State.WINDUP,.85 if hp>max_hp/2 else .62)
		State.WINDUP:
			velocity.x = 0
			if timer<=0:
				_enter(State.ATTACK,.75 if pattern==0 else .4)
				if pattern==1:
					_fire("wave",Vector2(-410,0),1,Vector2(0,-18))
					_fire("wave",Vector2(410,0),1,Vector2(0,-18))
					Events.impact.emit(global_position,Color("d8c58f"),1.5)
				elif pattern==2:
					for angle in [-.2,0.0,.2]: _fire("spore",Vector2(facing*350,0).rotated(angle),1,Vector2(0,-62))
		State.ATTACK:
			velocity.x = facing*650 if pattern==0 else 0.0
			if position.x<260 or position.x>1430 or timer<=0: _enter(State.RECOVER,1.1 if hp>max_hp/2 else .72)
		State.RECOVER:
			velocity.x = move_toward(velocity.x,0,delta*1200)
			if timer<=0: _enter(State.ALERT,.2)
		State.STUN:
			velocity.x = move_toward(velocity.x,0,delta*800)
			if timer<=0: _enter(State.RECOVER,.35)

func _at_ledge() -> bool:
	if not is_on_floor(): return false
	var from = global_position+Vector2(facing*33,-6)
	var query = PhysicsRayQueryParameters2D.create(from,from+Vector2(0,46),2)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _enter(next: State, duration: float) -> void:
	state = next
	timer = duration
	hit_player = false

func _fire(type: String, motion: Vector2, damage: int, offset: Vector2 = Vector2(0,-28)) -> void:
	var game = get_tree().get_first_node_in_group("game")
	if game: game.spawn_projectile(type,global_position+offset,motion,damage,"enemy")

func take_damage(amount: int, source: Vector2, element: String = "", force: float = 180) -> bool:
	if state==State.DEAD: return false
	if kind=="warden" and not active: return false
	hp = maxi(0,hp-amount)
	hurt_time = .18
	var direction: float = signf(global_position.x-source.x)
	velocity.x = direction*force*(.25 if kind=="warden" else 1.0)
	if element=="fire": burn_time = 2.2
	if element=="ice": freeze_time = .65 if kind=="warden" else 2.0
	if element=="lightning": _enter(State.STUN,.18 if kind=="warden" else .65)
	elif kind!="warden" and element!="burn": _enter(State.STUN,.26)
	Events.effect.emit(global_position-Vector2(0,24),GameData.color(element),12,110)
	Events.damage_number.emit(global_position-Vector2(0,45),amount,GameData.color(element))
	Events.sound.emit("hit")
	if kind=="warden": Events.boss_health.emit(hp,max_hp)
	if hp<=0: _die()
	return true

func _die() -> void:
	_enter(State.DEAD,.55)
	set_collision_layer_value(3,false)
	if not RunState.data.has("defeated"): RunState.data.defeated = {}
	RunState.data.defeated[spawn_id] = true
	RunState.record_kill()
	if kind=="warden":
		RunState.set_flag("boss")
		Events.boss_health.emit(0,max_hp)
		Events.victory.emit()
	RunState.save_run()
	Events.effect.emit(global_position-Vector2(0,35),Color("d8d5a5"),32,170)

func _draw() -> void:
	var flash: bool = hurt_time>0
	var tone = Color("78955b") if kind!="spore" else Color("88afa1")
	if freeze_time>0: tone = Color("a6dce0")
	if flash: tone = tone.lerp(Color("faf0ce"),.85)
	if kind=="warden":
		_draw_boss(tone)
		return
	var squash: float = .12*sin(clock*4) + (.22 if state==State.WINDUP else 0.0)
	draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
	draw_set_transform(Vector2(0,-14),0,Vector2(facing*(1+squash),1-squash*.5))
	draw_circle(Vector2.ZERO,20,tone)
	draw_colored_polygon(PackedVector2Array([Vector2(-23,4),Vector2(-17,-12),Vector2(11,-17),Vector2(24,7),Vector2(6,14),Vector2(-18,12)]),tone.darkened(.12))
	for i in 4:
		var x: float = -16+i*10
		draw_line(Vector2(x,8),Vector2(x+sin(clock*9+i)*4,15),tone.darkened(.25),4,true)
	if kind=="spore":
		draw_arc(Vector2(0,-15),25,PI,TAU,16,tone.lightened(.17),8,true)
		for x in [-12,0,13]: draw_circle(Vector2(x,-29+abs(x)*.35),2.2,Color("d3e5ca"))
	else:
		draw_line(Vector2(-7,-12),Vector2(-12,-28),tone.lightened(.3),2,true)
		draw_line(Vector2(6,-15),Vector2(13,-31),tone.lightened(.3),2,true)
	draw_circle(Vector2(8,-6),2.6,Color("ecedbe") if state!=State.WINDUP else Color("ffe0a6"))
	draw_set_transform(Vector2.ZERO)
	if state in [State.ALERT,State.WINDUP]:
		draw_string(ThemeDB.fallback_font,Vector2(-4,-53),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("f2dba9"))
	if hp<max_hp:
		draw_line(Vector2(-20,-42),Vector2(20,-42),Color("223f35"),3)
		draw_line(Vector2(-20,-42),Vector2(-20+40*float(hp)/max_hp,-42),Color("d4dca8"),3)

func _draw_boss(tone: Color) -> void:
	var wind: bool = state==State.WINDUP
	var stride: float = sin(clock*(18 if state==State.ATTACK else 3))*8
	draw_set_transform(Vector2(0,-50),.1*facing if state==State.ATTACK else 0,Vector2(facing,1))
	draw_line(Vector2(-25,24),Vector2(-35-stride,50),Color("344d36"),20,true)
	draw_line(Vector2(25,24),Vector2(36+stride,50),Color("344d36"),20,true)
	draw_colored_polygon(PackedVector2Array([Vector2(-49,17),Vector2(-45,-38),Vector2(-22,-62),Vector2(20,-62),Vector2(47,-35),Vector2(52,20),Vector2(0,37)]),tone.darkened(.18))
	draw_colored_polygon(PackedVector2Array([Vector2(-24,-50),Vector2(-30,-83),Vector2(-10,-72),Vector2(0,-103),Vector2(10,-73),Vector2(30,-88),Vector2(25,-50)]),tone)
	for x in [-19,12]: draw_rect(Rect2(x,-44,10,7),Color("ffe2a3") if wind else Color("d3e2ab"))
	for side in [-1,1]:
		var hand_y: float = -30 if wind else 25+stride*.3
		draw_line(Vector2(side*42,-25),Vector2(side*70,hand_y),tone,16,true)
		draw_line(Vector2(side*70,hand_y),Vector2(side*86,hand_y+35),Color("bdc38f"),3,true)
	draw_set_transform(Vector2.ZERO)
	if wind:
		draw_arc(Vector2(0,-62),91,PI*.85,PI*2.15,36,Color("efcc8ea0"),2,true)
		draw_string(ThemeDB.fallback_font,Vector2(-7,-173),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("f0d09a"))
		if pattern==0:
			draw_line(Vector2(0,-5),Vector2(facing*500,-5),Color("dfba6d55"),8,true)
