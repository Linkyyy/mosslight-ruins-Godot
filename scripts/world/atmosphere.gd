extends Node2D
## Deterministic multi-depth scenery; the foreground remains real physics.
var region_id: int = 0
var camera_x: float = 0
var clock: float = 0
var view_size: Vector2 = Vector2(1280,720)

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	var data = GameData.region(region_id)
	var base = Color(data.color)
	draw_rect(Rect2(Vector2(-20,-200),Vector2(view_size.x+40,view_size.y+400)),base.darkened(.61))
	for layer in 3:
		var factor: float = .12+layer*.15
		var spacing: float = 240-layer*35
		var offset: float = fmod(camera_x*factor,spacing)
		var tone = base.lightened(.06*layer).darkened(.24 if layer==0 else .08)
		tone.a = .32+layer*.13
		for i in range(-1,int(view_size.x/spacing)+2):
			var x: float = i*spacing-offset
			var height: float = 350+sin((i+int(camera_x*factor/spacing))*2.7)*90
			if data.type=="library" or data.type=="water":
				draw_rect(Rect2(x,125,24,465),tone)
				draw_arc(Vector2(x+spacing*.5,190),spacing*.5-12,PI,TAU,20,tone,16,true)
				if data.type=="library":
					for shelf in 4:
						draw_rect(Rect2(x+25,310+shelf*58,spacing-52,8),tone.lightened(.16))
						for book in 8:
							draw_rect(Rect2(x+33+book*16,285+shelf*58,8,24+sin(book)*5),Color(tone.lightened(.3),.23))
			elif data.type=="mine":
				draw_colored_polygon(PackedVector2Array([Vector2(x,590),Vector2(x+15,340),Vector2(x+45,270),Vector2(x+70,410),Vector2(x+110,590)]),tone)
				draw_line(Vector2(x+20,340),Vector2(x+45,290),Color("9687b244"),3,true)
			else:
				draw_line(Vector2(x,650),Vector2(x+sin(i*3)*50,590-height),tone,34-layer*5,true)
				draw_arc(Vector2(x+50,260),150,PI*.7,PI*1.8,22,tone,21,true)
				for root in 3:
					draw_line(Vector2(x,500),Vector2(x+(root-1)*85,610),tone,10,true)
	if data.type=="heart":
		var center = Vector2(900-camera_x*.3,250)
		for i in range(7,0,-1): draw_circle(center,70+i*22,Color(.58,.68,.34,.015))
		draw_line(center+Vector2(0,230),center+Vector2(0,-280),Color("576c3d77"),105,true)
		draw_circle(center,37+sin(clock*1.7)*3,Color("ccce8c88") if bool(RunState.data.flags.get("boss",false)) else Color("9ba87055"))
	for i in 40:
		var x: float = fposmod(i*137.4-camera_x*.28+sin(clock*.3+i)*16,view_size.x)
		var y: float = 80+fposmod(i*61.7-clock*(4+i%5),500)
		var alpha: float = .15+sin(clock+i)*.08
		draw_circle(Vector2(x,y),1.2 if i%3 else 2,Color(.75,.85,.65,alpha))
	draw_rect(Rect2(0,0,view_size.x,80),Color(.01,.06,.05,.2))
	draw_rect(Rect2(0,590,view_size.x,maxf(0,view_size.y-590)),Color(.015,.07,.06,.45))
