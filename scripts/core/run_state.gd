extends Node
## Authoritative progression and inventory. All input paths use these gates.
signal changed
var data: Dictionary = {}
var has_save: bool = false
var settings = {"music":0.45,"sfx":0.7,"touch":false,"shake":true,"fullscreen":true}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reset_run(false)
	var loaded = SaveStore.read_run()
	if not loaded.is_empty():
		restore(loaded)
		has_save = true
	var config = ConfigFile.new()
	if config.load(SaveStore.profile_path("settings.cfg")) == OK:
		for key in settings:
			settings[key] = config.get_value("game", key, settings[key])

func reset_run(erase_disk: bool = true) -> void:
	data = {"version":3,"room":0,"position":[330.0,590.0],"hp":5,"max_hp":5,"mana":100.0,"coins":0,"kills":0,"weapon":"","element":"","visited":[0],"discoveries":{},"flags":{},"caches":{},"rewards":{},"inventory":{"cloak":1},"equipment":{"armor":"cloak","charm":""},"quick":["potion","ether","bomb"],"checkpoint":{"room":0,"position":[430.0,590.0]}}
	has_save = false
	if erase_disk:
		SaveStore.clear_run()
	changed.emit()

func restore(raw: Dictionary) -> void:
	reset_run(false)
	data.room = clampi(_integer(raw.get("room", 0)), 0, 5)
	data.coins = clampi(_integer(raw.get("coins", 0)), 0, 999999)
	data.kills = clampi(_integer(raw.get("kills", 0)), 0, 999999)
	for category in ["discoveries", "flags", "caches", "rewards", "defeated"]:
		if raw.get(category) is Dictionary:
			if not data.has(category): data[category] = {}
			for key in raw[category]:
				data[category][str(key)] = _boolean(raw[category][key])
	# A legacy browser save must prove discovery; old default powers stay locked.
	if _integer(raw.get("version", 0)) < 3 and _integer(raw.get("discoveryVersion", 0)) != 2:
		data.discoveries = {"fire":bool(data.flags.get("vines",false)),"lightning":bool(data.flags.get("gate",false))}
	if raw.get("inventory") is Dictionary:
		for id in GameData.ITEMS:
			data.inventory[id] = clampi(_integer(raw.inventory.get(id, 0)), 0, 9999)
	data.inventory.cloak = maxi(1, int(data.inventory.get("cloak", 0)))
	if bool(data.flags.get("relic", false)):
		data.flags.moonwing = true
	if int(data.inventory.get("bow",0))>0: data.flags.bow = true
	if int(data.inventory.get("moonwing",0))>0: data.flags.moonwing = true
	data.max_hp = 6 if completed("moonwing") else 5
	data.hp = clampi(_integer(raw.get("hp", data.max_hp)), 1, data.max_hp)
	data.mana = clampf(_number(raw.get("mana", 100)), 0, 100)
	var visited = raw.get("visited", [0])
	if visited is Array:
		for id in visited:
			if _integer(id,-1) >= 0 and _integer(id,-1) <= 5 and not _integer(id) in data.visited:
				data.visited.append(_integer(id))
	if not data.room in data.visited:
		data.visited.append(data.room)
	var position_data = raw.get("position", [330.0,590.0])
	if position_data is Array and position_data.size() == 2:
		data.position = [clampf(_number(position_data[0],330),35,GameData.region(data.room).width-35),clampf(_number(position_data[1],590),80,590)]
	var checkpoint = raw.get("checkpoint", {})
	if checkpoint is Dictionary:
		data.checkpoint.room = clampi(_integer(checkpoint.get("room",0)),0,5)
		var p = checkpoint.get("position",[checkpoint.get("x",430),590])
		if p is Array and p.size() == 2:
			data.checkpoint.position = [clampf(_number(p[0],430),40,GameData.region(data.checkpoint.room).width-40),590.0]
	if raw.get("equipment") is Dictionary:
		for slot in ["armor","charm"]:
			var id = str(raw.equipment.get(slot,""))
			if owns(id) and str(GameData.ITEMS[id].get("slot","")) == slot:
				data.equipment[slot] = id
	for id in ["sword","fire","ice","lightning","heal"]:
		data.inventory[id] = 1 if unlocked(id) else 0
	if completed("bow"):
		data.inventory.bow = 1
	if completed("moonwing"):
		data.inventory.moonwing = 1
	var weapon = str(raw.get("weapon", ""))
	data.weapon = weapon if unlocked(weapon) else ("sword" if unlocked("sword") else ("bow" if unlocked("bow") else ""))
	var element = str(raw.get("element", ""))
	data.element = element if element in GameData.ELEMENTS and unlocked(element) else ""
	var slots = raw.get("quick", raw.get("quickItems", []))
	if slots is Array and slots.size() == 3:
		for i in 3:
			if str(slots[i]) in ["potion","ether","bomb","frost"]:
				data.quick[i] = str(slots[i])
	_grant_pending_rewards()
	changed.emit()

func _integer(value: Variant, fallback: int = 0) -> int:
	if value is int or value is bool: return int(value)
	if value is float and is_finite(value): return int(clampf(value,-100000000,100000000))
	if value is String and value.is_valid_int(): return int(value)
	return fallback

func _number(value: Variant, fallback: float = 0) -> float:
	if (value is float or value is int) and is_finite(float(value)): return float(value)
	if value is String and value.is_valid_float():
		var parsed: float = float(value)
		return parsed if is_finite(parsed) else fallback
	return fallback

func _boolean(value: Variant) -> bool:
	return value==true if value is bool else (value==1 if value is int or value is float else false)

func save_run() -> bool:
	var ok = SaveStore.write_run(data)
	if ok:
		has_save = true
	return ok

func unlocked(id: String) -> bool:
	if id == "bow":
		return bool(data.flags.get("bow", false))
	return id in ["sword","fire","ice","lightning","heal"] and bool(data.discoveries.get(id, false))

func completed(id: String) -> bool:
	return bool(data.discoveries.get(id,false)) or bool(data.flags.get(id,false)) or bool(data.caches.get(id,false)) or int(data.inventory.get(id,0)) > 0

func owns(id: String) -> bool:
	if not GameData.ITEMS.has(id):
		return false
	if id in ["sword","bow","fire","ice","lightning","heal"]:
		return unlocked(id)
	return int(data.inventory.get(id,0)) > 0

func discover(id: String) -> bool:
	if completed(id):
		return false
	if GameData.SUPPLIES.has(id):
		data.caches[id] = true
		for item in GameData.SUPPLIES[id]:
			grant(item, GameData.SUPPLIES[id][item])
		Events.notice.emit("发现旧日行囊 · 物资已收入背包")
	elif id in ["sword","fire","ice","lightning","heal"]:
		data.discoveries[id] = true
		data.inventory[id] = 1
		if id == "sword":
			data.weapon = id
		elif id in GameData.ELEMENTS:
			data.element = id
		elif id == "heal":
			data.hp = data.max_hp
			data.mana = 100.0
		Events.notice.emit("发现 " + GameData.ITEMS[id].name)
	elif id == "bow" or id == "moonwing":
		data.flags[id] = true
		data.inventory[id] = 1
		if id == "bow":
			data.weapon = id
		else:
			data.max_hp = 6
			data.hp = 6
		Events.notice.emit("获得 " + GameData.ITEMS[id].name)
	else:
		return false
	Events.sound.emit("discovery")
	changed.emit()
	save_run()
	return true

func set_flag(id: String) -> bool:
	if bool(data.flags.get(id,false)):
		return false
	data.flags[id] = true
	_grant_pending_rewards()
	changed.emit()
	save_run()
	return true

func _grant_pending_rewards() -> void:
	for flag in GameData.REWARDS:
		if bool(data.flags.get(flag,false)) and not bool(data.rewards.get(flag,false)):
			for item in GameData.REWARDS[flag]:
				grant(item, GameData.REWARDS[flag][item])
			data.rewards[flag] = true

func grant(id: String, amount: int = 1) -> void:
	if GameData.ITEMS.has(id):
		data.inventory[id] = clampi(int(data.inventory.get(id,0)) + amount,0,9999)

func stats() -> Dictionary:
	var result = {"damage":0,"element":0,"speed":1.0,"guard":false}
	for slot in ["armor","charm"]:
		var item = GameData.ITEMS.get(str(data.equipment[slot]),{})
		result.damage += int(item.get("damage",0))
		result.element += int(item.get("element",0))
		result.speed *= float(item.get("speed",1.0))
		result.guard = result.guard or bool(item.get("guard",false))
	return result

func equip(id: String) -> bool:
	if not owns(id):
		return false
	var slot = str(GameData.ITEMS[id].get("slot",""))
	if slot == "weapon":
		data.weapon = id
	elif slot in ["armor","charm"]:
		data.equipment[slot] = id
	else:
		return false
	changed.emit()
	save_run()
	Events.sound.emit("ui")
	return true

func cycle_weapon() -> bool:
	var available: Array = []
	for id in ["sword","bow"]:
		if unlocked(id):
			available.append(id)
	if available.is_empty():
		Events.notice.emit("在庭院旧路旁寻找遗落的短刃")
		return false
	return equip(available[(available.find(data.weapon)+1)%available.size()])

func cycle_element() -> bool:
	var available: Array = []
	for id in GameData.ELEMENTS:
		if unlocked(id):
			available.append(id)
	if available.is_empty():
		Events.notice.emit("元素之力需要在旅途中唤醒")
		return false
	data.element = available[(available.find(data.element)+1)%available.size()]
	changed.emit()
	return true

func select_element(id: String) -> bool:
	if not id in GameData.ELEMENTS or not unlocked(id):
		return false
	data.element = id
	changed.emit()
	return true

func spend_mana(amount: float) -> bool:
	if float(data.mana) < amount:
		return false
	data.mana = float(data.mana) - amount
	return true

func heal() -> bool:
	if not unlocked("heal"):
		Events.notice.emit("回春之种藏在庭院深处")
		return false
	if data.hp >= data.max_hp or not spend_mana(45):
		return false
	data.hp = mini(data.max_hp,data.hp+2)
	changed.emit()
	Events.item_used.emit("heal")
	return true

func use_item(id: String) -> bool:
	if not owns(id) or not str(GameData.ITEMS[id].kind) == "consumable":
		return false
	if id == "potion":
		if data.hp >= data.max_hp:
			return false
		data.hp = mini(data.max_hp,data.hp+3)
	elif id == "ether":
		if float(data.mana) >= 100:
			return false
		data.mana = minf(100,float(data.mana)+65)
	data.inventory[id] = int(data.inventory[id])-1
	changed.emit()
	Events.item_used.emit(id)
	save_run()
	return true

func assign_quick(id: String, index: int) -> bool:
	if not GameData.ITEMS.has(id) or GameData.ITEMS[id].kind != "consumable" or index < 0 or index > 2:
		return false
	data.quick[index] = id
	changed.emit()
	save_run()
	return true

func craft(id: String) -> bool:
	if not GameData.RECIPES.has(id):
		return false
	var recipe: Dictionary = GameData.RECIPES[id]
	for material in recipe:
		if int(data.inventory.get(material,0)) < int(recipe[material]):
			Events.notice.emit("制作材料不足")
			return false
	for material in recipe:
		data.inventory[material] = int(data.inventory[material])-int(recipe[material])
	grant(id, 2 if id == "bomb" else 1)
	changed.emit()
	save_run()
	Events.sound.emit("pickup")
	return true

func record_kill() -> void:
	data.kills += 1
	data.coins += 7
	grant("fiber" if data.kills%2 else "ore")
	if data.kills%3 == 0:
		grant("potion")
	changed.emit()

func rest_at(room: int, at: Vector2) -> void:
	data.hp = data.max_hp
	data.mana = 100.0
	data.checkpoint = {"room":room,"position":[at.x,at.y]}
	data.position = [at.x,at.y]
	data.room = room
	data.flags.rest = true
	changed.emit()
	Events.notice.emit("篝火已点亮 · 旅程已记录" if save_run() else "存档失败 · " + SaveStore.last_error)
	Events.sound.emit("discovery")

func respawn() -> void:
	data.coins = maxi(0,data.coins-10)
	data.hp = data.max_hp
	data.mana = 100.0
	data.room = int(data.checkpoint.room)
	data.position = data.checkpoint.position.duplicate()
	changed.emit()
	save_run()

func save_settings() -> void:
	var config = ConfigFile.new()
	for key in settings:
		config.set_value("game",key,settings[key])
	config.save(SaveStore.profile_path("settings.cfg"))

func quest() -> String:
	if not unlocked("sword"): return "寻找遗落的短刃"
	if not bool(data.flags.get("rest",false)): return "在苔息篝火休息"
	if not bool(data.flags.get("vines",false)): return "用火焰穿过荆棘书库"
	if not bool(data.flags.get("gate",false)): return "唤醒鸣雷机关"
	if not bool(data.flags.get("boss",false)): return "寻找古树之心"
	return "根脉已苏醒 · 继续探索遗境"
