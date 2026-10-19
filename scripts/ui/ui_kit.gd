class_name UI
extends RefCounted
const IVORY = Color("eeebd9")
const MUTED = Color("a8c1b1")
const PAPER = Color("eae5d5")
const INK = Color("4b6053")
const GOLD = Color("e3d1a4")
static var shared_font: Font
static var shared_theme: Theme
static var icons: Dictionary = {}

static func safe_insets() -> Vector4:
	if OS.get_name() not in ["Android","iOS"]:
		return Vector4.ZERO
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var window: Vector2i = DisplayServer.window_get_size()
	if safe.size==Vector2i.ZERO or window.x<=0 or window.y<=0:
		return Vector4.ZERO
	var tree = Engine.get_main_loop() as SceneTree
	var viewport_size: Vector2 = tree.root.get_visible_rect().size
	var ratio = viewport_size/Vector2(window)
	return Vector4(maxf(0,safe.position.x)*ratio.x,maxf(0,safe.position.y)*ratio.y,maxf(0,window.x-safe.end.x)*ratio.x,maxf(0,window.y-safe.end.y)*ratio.y)

static func font() -> Font:
	if shared_font==null:
		if ResourceLoader.exists("res://assets/fonts/MosslightUI.otf"):
			shared_font = load("res://assets/fonts/MosslightUI.otf")
		else:
			var system = SystemFont.new()
			system.font_names = PackedStringArray(["Noto Sans CJK SC","Microsoft YaHei","PingFang SC","sans-serif"])
			shared_font = system
	return shared_font

static func icon(id: String) -> Texture2D:
	if id.is_empty(): return null
	if not icons.has(id): icons[id] = load("res://assets/icons/"+id+".svg")
	return icons[id]

static func box(color: Color, radius: int = 4, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = border
	style.set_border_width_all(1 if border.a>0 else 0)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

static func theme() -> Theme:
	if shared_theme: return shared_theme
	var t = Theme.new()
	t.default_font = font()
	t.default_font_size = 20
	t.set_color("font_color","Label",IVORY)
	t.set_color("default_color","RichTextLabel",IVORY)
	t.set_stylebox("normal","Button",box(Color("d6e1c410"),28))
	t.set_stylebox("hover","Button",box(Color("d6e1c428"),28))
	t.set_stylebox("pressed","Button",box(Color("cbd9b743"),28))
	t.set_stylebox("disabled","Button",box(Color("d6e1c407"),28))
	t.set_stylebox("focus","Button",box(Color.TRANSPARENT,28,GOLD))
	t.set_color("font_color","Button",IVORY)
	t.set_color("font_hover_color","Button",Color("fff0c8"))
	t.set_color("font_disabled_color","Button",Color("95a79566"))
	t.set_constant("h_separation","Button",12)
	t.set_font_size("font_size","Button",20)
	t.set_stylebox("panel","TooltipPanel",box(Color("153d36f5"),5,Color("b6c8a655")))
	t.set_color("font_color","TooltipLabel",IVORY)
	t.set_font_size("font_size","TooltipLabel",17)
	var track = box(Color("c9d7b633"),3)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	t.set_stylebox("slider","HSlider",track)
	t.set_icon("grabber","HSlider",icon("slider_dot"))
	t.set_icon("grabber_highlight","HSlider",icon("slider_dot"))
	t.set_icon("checked","CheckButton",icon("toggle_on"))
	t.set_icon("unchecked","CheckButton",icon("toggle_off"))
	t.set_stylebox("scroll","VScrollBar",box(Color("d8e1ca08"),2))
	t.set_stylebox("grabber","VScrollBar",box(Color("b4c9ae77"),2))
	t.set_stylebox("grabber_highlight","VScrollBar",box(Color("c9d9b799"),2))
	shared_theme = t
	return t

static func label(text: String, size: int = 20, color: Color = IVORY) -> Label:
	var node = Label.new()
	node.text = text
	node.add_theme_font_override("font",font())
	node.add_theme_font_size_override("font_size",size)
	node.add_theme_color_override("font_color",color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func prose(text: String, size: int = 20, color: Color = MUTED) -> Label:
	var node = label(text,size,color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node

static func button(text: String, callback: Callable, icon_id: String = "", primary: bool = false) -> Button:
	var node = Button.new()
	node.text = text
	node.custom_minimum_size = Vector2(0,54)
	node.icon = icon(icon_id)
	node.expand_icon = true
	node.add_theme_constant_override("icon_max_width",26)
	node.pressed.connect(callback)
	node.pressed.connect(func(): Events.sound.emit("ui"))
	if primary:
		node.add_theme_stylebox_override("normal",box(Color("ddd5b9"),28))
		node.add_theme_stylebox_override("hover",box(Color("f2e8c9"),28))
		node.add_theme_stylebox_override("pressed",box(Color("c6c5a8"),28))
		node.add_theme_color_override("font_color",INK)
		node.add_theme_color_override("font_hover_color",INK)
		node.add_theme_color_override("icon_normal_color",INK)
		node.add_theme_color_override("icon_hover_color",INK)
	return node

static func icon_button(id: String, tooltip: String, callback: Callable, size: int = 64) -> Button:
	var node = button("",callback,id)
	node.custom_minimum_size = Vector2(size,size)
	node.add_theme_constant_override("icon_max_width",int(size*.46))
	node.tooltip_text = tooltip
	return node

static func column(gap: int = 14) -> VBoxContainer:
	var node = VBoxContainer.new()
	node.add_theme_constant_override("separation",gap)
	return node

static func row(gap: int = 14) -> HBoxContainer:
	var node = HBoxContainer.new()
	node.add_theme_constant_override("separation",gap)
	return node

static func pad(child: Control, amount: int = 22) -> MarginContainer:
	var node = MarginContainer.new()
	for side in ["left","right","top","bottom"]: node.add_theme_constant_override("margin_"+side,amount)
	node.add_child(child)
	return node

static func panel(child: Control, color: Color = PAPER) -> PanelContainer:
	var node = PanelContainer.new()
	node.add_theme_stylebox_override("panel",box(color,5))
	node.add_child(child)
	return node

static func scroll(child: Control) -> ScrollContainer:
	var node = ScrollContainer.new()
	node.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.add_child(child)
	node.follow_focus = true
	return node

static func texture(id: String, minimum: Vector2 = Vector2(64,64)) -> TextureRect:
	var node = TextureRect.new()
	node.texture = icon(id)
	node.custom_minimum_size = minimum
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func stretch(node: Control) -> void:
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
