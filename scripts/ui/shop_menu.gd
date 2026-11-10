extends Control

signal shop_closed()

# UI References
@onready var coin_label: Label = $Panel/VBox/HeaderHBox/CoinHBox/CoinLabel
@onready var items_container: VBoxContainer = $Panel/VBox/ScrollContainer/ItemsVBox
@onready var close_btn: Button = $Panel/VBox/FooterHBox/CloseBtn
@onready var info_label: Label = $Panel/VBox/FooterHBox/InfoLabel

# Tab Buttons
@onready var tab_stats_btn: Button = $Panel/VBox/TabsHBox/StatsTabBtn
@onready var tab_skills_btn: Button = $Panel/VBox/TabsHBox/SkillsTabBtn
@onready var tab_heroes_btn: Button = $Panel/VBox/TabsHBox/HeroesTabBtn

var current_tab: String = "stats"

# All Shop Items Catalog (16 varied options!)
const SHOP_ITEMS = [
	# --- STATS UPGRADES ---
	{
		"id": "health_level",
		"category": "stats",
		"name": "Heart Container (Vitality)",
		"desc": "+1 Max Heart permanently (Starts at 3, up to 6 hearts!).",
		"icon": "res://asset/Tiles/tile_0044.png",
		"is_tiered": true,
		"max_tier": 3,
		"costs": [100, 250, 450]
	},
	{
		"id": "speed_level",
		"category": "stats",
		"name": "Swift Feather Boots",
		"desc": "+15% movement run speed per upgrade level.",
		"icon": "res://asset/Tiles/tile_0107.png",
		"is_tiered": true,
		"max_tier": 3,
		"costs": [80, 180, 320]
	},
	{
		"id": "jump_level",
		"category": "stats",
		"name": "High Spring Coils",
		"desc": "+10% jump & double jump height per upgrade level.",
		"icon": "res://asset/Tiles/tile_0108.png",
		"is_tiered": true,
		"max_tier": 3,
		"costs": [90, 200, 350]
	},
	{
		"id": "dash_level",
		"category": "stats",
		"name": "Phantom Dash Mastery",
		"desc": "Reduces dash cooldown and grants invincibility frames during dash!",
		"icon": "res://asset/Tiles/tile_0086.png",
		"is_tiered": true,
		"max_tier": 3,
		"costs": [120, 260, 420]
	},
	{
		"id": "magnet_level",
		"category": "stats",
		"name": "Greed Magnet Aura",
		"desc": "Strongly pulls distant gold coins toward the player automatically.",
		"icon": "res://asset/Tiles/tile_0151.png",
		"is_tiered": true,
		"max_tier": 3,
		"costs": [70, 150, 280]
	},

	# --- SKILLS & CHARMS ---
	{
		"id": "midas_touch",
		"category": "skills",
		"name": "Midas Touch (2x Coins)",
		"desc": "Every gold coin collected permanently counts as TWO coins!",
		"icon": "res://asset/Tiles/tile_0067.png",
		"is_tiered": false,
		"cost": 250
	},
	{
		"id": "triple_jump",
		"category": "skills",
		"name": "Triple Jump Feather",
		"desc": "Allows an extra 3rd jump in mid-air! Reach secret areas with ease.",
		"icon": "res://asset/Tiles/tile_0111.png",
		"is_tiered": false,
		"cost": 280
	},
	{
		"id": "shockwave_slam",
		"category": "skills",
		"name": "Earthquake Slam",
		"desc": "Down-slam attacks unleash an earth shockwave that damages ground monsters!",
		"icon": "res://asset/Tiles/tile_0051.png",
		"is_tiered": false,
		"cost": 220
	},
	{
		"id": "guardian_shield",
		"category": "skills",
		"name": "Guardian Angel Shield",
		"desc": "Grants an energy shield at the start of each level that absorbs 1 hit!",
		"icon": "res://asset/Tiles/tile_0028.png",
		"is_tiered": false,
		"cost": 300
	},
	{
		"id": "skeleton_key",
		"category": "skills",
		"name": "Skeleton Key Charm",
		"desc": "Start every puzzle level already holding 1 Key, skipping door locks!",
		"icon": "res://asset/Tiles/tile_0027.png",
		"is_tiered": false,
		"cost": 180
	},
	{
		"id": "checkpoint_charm",
		"category": "skills",
		"name": "Guardian Checkpoint Charm",
		"desc": "Always activates an initial safety checkpoint automatically.",
		"icon": "res://asset/Tiles/tile_0112.png",
		"is_tiered": false,
		"cost": 90
	},

	# --- HERO SKINS (Choose & Equip your hero) ---
	{
		"id": "hero_0",
		"category": "heroes",
		"skin_id": 0,
		"name": "Green Adventurer",
		"desc": "The classic brave green explorer.",
		"icon": "res://asset/Tiles/Characters/tile_0000.png",
		"is_tiered": false,
		"cost": 0
	},
	{
		"id": "hero_1",
		"category": "heroes",
		"skin_id": 1,
		"name": "Pink Sprinter",
		"desc": "Agile rose pixel runner.",
		"icon": "res://asset/Tiles/Characters/tile_0004.png",
		"is_tiered": false,
		"cost": 0
	},
	{
		"id": "hero_2",
		"category": "heroes",
		"skin_id": 2,
		"name": "Blue Jumper",
		"desc": "Energetic azure acrobatic hero.",
		"icon": "res://asset/Tiles/Characters/tile_0002.png",
		"is_tiered": false,
		"cost": 0
	},
	{
		"id": "hero_3",
		"category": "heroes",
		"skin_id": 3,
		"name": "Golden Dasher",
		"desc": "Swift golden adventurer.",
		"icon": "res://asset/Tiles/Characters/tile_0006.png",
		"is_tiered": false,
		"cost": 0
	},
	{
		"id": "skin_4",
		"category": "heroes",
		"skin_id": 4,
		"name": "Shadow Ninja",
		"desc": "Stealthy purple ninja operative hero.",
		"icon": "res://asset/Tiles/Characters/tile_0008.png",
		"is_tiered": false,
		"cost": 150
	}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	close_btn.pressed.connect(_on_close_pressed)
	tab_stats_btn.pressed.connect(func(): _switch_tab("stats"))
	tab_skills_btn.pressed.connect(func(): _switch_tab("skills"))
	tab_heroes_btn.pressed.connect(func(): _switch_tab("heroes"))
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.coins_changed.connect(_update_coin_display)
		_update_coin_display(gm.coins)

func open() -> void:
	visible = true
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		_update_coin_display(gm.coins)
	_switch_tab(current_tab)

func _on_close_pressed() -> void:
	visible = false
	emit_signal("shop_closed")

func _update_coin_display(amount: int) -> void:
	coin_label.text = str(amount)

func _switch_tab(tab_name: String) -> void:
	current_tab = tab_name
	
	tab_stats_btn.modulate = Color(1.3, 1.3, 0.7) if tab_name == "stats" else Color(0.8, 0.8, 0.8)
	tab_skills_btn.modulate = Color(1.3, 1.3, 0.7) if tab_name == "skills" else Color(0.8, 0.8, 0.8)
	tab_heroes_btn.modulate = Color(1.3, 1.3, 0.7) if tab_name == "heroes" else Color(0.8, 0.8, 0.8)
	
	_render_items()

func _render_items() -> void:
	# Clear previous items
	for ch in items_container.get_children():
		ch.queue_free()
		
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
		
	for item in SHOP_ITEMS:
		if item["category"] != current_tab:
			continue
			
		var card = _create_item_card(item, gm)
		items_container.add_child(card)

func _create_item_card(item: Dictionary, gm: Node) -> Control:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.17, 0.26, 0.95)
	style.border_color = Color(0.28, 0.35, 0.52, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)
	
	# Icon
	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(24, 24)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(item["icon"]):
		icon_rect.texture = load(item["icon"])
	hbox.add_child(icon_rect)
	
	# Text Info (VBox)
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 1)
	hbox.add_child(vbox)
	
	var title_lbl = Label.new()
	title_lbl.add_theme_font_size_override("font_size", 9)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	
	var desc_lbl = Label.new()
	desc_lbl.add_theme_font_size_override("font_size", 7)
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	desc_lbl.text = item["desc"]
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	vbox.add_child(title_lbl)
	vbox.add_child(desc_lbl)
	
	# Action / Buy Button
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 24)
	btn.add_theme_font_size_override("font_size", 8)
	hbox.add_child(btn)
	
	# State resolution
	if item.get("is_tiered", false):
		var cur_tier = gm.get_upgrade_level(item["id"])
		var max_tier = item["max_tier"]
		title_lbl.text = "%s [Lv %d/%d]" % [item["name"], cur_tier, max_tier]
		
		if cur_tier >= max_tier:
			btn.text = "MAXED"
			btn.disabled = true
		else:
			var cost = item["costs"][cur_tier]
			btn.text = "%d COINS" % cost
			btn.disabled = (gm.coins < cost)
			btn.pressed.connect(func(): _on_buy_tiered_clicked(item, cost))
	elif item["category"] == "heroes":
		var skin_id = item["skin_id"]
		var unlocked_skins: Array = gm.shop_upgrades.get("unlocked_skins", [0, 1, 2, 3])
		var is_unlocked = unlocked_skins.has(skin_id) or item.get("cost", 0) == 0
		var is_active = (gm.selected_character == skin_id)
		
		title_lbl.text = item["name"]
		if is_active:
			btn.text = "ACTIVE"
			btn.disabled = true
			btn.modulate = Color(0.5, 1.2, 0.5)
		elif is_unlocked:
			btn.text = "EQUIP"
			btn.disabled = false
			btn.pressed.connect(func(): _on_equip_skin_clicked(skin_id))
		else:
			var cost = item["cost"]
			btn.text = "%d COINS" % cost
			btn.disabled = (gm.coins < cost)
			btn.pressed.connect(func(): _on_buy_skin_clicked(item, cost, skin_id))
	else: # Unique Skills
		var is_owned = gm.has_upgrade(item["id"])
		title_lbl.text = item["name"]
		
		if is_owned:
			btn.text = "EQUIPPED"
			btn.disabled = true
			btn.modulate = Color(0.5, 1.2, 0.5)
		else:
			var cost = item["cost"]
			btn.text = "%d COINS" % cost
			btn.disabled = (gm.coins < cost)
			btn.pressed.connect(func(): _on_buy_skill_clicked(item, cost))
			
	return panel

func _on_buy_tiered_clicked(item: Dictionary, cost: int) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.buy_upgrade(item["id"], cost, true, item["max_tier"]):
		_play_buy_sound()
		_show_feedback("Upgraded %s!" % item["name"], Color.GREEN)
		_render_items()
	else:
		_show_feedback("Not enough coins!", Color.RED)

func _on_buy_skill_clicked(item: Dictionary, cost: int) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.buy_upgrade(item["id"], cost, false):
		_play_buy_sound()
		_show_feedback("Unlocked %s!" % item["name"], Color.GREEN)
		_render_items()
	else:
		_show_feedback("Not enough coins!", Color.RED)

func _on_buy_skin_clicked(item: Dictionary, cost: int, skin_id: int) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.buy_skin(skin_id, cost):
		_play_buy_sound()
		_show_feedback("Unlocked & Equipped %s!" % item["name"], Color.GREEN)
		_render_items()
	else:
		_show_feedback("Not enough coins!", Color.RED)

func _on_equip_skin_clicked(skin_id: int) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.selected_character = skin_id
		gm.save_game()
		var am = get_node_or_null("/root/AudioManager")
		if am:
			am.play_sfx("jump")
		_show_feedback("Equipped Hero Skin!", Color.YELLOW)
		_render_items()

func _play_buy_sound() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("coin")

func _show_feedback(txt: String, col: Color) -> void:
	info_label.text = txt
	info_label.modulate = col
	var tween = info_label.create_tween()
	tween.tween_property(info_label, "scale", Vector2(1.1, 1.1), 0.08)
	tween.tween_property(info_label, "scale", Vector2.ONE, 0.08)
