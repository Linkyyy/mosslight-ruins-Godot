class_name InventoryView
extends HBoxContainer
const PORTRAIT = preload("res://scripts/ui/actor_portrait.gd")
const RARITY = [Color("7f9487"),Color("7f9487"),Color("5e9387"),Color("6889aa"),Color("9179a5"),Color("b4966b")]
var equipment_mode: bool = false
var selected: String = "sword"
var filter: String = "all"
var slot: String = "weapon"
var pending: bool = false
var grid: GridContainer
var catalog_scroll: ScrollContainer
var saved_scroll: int = 0

func _ready() -> void:
	add_theme_constant_override("separation",34)
	RunState.changed.connect(_refresh_later)
	_build()

func _refresh_later() -> void:
	if not pending:
		pending = true
		call_deferred("_build")

func _build() -> void:
	pending = false
	if is_instance_valid(catalog_scroll): saved_scroll = catalog_scroll.scroll_vertical
	for child in get_children():
		remove_child(child)
		child.queue_free()
	grid = null
	catalog_scroll = null
	if equipment_mode: _equipment()
	else: _bag()

func _bag() -> void:
	var catalog = UI.column(17)
	UI.stretch(catalog)
	add_child(catalog)
	var filters = UI.row(16)
	catalog.add_child(filters)
	for entry in [["all","全部","bag"],["gear","装备","shield"],["consumable","道具","potion"],["material","材料","ore"],["ability","灵印","gem"]]:
		var id: String = entry[0]
		var b = UI.icon_button(entry[2],entry[1],func(): filter=id; _refresh_later(),52)
		if filter==id: b.add_theme_stylebox_override("normal",UI.box(Color("dde5c32b"),26))
		filters.add_child(b)
	var caption = UI.label("旅者藏品",20,UI.MUTED)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	filters.add_child(caption)
	grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation",13)
	grid.add_theme_constant_override("v_separation",13)
	catalog_scroll = UI.scroll(grid)
	catalog.add_child(catalog_scroll)
	catalog_scroll.resized.connect(func(): if is_instance_valid(grid): grid.columns=maxi(2,int(catalog_scroll.size.x/125)))
	var ids: Array = []
	for id in GameData.ITEMS:
		var kind: String = GameData.ITEMS[id].kind
		if filter=="all" or filter==kind or (filter=="gear" and kind in ["weapon","armor","charm"]): ids.append(id)
	if not selected in ids and not ids.is_empty(): selected = ids[0]
	for id in ids: grid.add_child(_card(id))
	var wallet = UI.row()
	wallet.add_child(UI.label("✧  "+str(RunState.data.coins),24))
	var note = UI.label("力量藏在旅途之中",16,UI.MUTED)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wallet.add_child(note)
	catalog.add_child(wallet)
	var detail = _detail(selected)
	detail.custom_minimum_size.x = 350
	detail.size_flags_horizontal = Control.SIZE_FILL
	add_child(detail)
	catalog_scroll.set_deferred("scroll_vertical",saved_scroll)

func _equipment() -> void:
	var slots = UI.column(24)
	slots.custom_minimum_size.x = 180
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(slots)
	slots.add_child(UI.label("旅者行装",20,UI.MUTED))
	for entry in [["weapon","武器","sword"],["armor","护甲","cloak"],["charm","灵物","gem"]]:
		var id: String = entry[0]
		var equipped: String = str(RunState.data.weapon) if id=="weapon" else str(RunState.data.equipment[id])
		var title: String = str(GameData.ITEMS.get(equipped,{}).get("name","未装备"))
		var b = UI.button(entry[1]+"\n"+title,func(): slot=id; _select_equipped(); _refresh_later(),entry[2])
		b.custom_minimum_size.y = 86
		b.add_theme_font_size_override("font_size",19)
		if slot==id: b.add_theme_stylebox_override("normal",UI.box(Color("dce2c018"),40,Color("e4d6a57a")))
		slots.add_child(b)
	var character = UI.column(4)
	UI.stretch(character)
	add_child(character)
	var english = UI.label("MOSSLIGHT WANDERER",13,UI.MUTED)
	english.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character.add_child(english)
	var title = UI.label("微光旅者",31)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character.add_child(title)
	var portrait = Control.new()
	portrait.set_script(PORTRAIT)
	UI.stretch(portrait)
	character.add_child(portrait)
	var footer = UI.label("根脉与你同在",15,UI.MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character.add_child(footer)
	var aside = UI.column(18)
	var scroller = UI.scroll(aside)
	scroller.custom_minimum_size.x = 350
	scroller.size_flags_horizontal = Control.SIZE_FILL
	add_child(scroller)
	aside.add_child(UI.label("角色属性",23))
	var stats = RunState.stats()
	for entry in [["生命上限",str(RunState.data.max_hp)],["武器伤害","+"+str(stats.damage)],["元素增幅","+"+str(stats.element)],["移动速度",str(int(stats.speed*100))+"%"],["护甲格挡","每 8 秒" if stats.guard else "—"]]:
		var line = UI.row()
		var name_label = UI.label(entry[0],18,UI.MUTED)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(name_label)
		line.add_child(UI.label(entry[1],18))
		aside.add_child(line)
	var choices = GridContainer.new()
	choices.columns = 3
	choices.add_theme_constant_override("h_separation",10)
	choices.add_theme_constant_override("v_separation",10)
	aside.add_child(choices)
	var candidates: Array = []
	for id in GameData.ITEMS:
		if str(GameData.ITEMS[id].get("slot",""))==slot: candidates.append(id)
	if not selected in candidates and not candidates.is_empty(): selected = candidates[0]
	for id in candidates: choices.add_child(_card(id,true))
	aside.add_child(_detail(selected,true))

func _select_equipped() -> void:
	var equipped: String = str(RunState.data.weapon) if slot=="weapon" else str(RunState.data.equipment[slot])
	if not equipped.is_empty(): selected = equipped

func _card(id: String, small: bool = false) -> Button:
	var item: Dictionary = GameData.ITEMS[id]
	var b = UI.button("",func(): selected=id; _refresh_later())
	b.tooltip_text = item.name
	b.custom_minimum_size = Vector2(104 if small else 112,108 if small else 145)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var color: Color = RARITY[int(item.rarity)]
	b.add_theme_stylebox_override("normal",UI.box(color,5,Color("fff6db") if selected==id else Color.TRANSPARENT))
	b.add_theme_stylebox_override("hover",UI.box(color.lightened(.12),5,Color("fff1cf")))
	b.clip_contents = true
	var content = UI.column(0)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 4
	content.offset_top = 5
	content.offset_right = -4
	content.offset_bottom = -4
	var image = UI.texture(item.icon,Vector2(54,70 if small else 105))
	image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(image)
	var caption = UI.row(0)
	var stars = UI.label("★".repeat(int(item.rarity)),12,Color("b28e4e"))
	stars.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.add_child(stars)
	caption.add_child(UI.label(str(RunState.data.inventory.get(id,0)) if RunState.owns(id) else "—",14,UI.INK))
	var paper = UI.panel(caption,UI.PAPER)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(paper)
	if not RunState.owns(id): b.modulate.a = .4
	return b

func _detail(id: String, compact: bool = false) -> Control:
	if not GameData.ITEMS.has(id): return UI.panel(UI.label("尚待发现",22,UI.INK))
	var item: Dictionary = GameData.ITEMS[id]
	var column = UI.column(14)
	var title_column = UI.column(8)
	title_column.add_child(UI.label({"weapon":"武器","armor":"护甲","charm":"灵物","consumable":"消耗品","material":"材料","ability":"探索能力"}.get(item.kind,"遗物"),15,Color("e5e6d3")))
	title_column.add_child(UI.label(item.name,26 if compact else 30))
	title_column.add_child(UI.label("★".repeat(int(item.rarity)),19,UI.GOLD))
	column.add_child(UI.panel(UI.pad(title_column,19),RARITY[int(item.rarity)]))
	var prose = UI.column(17)
	if not compact:
		var image = UI.texture(item.icon,Vector2(85,110))
		image.modulate = Color("73876b")
		prose.add_child(image)
	prose.add_child(UI.prose(item.effect,19,UI.INK))
	if not compact: prose.add_child(UI.prose(item.lore,17,Color("87907b")))
	prose.add_child(UI.prose("来源 · "+item.source,16,Color("87907b")))
	var owned: bool = RunState.owns(id)
	if GameData.RECIPES.has(id):
		var costs: Array[String] = []
		for material in GameData.RECIPES[id]: costs.append(GameData.ITEMS[material].name+" "+str(RunState.data.inventory.get(material,0))+" / "+str(GameData.RECIPES[id][material]))
		prose.add_child(UI.prose("制作所需\n"+"\n".join(costs),16,Color("77836d")))
		prose.add_child(UI.button("制作 ×"+("2" if id=="bomb" else "1"),func(): RunState.craft(id),"leaf",true))
	if item.kind=="consumable":
		var assign = UI.row(8)
		assign.add_child(UI.label("快捷栏",16,UI.INK))
		for i in 3:
			var index: int = i
			assign.add_child(UI.button(str(i+1),func(): RunState.assign_quick(id,index)))
		prose.add_child(assign)
	var action = UI.button("在旅途中寻找",func(): pass,"leaf",true)
	action.disabled = not owned
	if owned:
		if item.has("slot"):
			var equipped: bool = RunState.data.weapon==id if item.slot=="weapon" else RunState.data.equipment[item.slot]==id
			action.text = "已装备" if equipped else "装备"
			action.disabled = equipped
			action.pressed.connect(func(): RunState.equip(id))
		elif item.kind=="consumable":
			action.text = "使用"
			action.pressed.connect(func(): RunState.use_item(id))
		elif id in GameData.ELEMENTS:
			action.text = "已选用" if RunState.data.element==id else "选用灵印"
			action.pressed.connect(func(): RunState.select_element(id))
		else:
			action.text = "已掌握" if item.kind=="ability" else "制作材料"
			action.disabled = true
	prose.add_child(action)
	column.add_child(UI.pad(prose,18))
	var sheet = UI.panel(column,UI.PAPER)
	if compact: return sheet
	return UI.scroll(sheet)
