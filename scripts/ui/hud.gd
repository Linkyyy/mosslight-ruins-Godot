extends Control
var game: Node
var actions: HBoxContainer
var rail: HBoxContainer
var quick_buttons: Array[Button] = []
var counts: Array[Label] = []
var toast: PanelContainer
var toast_label: Label
var toast_left: float = 0
var region_left: float = 0
var region: Label
var objective: Label
var prompt: Label
var boss_hp: int = 0
var boss_max: int = 1
var tick: float = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UI.theme()
	actions = UI.row(9)
	add_child(actions)
	for entry in [["map","遗境舆图"],["bag","旅者背包"],["equipment","武器与装备"],["journal","冒险手记"],["settings","设置"]]:
		var id: String = entry[0]
		var action_button = UI.icon_button({"equipment":"shield","journal":"book","settings":"sound"}.get(id,id),entry[1],func(): game.menu.open_view(id),52)
		action_button.focus_mode = Control.FOCUS_NONE
		actions.add_child(action_button)
	var pause_button = UI.icon_button("pause","暂停",func(): game.menu.open_view("pause"),52)
	pause_button.focus_mode = Control.FOCUS_NONE
	actions.add_child(pause_button)
	rail = UI.row(12)
	add_child(rail)
	for i in 6:
		var index: int = i
		var b = UI.icon_button("lock","",func(): _quick(index),58)
		b.focus_mode = Control.FOCUS_NONE
		rail.add_child(b)
		quick_buttons.append(b)
		var count = UI.label("",15)
		count.position = Vector2(38,39)
		b.add_child(count)
		counts.append(count)
	objective = UI.label("",20,UI.MUTED)
	add_child(objective)
	region = UI.label("",34)
	region.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(region)
	prompt = UI.label("",20)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(prompt)
	toast_label = UI.prose("",20)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.custom_minimum_size.x = 620
	toast = UI.panel(UI.pad(toast_label,15),Color("153c35ee"))
	add_child(toast)
	toast.visible = false
	Events.notice.connect(notify)
	Events.boss_health.connect(func(hp: int, maximum: int): boss_hp=hp; boss_max=maximum)
	RunState.changed.connect(refresh)
	resized.connect(_layout)
	_layout()
	refresh()

func _layout() -> void:
	if actions==null: return
	var safe: Vector4 = UI.safe_insets()
	actions.position = Vector2(size.x-394-safe.z,27+safe.y)
	rail.position = Vector2(size.x*.5-204,size.y-78-safe.w)
	objective.position = Vector2(38+safe.x,129+safe.y)
	region.position = Vector2(size.x*.5-260,178)
	region.size = Vector2(520,65)
	toast.position = Vector2(size.x*.5-340,107)
	toast.size.x = 680

func refresh() -> void:
	if quick_buttons.is_empty(): return
	objective.text = "◇  "+RunState.quest()
	var icons = ["sword" if RunState.data.weapon!="bow" else "bow",str(GameData.ITEMS.get(str(RunState.data.element),{}).get("icon","gem")),"heal"]
	for i in 6:
		var id: String = str(RunState.data.quick[i-3]) if i>=3 else (str(RunState.data.weapon) if i==0 else (str(RunState.data.element) if i==1 else "heal"))
		quick_buttons[i].icon = UI.icon(str(GameData.ITEMS.get(id,{}).get("icon",icons[i] if i<3 else "potion")))
		var available: bool = RunState.owns(id)
		quick_buttons[i].modulate.a = 1 if available else .32
		quick_buttons[i].tooltip_text = str(GameData.ITEMS.get(id,{}).get("name","尚待发现"))
		counts[i].text = str(RunState.data.inventory.get(id,0)) if i>=3 else ""

func _quick(index: int) -> void:
	if get_tree().paused: return
	if index==0: RunState.cycle_weapon()
	elif index==1: RunState.cycle_element()
	elif index==2: RunState.heal()
	else: RunState.use_item(str(RunState.data.quick[index-3]))
	refresh()

func notify(text: String) -> void:
	toast_label.text = text
	toast_left = 3.2
	toast.visible = true

func show_region() -> void:
	region.text = GameData.region(int(RunState.data.room)).name
	region_left = 3.5
	boss_hp = 0

func _process(delta: float) -> void:
	toast_left = maxf(0,toast_left-delta)
	toast.visible = toast_left>0
	toast.modulate.a = minf(1,toast_left*3)
	region_left = maxf(0,region_left-delta)
	region.modulate.a = minf(1,region_left)*minf(1,(3.5-region_left)*2)
	if is_instance_valid(game) and is_instance_valid(game.near) and game.started and not get_tree().paused:
		prompt.text = "[E]  "+game.near.label() if not Controls.touch_enabled() else game.near.label()
		var point: Vector2 = get_viewport().get_canvas_transform()*game.near.global_position
		prompt.position = Vector2(clampf(point.x-180,20,size.x-380),clampf(point.y-112,180,size.y-150))
		prompt.size = Vector2(360,35)
		prompt.visible = true
	else: prompt.visible = false
	tick += delta
	if tick>.15:
		tick = 0
		refresh()
	queue_redraw()

func _draw() -> void:
	for i in int(RunState.data.max_hp):
		draw_texture_rect(UI.icon("heart"),Rect2(37+i*34,32,25,25),false,UI.IVORY if i<int(RunState.data.hp) else Color("90aa7640"))
	draw_line(Vector2(38,80),Vector2(220,80),Color("7b9a7555"),5,true)
	draw_line(Vector2(38,80),Vector2(38+182*float(RunState.data.mana)/100,80),Color("d4dfb2"),5,true)
	draw_string(UI.font(),Vector2(38,105),"灵息  "+str(int(RunState.data.mana)),HORIZONTAL_ALIGNMENT_LEFT,-1,15,UI.MUTED)
	draw_string(UI.font(),Vector2(size.x-135,size.y-25),"✧ "+str(RunState.data.coins),HORIZONTAL_ALIGNMENT_LEFT,-1,22,UI.IVORY)
	if boss_hp>0 and int(RunState.data.room)==5:
		var x: float = size.x*.3
		var y: float = size.y-205
		draw_string(UI.font(),Vector2(x,y-19),"根骸守卫",HORIZONTAL_ALIGNMENT_CENTER,size.x*.4,21,UI.IVORY)
		draw_line(Vector2(x,y),Vector2(size.x-x,y),Color("6e795944"),6,true)
		draw_line(Vector2(x,y),Vector2(x+(size.x-2*x)*float(boss_hp)/boss_max,y),Color("d4cf99"),6,true)
