extends Control
var clock: float = 0

func _ready() -> void:
	custom_minimum_size = Vector2(180,180)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	var center = size*.5
	draw_arc(center,minf(size.x*.46,size.y*.47),0,TAU,96,Color("dce3bd14"),1.0,true)
	draw_arc(center,minf(size.x*.49,size.y*.5),0,TAU,96,Color("dce3bd08"),1.0,true)
	var zoom: float = minf(size.y/140,size.x/110)*.86
	TravelerArt.draw_rig(self,Vector2(size.x*.5,size.y*.94),zoom,{"clock":clock,"facing":1,"speed":0,"weapon":str(RunState.data.weapon)})
