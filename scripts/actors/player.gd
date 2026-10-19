class_name MossPlayer
extends CharacterBody2D
signal shot(kind: String, at: Vector2, motion: Vector2, damage: int, team: String)
signal element_released(kind: String, at: Vector2)

const SPEED = 260.0
const GRAVITY = 1650.0
const JUMP_SPEED = -650.0
var facing: int = 1
var clock: float = 0.0
var coyote: float = 0.0
var jump_buffer: float = 0.0
var jumps: int = 0
var invulnerability: float = 1.0
var guard_cooldown: float = 0.0
var hurt_timer: float = 0.0
var landing: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown: float = 0.0
var attack_elapsed: float = -1.0
var attack_cooldown: float = 0.0
var attack_buffer: float = 0.0
var combo_stage: int = 0
var combo_grace: float = 0.0
var cast_elapsed: float = -1.0
var cast_kind: String = ""
var cast_cooldown: float = 0.0
var cast_fired: bool = false
var bow_fired: bool = false
var swing_hits: Dictionary = {}
var step_clock: float = 0.0
@onready var melee: Area2D = $Melee

func _ready() -> void:
	add_to_group("player")
	floor_snap_length = 10

func _physics_process(delta: float) -> void:
	clock += delta
	for key in ["coyote","jump_buffer","invulnerability","guard_cooldown","hurt_timer","dash_cooldown","attack_cooldown","attack_buffer","combo_grace","cast_cooldown"]:
		set(key,maxf(0.0,float(get(key))-delta))
	landing = move_toward(landing,0,delta*6)
	RunState.data.mana = minf(100.0,float(RunState.data.mana)+delta*5.5)
	if int(RunState.data.hp) <= 0:
		return
	var direction: float = Input.get_axis("move_left","move_right")
	if absf(direction)>0.18 and attack_elapsed<0 and cast_elapsed<0:
		facing = 1 if direction>0 else -1
	var was_grounded: bool = is_on_floor()
	if was_grounded:
		coyote = 0.12
		jumps = 0
	if Input.is_action_just_pressed("jump"):
		jump_buffer = 0.14
	if jump_buffer>0 and (coyote>0 or (RunState.completed("moonwing") and jumps<2)):
		_jump()
	if Input.is_action_just_released("jump") and velocity.y < -240:
		velocity.y *= 0.52
	if Input.is_action_just_pressed("attack"):
		attack_buffer = 0.18
	if attack_buffer>0 and attack_cooldown<=0 and dash_timer<=0 and cast_elapsed<0:
		begin_attack()
	if Input.is_action_just_pressed("cast"):
		begin_cast()
	if Input.is_action_just_pressed("dash"):
		begin_dash()
	if Input.is_action_just_pressed("heal"):
		RunState.heal()
	if dash_timer>0:
		dash_timer -= delta
		velocity = Vector2(facing*700.0,0)
		if int(clock*65)%3 == 0:
			Events.effect.emit(global_position-Vector2(0,35),Color("c9dec2"),1,15)
	else:
		velocity.y = minf(1000,velocity.y+GRAVITY*delta)
		var maximum: float = SPEED*float(RunState.stats().speed)
		if attack_elapsed>=0 or cast_elapsed>=0:
			maximum *= 0.34
		if hurt_timer<=0:
			velocity.x = move_toward(velocity.x,direction*maximum,delta*(2300 if direction else 2900))
		else:
			velocity.x = move_toward(velocity.x,0,delta*500)
	melee.position.x = facing*54
	_combat_tick(delta)
	move_and_slide()
	if is_on_floor() and not was_grounded and velocity.y>=0:
		landing = 1.0
		Events.effect.emit(global_position,Color("a3b990"),9,65)
		Events.sound.emit("land")
	if is_on_floor() and absf(velocity.x)>80:
		step_clock += delta
		if step_clock>.24:
			step_clock = 0
			Events.sound.emit("step")
	queue_redraw()

func _jump() -> void:
	jumps = 1 if coyote>0 else maxi(1,jumps)+1
	velocity.y = JUMP_SPEED if jumps==1 else JUMP_SPEED*0.92
	coyote = 0
	jump_buffer = 0
	Events.effect.emit(global_position,Color("c3d4a8"),11,70)
	Events.sound.emit("jump")

func begin_dash() -> bool:
	if dash_cooldown>0 or hurt_timer>0 or not RunState.spend_mana(8):
		return false
	dash_timer = .16
	dash_cooldown = .65
	invulnerability = maxf(invulnerability,.2)
	attack_elapsed = -1
	cast_elapsed = -1
	Events.sound.emit("dash")
	return true

func begin_attack() -> bool:
	var weapon: String = RunState.data.weapon
	if not RunState.unlocked(weapon):
		Events.notice.emit("先在庭院拾得旅者短刃")
		attack_buffer = 0
		return false
	if attack_cooldown>0:
		return false
	combo_stage = (combo_stage+1)%3 if combo_grace>0 else 0
	combo_grace = 1.0
	attack_buffer = 0
	attack_elapsed = 0
	attack_cooldown = .5 if combo_stage==2 else .34
	bow_fired = false
	swing_hits.clear()
	Events.sound.emit("swing")
	return true

func begin_cast() -> bool:
	if cast_cooldown>0 or attack_elapsed>=0 or dash_timer>0:
		return false
	cast_kind = str(RunState.data.element)
	if not RunState.unlocked(cast_kind):
		Events.notice.emit("元素之力需要探索唤醒")
		return false
	if not RunState.spend_mana(18):
		Events.notice.emit("灵息不足")
		return false
	cast_elapsed = 0
	cast_cooldown = .58
	cast_fired = false
	Events.sound.emit("cast")
	return true

func _combat_tick(delta: float) -> void:
	if attack_elapsed>=0:
		attack_elapsed += delta
		if RunState.data.weapon == "bow":
			if attack_elapsed>=.15 and not bow_fired:
				bow_fired = true
				shot.emit("arrow",global_position+Vector2(facing*26,-27),Vector2(facing*690,0),2+int(RunState.stats().damage),"player")
		else:
			var windup: float = .16 if combo_stage==2 else .07
			if attack_elapsed>=windup and attack_elapsed<=windup+.12:
				for body in melee.get_overlapping_bodies():
					if body.has_method("take_damage") and not swing_hits.has(body.get_instance_id()):
						swing_hits[body.get_instance_id()] = true
						body.take_damage((4 if combo_stage==2 else 2)+int(RunState.stats().damage),global_position,"melee",360 if combo_stage==2 else 180)
						Events.impact.emit(body.global_position-Vector2(0,20),Color("f3ddb1"),1.35 if combo_stage==2 else .65)
		if attack_elapsed>=attack_cooldown+.28 or attack_elapsed>=.45:
			attack_elapsed = -1
	if cast_elapsed>=0:
		cast_elapsed += delta
		if cast_elapsed>=.12 and not cast_fired:
			cast_fired = true
			var at = global_position+Vector2(facing*30,-27)
			shot.emit(cast_kind,at,Vector2(facing*550,0),3+int(RunState.stats().element),"player")
			element_released.emit(cast_kind,global_position)
			Events.effect.emit(at,GameData.color(cast_kind),15,95)
		if cast_elapsed>=.32:
			cast_elapsed = -1

func take_damage(amount: int, source: Vector2, _kind: String = "", force: float = 210.0) -> bool:
	if invulnerability>0 or int(RunState.data.hp)<=0:
		return false
	if bool(RunState.stats().guard) and guard_cooldown<=0:
		guard_cooldown = 8
		invulnerability = .3
		Events.effect.emit(global_position-Vector2(0,25),Color("e0dfad"),22,140)
		Events.notice.emit("根石护甲 · 格挡")
		Events.sound.emit("hit")
		return false
	RunState.data.hp = maxi(0,int(RunState.data.hp)-amount)
	invulnerability = 1.15
	hurt_timer = .22
	velocity = Vector2(signf(global_position.x-source.x)*force,-180)
	attack_elapsed = -1
	cast_elapsed = -1
	dash_timer = 0
	RunState.changed.emit()
	Events.sound.emit("hurt")
	Events.impact.emit(global_position-Vector2(0,30),Color("e3b092"),1.0)
	if int(RunState.data.hp)<=0:
		Events.player_died.emit()
	return true

func reset_motion(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	invulnerability = 1.2
	attack_elapsed = -1
	cast_elapsed = -1
	dash_timer = 0
	jumps = 0
	coyote = 0
	jump_buffer = 0
	swing_hits.clear()

func _draw() -> void:
	if invulnerability>.0 and hurt_timer<=0 and int(clock*18)%2==0 and invulnerability<1.0:
		modulate.a = .48
	else:
		modulate.a = 1
	TravelerArt.draw_rig(self,Vector2.ZERO,.62,{"clock":clock,"facing":facing,"speed":velocity.x,"air":not is_on_floor(),"hurt":hurt_timer,"landing":landing,"weapon":str(RunState.data.weapon),"attack":attack_elapsed/.34 if attack_elapsed>=0 else -1.0,"casting":cast_elapsed>=0,"cast_color":GameData.color(cast_kind)})
	if attack_elapsed>.07 and attack_elapsed<.28 and RunState.data.weapon=="sword":
		draw_set_transform(Vector2(0,-29),0,Vector2(facing,1))
		var phase = clampf((attack_elapsed-.07)/.21,0,1)
		draw_arc(Vector2.ZERO,58+combo_stage*8,-1.55+phase*2,-.2+phase*2,18,Color(0.96,.91,.69,(1-phase)*.8),3+combo_stage*2,true)
		draw_set_transform(Vector2.ZERO)
