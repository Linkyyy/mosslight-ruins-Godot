class_name GameData
extends RefCounted
## Read-only design data shared by world scenes, progression and menus.

const ELEMENTS = ["fire", "ice", "lightning"]
const ELEMENT_NAMES = {"fire": "火焰", "ice": "寒冰", "lightning": "雷电"}
const COLORS = {"fire": Color("efb07d"), "ice": Color("a6e0e2"), "lightning": Color("d7bdf1"), "heal": Color("c6e2a8"), "sword": Color("e9e4be")}
const ITEMS = {
	"sword": {"name":"旅者短刃", "kind":"weapon", "slot":"weapon", "icon":"sword", "rarity":3, "effect":"三段近战连击，第三击产生更强的击退。", "lore":"苔痕覆盖剑柄，却依然锋利。", "source":"苔息庭院 · 篝火东侧的旧路"},
	"bow": {"name":"古木长弓", "kind":"weapon", "slot":"weapon", "icon":"bow", "rarity":3, "effect":"射出不消耗弹药的灵木箭矢。", "lore":"弦声如风，唤醒古木的回忆。", "source":"沉水回廊 · 对岸的古老宝箱"},
	"cloak": {"name":"苔织披风", "kind":"armor", "slot":"armor", "icon":"cloak", "rarity":2, "speed":1.05, "effect":"移动速度 +5%。", "lore":"柔软的苔丝，陪伴旅者踏上旧路。", "source":"旅者初始行装"},
	"stonevest": {"name":"根石护甲", "kind":"armor", "slot":"armor", "icon":"shield", "rarity":4, "speed":0.96, "guard":true, "effect":"每 8 秒格挡一次伤害；移动速度 -4%。", "lore":"细小的雷光在石纹间游走。", "source":"鸣雷矿井 · 唤醒灵石机关"},
	"amber": {"name":"余烬琥珀", "kind":"charm", "slot":"charm", "icon":"gem", "rarity":4, "damage":1, "effect":"武器伤害 +1。", "lore":"树脂凝固的一瞬，封存了一缕火。", "source":"荆棘书库 · 烧开封路藤蔓"},
	"moonwing": {"name":"月孢之翼", "kind":"charm", "slot":"charm", "icon":"leaf", "rarity":5, "speed":1.12, "effect":"移动速度 +12%；发现时永久解锁二段跳。", "lore":"月光停留在轻盈的孢翼之间。", "source":"月孢洞窟 · 高处的隐秘宝箱"},
	"thornring": {"name":"根脉灵环", "kind":"charm", "slot":"charm", "icon":"ring", "rarity":5, "element":1, "effect":"元素伤害 +1。", "lore":"漫长守望落幕后，仍有温暖留存。", "source":"古树心室 · 击败根骸守卫"},
	"potion": {"name":"苔露药剂", "kind":"consumable", "icon":"potion", "rarity":2, "effect":"恢复 3 点生命。满生命时不消耗。", "lore":"从苔藓中收集的温和露滴。", "source":"探索行囊、战斗收集或制作"},
	"ether": {"name":"灵息露", "kind":"consumable", "icon":"flask", "rarity":3, "effect":"恢复 65 点灵息。灵息已满时不消耗。", "lore":"瓶中盛着微凉的蓝光。", "source":"探索行囊、机关奖励或制作"},
	"bomb": {"name":"爆破种子", "kind":"consumable", "icon":"bomb", "rarity":3, "effect":"向前投掷，短暂延迟后造成 5 点范围伤害。", "lore":"坚硬的种壳包裹着灼热的生命。", "source":"探索行囊、战斗收集或制作"},
	"frost": {"name":"寒霜瓶", "kind":"consumable", "icon":"ice", "rarity":3, "effect":"冻结附近敌人，并生成持续 14 秒的冰桥。", "lore":"瓶口结着一圈不会融化的细霜。", "source":"水道遗物或制作"},
	"fiber": {"name":"苔丝纤维", "kind":"material", "icon":"leaf", "rarity":1, "effect":"制作药剂与灵息露的材料。", "lore":"来自遗境生物的柔韧细丝。", "source":"击败遗境中的怪物"},
	"ore": {"name":"鸣雷碎矿", "kind":"material", "icon":"ore", "rarity":2, "effect":"制作爆破种子、寒霜瓶与灵息露。", "lore":"断面中偶尔闪过细小的电光。", "source":"击败怪物或激活矿井机关"},
	"fire": {"name":"余烬灵印", "kind":"ability", "icon":"fire", "rarity":4, "effect":"唤出火焰，点燃敌人并焚毁荆棘。", "lore":"古树仍记得阳光的温度。", "source":"庭院上层平台或荆棘书库"},
	"ice": {"name":"寒霜灵印", "kind":"ability", "icon":"ice", "rarity":4, "effect":"冻结敌人与深水，创造临时通路。", "lore":"沉水之下，时间缓缓凝结。", "source":"沉水回廊 · 水池前的残响"},
	"lightning": {"name":"鸣雷灵印", "kind":"ability", "icon":"bolt", "rarity":4, "effect":"电击敌人，沿水传导并唤醒灵石。", "lore":"听见水中的雷声了吗？", "source":"鸣雷矿井 · 水池西岸"},
	"heal": {"name":"回春之种", "kind":"ability", "icon":"heal", "rarity":4, "effect":"消耗 45 灵息，恢复 2 点生命。", "lore":"微光从未真正熄灭。", "source":"苔息庭院 · 旧路深处"}
}
const RECIPES = {"potion":{"fiber":3}, "ether":{"fiber":2,"ore":1}, "bomb":{"ore":2}, "frost":{"fiber":1,"ore":2}}
const REGIONS = [
	{"name":"苔息庭院","en":"THE MOSS GARDEN","tag":"遗忘之森 · 01","type":"garden","width":1840,"color":"264e42","left":-1,"right":1,"map":[100,260,260,115],"floor":[[0,1840]],"platforms":[[600,480,180],[870,380,190],[1170,465,180]],"camp":430,"enemies":[[1110,"crawler"],[1480,"crawler"]],"objects":[["sword",530,590],["fire",720,480],["heal",1580,590],["supply_garden",920,590],["portal_grotto",970,380]]},
	{"name":"沉水回廊","en":"THE SUNKEN HALL","tag":"旧日水道 · 02","type":"water","width":1960,"color":"285260","left":0,"right":2,"map":[440,260,275,115],"floor":[[0,680],[1080,880]],"platforms":[[280,475,180],[1320,450,180]],"pool":[680,1080],"enemies":[[1490,"crawler"],[1750,"spore"]],"objects":[["ice",520,590],["ice",1130,590],["bow",1250,590],["supply_water",1400,450]]},
	{"name":"荆棘书库","en":"THE THORN ARCHIVE","tag":"失落圣所 · 03","type":"library","width":1800,"color":"3c5048","left":1,"right":3,"map":[790,260,255,115],"floor":[[0,1800]],"platforms":[[410,465,170],[1180,455,170]],"camp":250,"enemies":[[660,"crawler"],[1230,"spore"],[1560,"crawler"]],"objects":[["ice",350,590],["fire",600,590],["vines",930,590]]},
	{"name":"鸣雷矿井","en":"THE THUNDER DEPTHS","tag":"灵石矿脉 · 04","type":"mine","width":1840,"color":"424260","left":2,"right":5,"map":[790,480,260,115],"floor":[[0,600],[940,900]],"platforms":[[270,460,170],[1090,430,140]],"pool":[600,940],"enemies":[[420,"crawler"],[1300,"spore"]],"objects":[["lightning",390,590],["ice",1050,590],["conductor",1175,590],["gate",1490,590],["supply_mine",1250,590]]},
	{"name":"月孢洞窟","en":"THE MOONSPORE GROTTO","tag":"隐秘支路 · 05","type":"grotto","width":1500,"color":"2f5861","left":-1,"right":-1,"map":[100,40,260,115],"floor":[[0,1500]],"platforms":[[430,500,180],[650,415,180],[870,330,240]],"enemies":[[600,"spore"]],"objects":[["moonwing",980,330],["portal_garden",145,590]]},
	{"name":"古树心室","en":"THE ANCIENT HEART","tag":"根脉深处 · 06","type":"heart","width":1600,"color":"45543b","left":3,"right":-1,"map":[1130,480,260,115],"floor":[[0,1600]],"platforms":[[210,455,160],[1260,455,160]],"camp":140,"enemies":[[1070,"warden"]],"objects":[["portal_return",1440,590]]}
]
const LINKS = [[0,1],[1,2],[2,3],[0,4],[3,5]]
const SUPPLIES = {"supply_garden":{"potion":2,"bomb":2,"ether":1},"supply_water":{"frost":2,"ether":1,"potion":1},"supply_mine":{"bomb":2,"potion":2,"ore":3}}
const REWARDS = {"vines":{"amber":1,"fiber":3},"gate":{"stonevest":1,"ore":4,"ether":2},"boss":{"thornring":1,"bomb":3,"potion":3}}

static func region(id: int) -> Dictionary:
	return REGIONS[clampi(id, 0, REGIONS.size() - 1)]

static func color(element: String) -> Color:
	return COLORS.get(element, Color("d7dfb7"))

static func objectives(id: int) -> Array:
	match id:
		0: return [["sword","发现旅者短刃"],["fire","发现余烬灵印"],["heal","发现回春之种"],["supply_garden","收集旧日行囊"],["rest","点亮庭院篝火"]]
		1: return [["ice","发现寒霜灵印"],["bow","找到古木长弓"],["supply_water","收集水道遗物"]]
		2: return [["vines","焚开封路荆棘"],["amber","收集余烬琥珀"]]
		3: return [["lightning","发现鸣雷灵印"],["gate","唤醒鸣雷机关"],["supply_mine","收集矿工遗物"]]
		4: return [["moonwing","发现月孢之翼"]]
		_: return [["boss","击败根骸守卫"],["thornring","收集根脉灵环"]]
