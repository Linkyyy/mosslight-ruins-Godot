extends Control
## A single native full-screen shell; each view owns its bounded scroll areas.
const VIEWS = ["map","bag","equipment","journal","guide","settings"]
const TITLES = {"map":"遗境舆图","bag":"旅者背包","equipment":"武器与装备","journal":"冒险手记","guide":"旅者指南","settings":"旅途设置","credits":"制作与致谢","pause":"在微光中歇息","death":"微光暂歇","victory":"根脉苏醒，微光归来"}
var game: Node
var current: String = ""
var body: Control
var heading: Label
var navigation: HBoxContainer
var close_button: Button
var feedback: Label
var feedback_time: float = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UI.theme()
	heading = UI.label("",30)
	add_child(heading)
	navigation = UI.row(14)
	add_child(navigation)
	for entry in [["map","地图","map"],["bag","背包","bag"],["equipment","装备","shield"],["journal","手记","book"],["guide","指南","help"],["settings","设置","sound"]]:
		var id: String = entry[0]
		var button = UI.icon_button(entry[2],entry[1],func(): if current!=id: open_view(id),64)
		button.set_meta("view",id)
		navigation.add_child(button)
	close_button = UI.button("×",close_view)
	close_button.custom_minimum_size = Vector2(64,64)
	close_button.add_theme_font_size_override("font_size",40)
	close_button.tooltip_text = "返回旅途 · Esc"
	add_child(close_button)
	body = Control.new()
	add_child(body)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 38
	body.offset_top = 122
	body.offset_right = -38
	body.offset_bottom = -35
	feedback = UI.label("",16,UI.GOLD)
	add_child(feedback)
	Events.notice.connect(func(text: String): feedback.text=text; feedback_time=3.2)
	resized.connect(_layout)
	_layout()
	visible = false

func _layout() -> void:
	if heading==null: return
	var safe: Vector4 = UI.safe_insets()
	heading.position = Vector2(38+safe.x,35+safe.y)
	navigation.position = Vector2(size.x*.5-227,23)
	close_button.position = Vector2(size.x-101-safe.z,26+safe.y)
	feedback.position = Vector2(40+safe.x,size.y-28-safe.w)
	if body:
		body.offset_left = 38+safe.x
		body.offset_right = -38-safe.z
		body.offset_top = 122+safe.y
		body.offset_bottom = -35-safe.w
	queue_redraw()

func _process(delta: float) -> void:
	feedback_time = maxf(0,feedback_time-delta)
	feedback.modulate.a = minf(1,feedback_time)

func open_view(view: String) -> void:
	if int(RunState.data.hp)<=0 and view!="death": return
	current = view
	visible = true
	get_tree().paused = true
	Engine.time_scale = 1
	Controls.reset_inputs()
	heading.text = TITLES.get(view,"")
	heading.visible = view!="title"
	navigation.visible = view not in ["title","death","victory"]
	close_button.visible = view not in ["title","death"]
	for b in navigation.get_children():
		b.add_theme_stylebox_override("normal",UI.box(Color("e0e5c422") if b.get_meta("view")==view else Color.TRANSPARENT,32))
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	match view:
		"bag", "equipment":
			var inventory = InventoryView.new()
			inventory.equipment_mode = view=="equipment"
			_fill(inventory)
		"map": _map()
		"journal": _journal()
		"guide": _guide()
		"settings": _settings()
		"credits": _credits()
		"pause": _pause_page()
		"death": _death_page()
		"victory": _victory_page()
		_: _title_page()
	if close_button.visible: close_button.grab_focus()
	queue_redraw()

func close_view() -> void:
	if current=="death": return
	RunState.save_settings()
	if not game.started:
		open_view("title")
		return
	current = ""
	visible = false
	get_tree().paused = game.orientation_paused
	Controls.reset_inputs()

func _fill(child: Control) -> void:
	body.add_child(child)
	child.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _center(column: Control, width: float = 620) -> void:
	var center = CenterContainer.new()
	_fill(center)
	column.custom_minimum_size.x = width
	center.add_child(UI.scroll(column))
	center.get_child(0).custom_minimum_size = Vector2(width,minf(body.size.y,column.get_combined_minimum_size().y))

func _title_page() -> void:
	var column = UI.column(18)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(UI.texture("leaf",Vector2(95,100)))
	var english = UI.label("M O S S L I G H T",18,UI.MUTED)
	english.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(english)
	var title = UI.label("苔光遗境",65)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var sub = UI.label("循着微光，唤醒根脉深处的回声。",21,UI.MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(sub)
	var start = UI.button("继续旅程" if RunState.has_save else "踏上旅途",func(): game.start_game(false),"leaf",true)
	column.add_child(start)
	if RunState.has_save: column.add_child(UI.button("新的旅程",_confirm_new))
	var row = UI.row(20)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(UI.button("旅者指南",func(): open_view("guide"),"help"))
	row.add_child(UI.button("设置",func(): open_view("settings"),"sound"))
	column.add_child(row)
	_center(column)
	start.call_deferred("grab_focus")

func _map() -> void:
	var row = UI.row(28)
	_fill(row)
	var left = UI.column(15)
	UI.stretch(left)
	row.add_child(left)
	left.add_child(UI.label("CARTOGRAPHY  ·  已探索 "+str(RunState.data.visited.size())+" / 6",18,UI.MUTED))
	var map_view = MossMapView.new()
	UI.stretch(map_view)
	left.add_child(map_view)
	var controls = UI.row(10)
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_child(UI.button("＋",func(): map_view.zoom_at(1.2,map_view.size*.5)))
	controls.add_child(UI.button("−",func(): map_view.zoom_at(1/1.2,map_view.size*.5)))
	controls.add_child(UI.button("全貌",map_view.reset_view,"map"))
	controls.add_child(UI.button("定位",map_view.locate,"compass"))
	left.add_child(controls)
	left.add_child(UI.label("拖动探索 · 滚轮或双指缩放 · 亮点为旅者所在",16,UI.MUTED))
	var details = UI.column(17)
	var paper = UI.panel(UI.pad(details,20))
	var scroller = UI.scroll(paper)
	scroller.custom_minimum_size.x = 340
	scroller.size_flags_horizontal = Control.SIZE_FILL
	row.add_child(scroller)
	map_view.region_selected.connect(func(id: int): _map_details(id,details))
	_map_details(int(RunState.data.room),details)

func _map_details(id: int, column: VBoxContainer) -> void:
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
	if not id in RunState.data.visited:
		column.add_child(UI.label("未探索区域",28,UI.INK))
		column.add_child(UI.prose("迷雾后的道路，等待你亲自踏足。",20,Color("819077")))
		return
	var data = GameData.region(id)
	column.add_child(UI.label(data.tag,16,Color("87947d")))
	column.add_child(UI.label(data.name,31,UI.INK))
	column.add_child(UI.label("●  旅者当前所在" if id==int(RunState.data.room) else "已探索",18,Color("6b876e")))
	column.add_child(UI.prose(["古树的微光沿着旧路流动。高处的拱门通向一条隐秘支路。","水曾淹没旧王国的回廊。寒霜能让旅者再次走过水面。","书页与荆棘一同沉睡。余烬仍能唤醒失落圣所。","雷电在灵石间流转。让水面成为机关的脉络。","月光在孢群中沉积。向上攀登，寻找另一种跃起的力量。","漫长的守卫仍在履行职责。留意蓄力，寻找反击的空隙。"][id],19,Color("7d8974")))
	column.add_child(UI.label("探索目标",22,UI.INK))
	for entry in GameData.objectives(id):
		column.add_child(UI.prose(("✓  " if RunState.completed(entry[0]) else "◇  ")+entry[1],18,Color("98a08b") if RunState.completed(entry[0]) else UI.INK))

func _journal() -> void:
	var row = UI.row(38)
	_fill(row)
	var chapters = UI.column(16)
	chapters.custom_minimum_size.x = 265
	row.add_child(UI.scroll(chapters))
	chapters.add_child(UI.label("遗境见闻",22,UI.MUTED))
	var page = UI.column(25)
	var paper = UI.panel(UI.pad(page,32))
	var right = UI.scroll(paper)
	UI.stretch(right)
	row.add_child(right)
	var entries = [["旅途起点","微光未曾熄灭","地下王国失去了古树的庇护。一位循着苔光而来的旅者，在遗境中寻找失落的灵印与武器。","leaf"],["元素法则","万物彼此相连","木畏火，水遇寒而凝，雷随水而行。留心身边的水、木与灵石，让力量回应这个世界。","gem"],["遗落之翼","高处的另一条路","月孢回应了你的呼唤。空中再次跃起，就能触及曾经遥远的地方。" if RunState.completed("moonwing") else "庭院高处的拱门隐约有孢光流动。那里也许藏着通往更高处的秘密。","jump"],["古树之心","根脉深处的回声","守卫终于放下漫长的职责。古树之心再次发光，微光沿根脉回到每个角落。" if bool(RunState.data.flags.get("boss",false)) else "最后的守卫仍在等待。它的蓄力预示着下一次冲锋，跃起可以避开地面根脉波。","book"]]
	for i in entries.size():
		var index: int = i
		chapters.add_child(UI.button("0"+str(i+1)+"  "+entries[i][0],func(): _journal_page(page,entries[index],index),entries[i][3]))
	_journal_page(page,entries[0],0)

func _journal_page(page: VBoxContainer, entry: Array, index: int) -> void:
	for child in page.get_children():
		page.remove_child(child)
		child.queue_free()
	page.add_child(UI.label("FIELD NOTES  ·  0"+str(index+1),17,Color("919880")))
	page.add_child(UI.label(entry[1],35,UI.INK))
	var image = UI.texture(entry[3],Vector2(90,145))
	image.modulate = Color("92a387")
	page.add_child(image)
	page.add_child(UI.prose(entry[2],23,UI.INK))
	page.add_child(UI.prose("根脉与你同在。",18,Color("919880")))
	page.add_child(UI.label("MOSSLIGHT  ·  "+str(index+1)+" / 4",16,Color("a0a58f")))

func _guide() -> void:
	var row = UI.row(35)
	_fill(row)
	var controls = UI.column(12)
	var left = UI.scroll(controls)
	UI.stretch(left)
	row.add_child(left)
	controls.add_child(UI.label("旅者的技艺",24))
	var bindings = [["移动","A / D 或 ← →","左侧摇杆"],["跳跃 / 二段跳","空格 / W / ↑","跳跃图标"],["武器攻击","J","短刃图标"],["元素施法","K","元素图标"],["冲刺","Shift","冲刺图标"],["互动 / 篝火休息","E","手掌图标"],["切换元素","Q / 手柄 LB","下方元素图标"],["切换武器","1 / 2 / Tab","下方武器图标"],["灵息疗愈","R / 方向上","下方回春图标"],["快捷道具","3 / 4 / 5","下方道具图标"],["地图 / 背包 / 装备","M / B / I","顶部菜单"],["全屏 / 暂停","F / Esc","设置 / 暂停"]]
	for entry in bindings:
		var line = UI.row(20)
		line.custom_minimum_size.y = 42
		var name_label = UI.label(entry[0],21,UI.MUTED)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(name_label)
		line.add_child(UI.label(entry[2] if Controls.touch_enabled() else entry[1],19))
		controls.add_child(line)
	var notes = UI.column(20)
	notes.add_child(UI.label("循光而行",31,UI.INK))
	for entry in [["万物彼此相连","火焰焚毁荆棘，寒冰冻结深水，雷电沿水传导并唤醒灵石。施法消耗 18 灵息，灵息会缓慢恢复。"],["力量，藏在旅途之中","武器、元素与回春需要探索拾取。靠近发光遗物后互动。篝火恢复生命并记录旅程。"],["留心每一次出手","连续挥刃可衔接三段攻击；冲刺消耗 8 灵息，提供短暂闪避。回春消耗 45 灵息。"],["随时整理行囊","背包可装备、使用、制作道具，并分配三个快捷槽。手机支持多指同时操作；手柄支持移动、战斗与菜单导航。"]]:
		notes.add_child(UI.label(entry[0],21,UI.INK))
		notes.add_child(UI.prose(entry[1],19,Color("7b8873")))
	notes.add_child(UI.button("继续旅程" if game.started else "踏上旅途",_continue_or_start,"leaf",true))
	var paper = UI.scroll(UI.panel(UI.pad(notes,22)))
	paper.custom_minimum_size.x = 390
	paper.size_flags_horizontal = Control.SIZE_FILL
	row.add_child(paper)

func _continue_or_start() -> void:
	if game.started: close_view()
	else: game.start_game(false)

func _settings() -> void:
	var column = UI.column(23)
	for entry in [["music","环境音乐"],["sfx","动作与界面音效"]]:
		var key: String = entry[0]
		var line = UI.row(24)
		line.add_child(UI.label(entry[1],23))
		var slider = HSlider.new()
		slider.min_value = 0
		slider.max_value = 1
		slider.step = .01
		slider.value = float(RunState.settings[key])
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size = Vector2(300,45)
		slider.value_changed.connect(func(value: float): RunState.settings[key]=value)
		line.add_child(slider)
		column.add_child(line)
	for entry in [["touch","显示触屏操作"],["shake","命中时镜头震动"]]:
		var key: String = entry[0]
		var toggle = CheckButton.new()
		toggle.text = entry[1]
		toggle.custom_minimum_size.y = 62
		toggle.button_pressed = bool(RunState.settings[key])
		toggle.toggled.connect(func(value: bool): RunState.settings[key]=value; RunState.save_settings())
		column.add_child(toggle)
	column.add_child(UI.button("切换全屏",game.toggle_fullscreen,"fullscreen"))
	column.add_child(UI.button("导入旧旅程 JSON",_import_dialog,"book"))
	column.add_child(UI.button("制作与致谢",func(): open_view("credits"),"leaf"))
	column.add_child(UI.prose("自动存档在探索发现、区域切换和篝火休息时记录。当前旅程仅保存在这台设备。",19,UI.MUTED))
	column.add_child(UI.button("新的旅程",_confirm_new))
	_center(column,690)

func _credits() -> void:
	var column = UI.column(24)
	column.add_child(UI.label("MOSSLIGHT · 苔光遗境",33))
	column.add_child(UI.label("原生重构版本 0.1.0",20,UI.MUTED))
	column.add_child(UI.prose("角色、怪物、图标与场景矢量表现，以及动作与环境合成音效，均为本项目原创制作。",22))
	column.add_child(UI.prose("引擎 · Godot Engine / MIT License\nhttps://godotengine.org/license/",20))
	column.add_child(UI.prose("中文字体 · Noto Sans CJK SC 的 Mosslight UI 子集\nSIL Open Font License 1.1\nhttps://github.com/notofonts/noto-cjk",20))
	column.add_child(UI.prose("字体完整授权见随项目提供的 assets/fonts/LICENSE-Noto.txt。旅程保存在这台设备，本版本无需网络连接。",19,UI.MUTED))
	column.add_child(UI.button("返回设置",func(): open_view("settings"),"arrow",true))
	_center(column,740)

func _pause_page() -> void:
	var column = UI.column(24)
	column.add_child(UI.texture("leaf",Vector2(75,90)))
	var title = UI.label(GameData.region(int(RunState.data.room)).name,34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	column.add_child(UI.label("探索 "+str(RunState.data.visited.size())+" / 6     ✧ "+str(RunState.data.coins),23,UI.MUTED))
	column.add_child(UI.prose("遗境会等你回来。整理行囊，或者继续下一段旅程。",22,UI.MUTED))
	column.add_child(UI.button("继续冒险",close_view,"leaf",true))
	column.add_child(UI.button("记录旅程",func(): game.save_position(); Events.notice.emit("旅程已记录" if RunState.save_run() else SaveStore.last_error),"book"))
	column.add_child(UI.button("返回主界面",func(): game.quit_to_title()))
	_center(column)

func _death_page() -> void:
	var column = UI.column(25)
	column.add_child(UI.texture("leaf",Vector2(90,100)))
	column.add_child(UI.prose("失去的只是片刻方向。古树仍在等你。\n消耗至多 10 枚灵光碎片，从最后的篝火重新出发。",24))
	var revive = UI.button("重燃微光",func(): game.respawn(),"leaf",true)
	column.add_child(revive)
	_center(column)
	revive.call_deferred("grab_focus")

func _victory_page() -> void:
	var column = UI.column(24)
	column.add_child(UI.texture("leaf",Vector2(90,100)))
	column.add_child(UI.prose("根骸守卫卸下了漫长的守望。\n古树之心再次跳动，温柔的光沿根脉回到遗境。",24))
	column.add_child(UI.label("区域 "+str(RunState.data.visited.size())+" / 6    击败敌人 "+str(RunState.data.kills),23))
	column.add_child(UI.prose("回到庭院的根脉捷径已开启。你可以继续寻找尚未发现的秘密。",21,UI.MUTED))
	column.add_child(UI.button("继续探索",close_view,"leaf",true))
	_center(column)

func _confirm_new() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "新的旅程"
	dialog.dialog_text = "这会替换这台设备上保存的旅程。确定重新启程？"
	dialog.ok_button_text = "重新启程"
	dialog.cancel_button_text = "保留旅程"
	dialog.theme = UI.theme()
	add_child(dialog)
	dialog.confirmed.connect(func(): game.start_game(true); dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(620,220))

func _import_dialog() -> void:
	var dialog = FileDialog.new()
	dialog.title = "导入旧旅程"
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.json ; 旅程存档"])
	dialog.use_native_dialog = true
	add_child(dialog)
	dialog.file_selected.connect(func(path: String):
		var file = FileAccess.open(path,FileAccess.READ)
		if not file or file.get_length()>2000000:
			Events.notice.emit("无法读取此存档")
			dialog.queue_free()
			return
		var raw = JSON.parse_string(file.get_as_text())
		if raw is Dictionary and raw.get("payload") is String: raw = JSON.parse_string(raw.payload)
		if raw is Dictionary and raw.has("room") and (raw.has("inventory") or raw.has("discoveries")):
			RunState.restore(raw)
			RunState.save_run()
			game.start_game(false)
			Events.notice.emit("旧旅程已迁入遗境")
		else: Events.notice.emit("此文件不是有效的旅程存档")
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered_ratio(.8)

func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if event.is_action_pressed("fullscreen"):
		game.toggle_fullscreen()
		accept_event()
		return
	if current in ["death","title"]: return
	if event.is_action_pressed("pause"):
		close_view()
		accept_event()
		return
	for entry in [["map","map"],["bag","bag"],["equipment","equipment"],["guide","guide"]]:
		if event.is_action_pressed(entry[0]):
			if current==entry[1]: close_view()
			else: open_view(entry[1])
			accept_event()
			return
	if event is InputEventJoypadButton and (event.button_index==JOY_BUTTON_LEFT_SHOULDER or event.button_index==JOY_BUTTON_RIGHT_SHOULDER) and event.pressed:
		var direction: int = -1 if event.button_index==JOY_BUTTON_LEFT_SHOULDER else 1
		open_view(VIEWS[posmod(VIEWS.find(current)+direction,VIEWS.size())])
		accept_event()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("183e40f5"))
	for i in range(9,0,-1):
		draw_circle(Vector2(size.x*.4,size.y*.6),i*80,Color(.63,.77,.64,.006))
	draw_arc(Vector2(size.x*.42,size.y*.6),size.y*.45,0,TAU,120,Color("d6dfb607"),1,true)
