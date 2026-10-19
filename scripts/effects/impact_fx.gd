extends Node2D
## Bounded transient pools keep combat effects inexpensive on phones.
const MAX_PARTICLES = 360
var particles: Array = []
var numbers: Array = []
var rings: Array = []

func _ready() -> void:
	Events.effect.connect(burst)
	Events.damage_number.connect(_number)
	Events.impact.connect(_ring)

func burst(at: Vector2, color: Color, count: int, force: float) -> void:
	for i in mini(count,MAX_PARTICLES-particles.size()):
		var duration: float = randf_range(.25,.7)
		particles.append({"p":at,"v":Vector2(randf_range(-1,1),randf_range(-1.25,.25))*force,"life":duration,"max":duration,"color":color,"size":randf_range(1.2,3.2)})

func _number(at: Vector2, amount: int, color: Color) -> void:
	if numbers.size()<24: numbers.append({"p":at,"text":str(amount),"life":.8,"color":color})

func _ring(at: Vector2, color: Color, strength: float) -> void:
	rings.append({"p":at,"life":.25,"color":color,"strength":strength})

func _process(delta: float) -> void:
	for i in range(particles.size()-1,-1,-1):
		var p: Dictionary = particles[i]
		p.life -= delta
		p.v.y += 220*delta
		p.p += p.v*delta
		if p.life<=0: particles.remove_at(i)
	for i in range(numbers.size()-1,-1,-1):
		numbers[i].life -= delta
		numbers[i].p.y -= delta*44
		if numbers[i].life<=0: numbers.remove_at(i)
	for i in range(rings.size()-1,-1,-1):
		rings[i].life -= delta
		if rings[i].life<=0: rings.remove_at(i)
	queue_redraw()

func clear() -> void:
	particles.clear()
	numbers.clear()
	rings.clear()

func _draw() -> void:
	for p in particles:
		draw_circle(p.p,p.size,Color(p.color,p.life/p.max))
	for ring in rings:
		draw_arc(ring.p,(1-ring.life/.25)*45*ring.strength,0,TAU,25,Color(ring.color,ring.life*3),1.5,true)
	for number in numbers:
		draw_string(ThemeDB.fallback_font,number.p,number.text,HORIZONTAL_ALIGNMENT_CENTER,-1,21,Color(number.color,minf(1,number.life*2)))
