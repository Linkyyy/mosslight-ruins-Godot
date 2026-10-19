class_name MossMapView
extends Control
signal region_selected(id: int)
var selected: int = 0
var zoom: float = 1
var pan: Vector2 = Vector2.ZERO
var drag_start: Vector2 = Vector2.ZERO
var pointer_start: Vector2 = Vector2.ZERO
var dragging: bool = false
var fingers: Dictionary = {}
var pinch_span: float = 0
var pinched: bool = false

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(280,180)
	focus_mode = Control.FOCUS_ALL
	resized.connect(reset_view)
	selected = int(RunState.data.room)
	reset_view()

func reset_view() -> void:
	zoom = clampf(minf(size.x/1480,size.y/660)*.94,.12,2.0)
	pan = size*.5-Vector2(740,330)*zoom
	queue_redraw()

func locate() -> void:
	selected = int(RunState.data.room)
	zoom = maxf(zoom,.75)
	pan = size*.5-_room_rect(selected).get_center()*zoom
	region_selected.emit(selected)
	queue_redraw()

func zoom_at(factor: float, at: Vector2) -> void:
	var old: float = zoom
	zoom = clampf(zoom*factor,.22,2.5)
	pan = at-(at-pan)*(zoom/old)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP: zoom_at(1.15,event.position)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN: zoom_at(1/1.15,event.position)
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_start = pan
				pointer_start = event.position
			else:
				if dragging and event.position.distance_to(pointer_start)<10: _select_at(event.position)
				dragging = false
		accept_event()
	elif event is InputEventMouseMotion and dragging:
		pan = drag_start+event.position-pointer_start
		queue_redraw()
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			fingers[event.index] = event.position
			if fingers.size()==1:
				drag_start = pan
				pointer_start = event.position
				pinched = false
			elif fingers.size()==2:
				pinch_span = fingers.values()[0].distance_to(fingers.values()[1])
				pinched = true
		else:
			if fingers.has(event.index) and fingers.size()==1 and not pinched and event.position.distance_to(pointer_start)<10: _select_at(event.position)
			fingers.erase(event.index)
			if fingers.size()==1:
				drag_start = pan
				pointer_start = fingers.values()[0]
		accept_event()
	elif event is InputEventScreenDrag and fingers.has(event.index):
		fingers[event.index] = event.position
		if fingers.size()==1:
			pan = drag_start+event.position-pointer_start
		elif fingers.size()==2:
			var values = fingers.values()
			var span: float = values[0].distance_to(values[1])
			if pinch_span>5: zoom_at(span/pinch_span,(values[0]+values[1])*.5)
			pinch_span = span
		queue_redraw()
		accept_event()

func _select_at(at: Vector2) -> void:
	var point = (at-pan)/zoom
	for id in 6:
		if _room_rect(id).has_point(point):
			selected = id
			region_selected.emit(id)
			Events.sound.emit("ui")
			queue_redraw()
			return

func _room_rect(id: int) -> Rect2:
	var r: Array = GameData.region(id).map
	return Rect2(r[0],r[1],r[2],r[3])

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("173c39bb"))
	for x in range(0,int(size.x),24): draw_line(Vector2(x,0),Vector2(x,size.y),Color("aecbb40b"))
	for y in range(0,int(size.y),24): draw_line(Vector2(0,y),Vector2(size.x,y),Color("aecbb40b"))
	draw_set_transform(pan,0,Vector2(zoom,zoom))
	for pair in GameData.LINKS:
		var a = _room_rect(pair[0]).get_center()
		var b = _room_rect(pair[1]).get_center()
		var known: bool = pair[0] in RunState.data.visited and pair[1] in RunState.data.visited
		var color = Color("bed4b6aa") if known else Color("a1b9aa3d")
		var middle = Vector2(b.x,a.y)
		draw_line(a,middle,color,2,true)
		draw_line(middle,b,color,2,true)
	if bool(RunState.data.flags.get("boss",false)):
		draw_polyline(PackedVector2Array([_room_rect(5).get_center(),Vector2(1260,15),Vector2(230,15),_room_rect(0).get_center()]),Color("ddc58d88"),2,true)
	for id in 6:
		var rect = _room_rect(id)
		var known: bool = id in RunState.data.visited
		var current: bool = id==int(RunState.data.room)
		draw_rect(rect,Color("6a8165") if current else (Color("375d52") if known else Color("244840")))
		draw_rect(rect,Color("eee7bb") if current else Color("acc0a577"),false,2,true)
		if selected==id: draw_rect(rect.grow(5),Color("f2dda8"),false,2,true)
		var name: String = GameData.region(id).name if known else "未探索区域"
		draw_string(UI.font(),Vector2(rect.position.x,rect.position.y-16),name,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,22,UI.IVORY if known else Color("90aa9a"))
		if known:
			for platform in GameData.region(id).platforms:
				var px: float = rect.position.x+14+(float(platform[0])/GameData.region(id).width)*(rect.size.x-28)
				var py: float = rect.end.y-18-(590-float(platform[1]))*.14
				draw_line(Vector2(px,py),Vector2(px+18,py),Color("c6d1af"),2,true)
			if GameData.region(id).has("camp"): draw_circle(rect.position+Vector2(27,rect.size.y-22),6,Color("e9cd8d"))
		else:
			for x in range(10,int(rect.size.x),16):
				draw_line(rect.position+Vector2(x,rect.size.y),rect.position+Vector2(minf(x+25,rect.size.x),maxf(0,rect.size.y-25)),Color("94b09b33"),1,true)
			draw_string(UI.font(),rect.get_center()+Vector2(-8,11),"?",HORIZONTAL_ALIGNMENT_LEFT,-1,35,Color("93af9c"))
		if current:
			var ratio: float = clampf(float(RunState.data.position[0])/GameData.region(id).width,0.05,.95)
			var at = rect.position+Vector2(12+ratio*(rect.size.x-24),rect.size.y-22)
			draw_circle(at,11,Color("f2e4a73d"))
			draw_circle(at,4.5,Color("ffefbb"))
	draw_set_transform(Vector2.ZERO)
