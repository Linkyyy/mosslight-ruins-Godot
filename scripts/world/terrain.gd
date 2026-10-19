@tool
class_name MossTerrain
extends StaticBody2D
@export var size: Vector2 = Vector2(180,20):
	set(value):
		size = value
		if has_node("Collision"):
			$Collision.shape.size = size
			$Collision.position = size*.5
		queue_redraw()
@export var ice: bool = false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	var collider = CollisionShape2D.new()
	collider.name = "Collision"
	var shape = RectangleShape2D.new()
	shape.size = size
	collider.shape = shape
	collider.position = size*.5
	add_child(collider)
	queue_redraw()

func _draw() -> void:
	if ice:
		draw_rect(Rect2(Vector2.ZERO,size),Color("86babcaa"))
		draw_line(Vector2(0,0),Vector2(size.x,0),Color("d3efdf"),3,true)
		for x in range(15,int(size.x),28):
			draw_line(Vector2(x,3),Vector2(x+9,size.y),Color("d8efdc88"),1,true)
		return
	draw_rect(Rect2(Vector2(0,3),size),Color("19382f"))
	draw_rect(Rect2(0,0,size.x,7),Color("6e8e60"))
	draw_line(Vector2.ZERO,Vector2(size.x,0),Color("a6b883"),2,true)
	for x in range(7,int(size.x),17):
		var n: float = sin(x*1.73+position.x)*.5+.5
		draw_line(Vector2(x,0),Vector2(x-3,-3-n*7),Color("91ad71"),1,true)
		if size.y>40 and x%3==1:
			draw_line(Vector2(x,17),Vector2(x+12,45+n*55),Color("78905a33"),2,true)
	if size.y<40:
		draw_colored_polygon(PackedVector2Array([Vector2(0,size.y),Vector2(size.x*.23,size.y+7),Vector2(size.x*.48,size.y+2),Vector2(size.x*.75,size.y+11),Vector2(size.x,size.y)]),Color("243f31"))
