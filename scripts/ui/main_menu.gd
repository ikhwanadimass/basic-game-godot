extends Control

# Panels
@onready var main_buttons_panel: VBoxContainer = $CenterContainer/MainButtons
@onready var level_select_panel: Panel = $Modals/LevelSelectPanel
@onready var settings_panel: Panel = $Modals/SettingsPanel
@onready var controls_panel: Panel = $Modals/ControlsPanel

# Main Buttons
@onready var play_btn: Button = $CenterContainer/MainButtons/PlayButton
@onready var levels_btn: Button = $CenterContainer/MainButtons/LevelsButton
@onready var shop_btn: Button = $CenterContainer/MainButtons/ShopButton
@onready var settings_btn: Button = $CenterContainer/MainButtons/SettingsButton
@onready var controls_btn: Button = $CenterContainer/MainButtons/ControlsButton
@onready var shop_menu: Control = $Modals/ShopMenu

# Level Select Grid
@onready var scroll_container: ScrollContainer = $Modals/LevelSelectPanel/VBox/ScrollContainer
@onready var levels_grid: GridContainer = $Modals/LevelSelectPanel/VBox/ScrollContainer/LevelsGrid
@onready var close_levels_btn: Button = $Modals/LevelSelectPanel/VBox/CloseLevelsBtn

# Character Preview
@onready var current_hero_preview: TextureRect = $CenterContainer/MainButtons/HeroPreview

# Settings Controls
@onready var music_slider: HSlider = $Modals/SettingsPanel/VBox/MusicHBox/MusicSlider
@onready var sfx_slider: HSlider = $Modals/SettingsPanel/VBox/SfxHBox/SfxSlider
@onready var shake_check: CheckBox = $Modals/SettingsPanel/VBox/ShakeHBox/ShakeCheck
@onready var fullscreen_btn: Button = $Modals/SettingsPanel/VBox/FullscreenBtn
@onready var close_settings_btn: Button = $Modals/SettingsPanel/VBox/CloseSettingsBtn
@onready var close_controls_btn: Button = $Modals/ControlsPanel/VBox/CloseControlsBtn

const HERO_TEXTURES = [
	"res://asset/Tiles/Characters/tile_0000.png",
	"res://asset/Tiles/Characters/tile_0004.png",
	"res://asset/Tiles/Characters/tile_0002.png",
	"res://asset/Tiles/Characters/tile_0006.png",
	"res://asset/Tiles/Characters/tile_0008.png"
]

func _ready() -> void:
	# Hide all modals
	level_select_panel.visible = false
	settings_panel.visible = false
	controls_panel.visible = false
	
	# Connect Main Buttons
	play_btn.pressed.connect(_on_play_pressed)
	levels_btn.pressed.connect(_open_level_select)
	if shop_btn:
		shop_btn.pressed.connect(_open_shop)
	settings_btn.pressed.connect(_open_settings)
	controls_btn.pressed.connect(_open_controls)
	
	if shop_menu:
		shop_menu.shop_closed.connect(_on_shop_closed)
	
	# Setup 50 Level Buttons & World Navigation
	_setup_world_tabs()
	_setup_50_level_buttons()
	_setup_extra_settings()
	close_levels_btn.pressed.connect(func(): level_select_panel.visible = false)
	
	# Connect Settings
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		music_slider.value = gm.music_volume * 100.0
		sfx_slider.value = gm.sfx_volume * 100.0
		shake_check.button_pressed = gm.screen_shake_enabled
		_update_hero_preview(gm.selected_character)
		
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	shake_check.toggled.connect(_on_shake_toggled)
	fullscreen_btn.pressed.connect(_toggle_fullscreen)
	close_settings_btn.pressed.connect(func(): settings_panel.visible = false)
	close_controls_btn.pressed.connect(func(): controls_panel.visible = false)
	
	# Play Menu Chiptune
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_music("title")
		
	_refresh_level_buttons()

func _setup_50_level_buttons() -> void:
	for i in range(1, 51):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(56, 32)
		btn.add_theme_font_size_override("font_size", 8)
		var lvl_num = i
		btn.pressed.connect(func(): _start_level(lvl_num))
		levels_grid.add_child(btn)

func _on_play_pressed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	var target_lvl = gm.max_unlocked_level if gm else 1
	_start_level(target_lvl)

func _start_level(lvl: int) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("coin")
		am.stop_music()
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.start_level(lvl)

func _setup_world_tabs() -> void:
	var tabs_hbox = HBoxContainer.new()
	tabs_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs_hbox.add_theme_constant_override("separation", 3)
	var world_names = ["W1 (1-10)", "W2 (11-20)", "W3 (21-30)", "W4 (31-40)", "W5 (41-50)"]
	for w_idx in range(5):
		var w_btn = Button.new()
		w_btn.text = world_names[w_idx]
		w_btn.add_theme_font_size_override("font_size", 7)
		w_btn.custom_minimum_size = Vector2(58, 20)
		var start_row = w_idx * 2
		w_btn.pressed.connect(func(): _scroll_to_row(start_row))
		tabs_hbox.add_child(w_btn)
	var vbox = scroll_container.get_parent()
	vbox.add_child(tabs_hbox)
	vbox.move_child(tabs_hbox, scroll_container.get_index())

func _scroll_to_row(row_idx: int) -> void:
	if scroll_container:
		scroll_container.scroll_vertical = max(0, row_idx * 38)

func _open_level_select() -> void:
	_refresh_level_buttons()
	level_select_panel.visible = true
	var gm = get_node_or_null("/root/GameManager")
	var max_unlocked = gm.max_unlocked_level if gm else 1
	var target_row = (max_unlocked - 1) / 5
	call_deferred("_scroll_to_row", max(0, target_row - 1))

func _refresh_level_buttons() -> void:
	var gm = get_node_or_null("/root/GameManager")
	var max_unlocked = gm.max_unlocked_level if gm else 1
	var btns = levels_grid.get_children()
	for i in range(btns.size()):
		var lvl = i + 1
		var btn = btns[i] as Button
		if btn:
			btn.disabled = (lvl > max_unlocked)
			var stars = 0
			if gm and gm.level_records.has(lvl):
				stars = gm.level_records[lvl].get("stars", 0)
			
			var prefix = ""
			if lvl in [10, 20, 30, 40, 50]:
				prefix = "[B] "
			
			if stars > 0:
				var star_str = ""
				for s in range(stars):
					star_str += "★"
				btn.text = "%sLV %d\n%s" % [prefix, lvl, star_str]
			else:
				btn.text = "%sLV %d" % [prefix, lvl]
				
			if lvl == max_unlocked:
				btn.modulate = Color(1.2, 1.2, 0.8, 1.0)
			else:
				btn.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _setup_extra_settings() -> void:
	var vbox = settings_panel.get_node_or_null("VBox")
	if vbox and close_settings_btn:
		var unlock_btn = Button.new()
		unlock_btn.text = "UNLOCK ALL LEVELS (TEST 1-50)"
		unlock_btn.add_theme_font_size_override("font_size", 9)
		unlock_btn.pressed.connect(_on_unlock_all_levels)
		
		var reset_btn = Button.new()
		reset_btn.text = "RESET PROGRESS TO LV 1"
		reset_btn.add_theme_font_size_override("font_size", 9)
		reset_btn.pressed.connect(_on_reset_progress)
		
		var close_idx = close_settings_btn.get_index()
		vbox.add_child(unlock_btn)
		vbox.move_child(unlock_btn, close_idx)
		vbox.add_child(reset_btn)
		vbox.move_child(reset_btn, close_idx + 1)

func _on_unlock_all_levels() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.max_unlocked_level = 50
		gm.save_game()
		_refresh_level_buttons()
	settings_panel.visible = false
	_open_level_select()

func _on_reset_progress() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.max_unlocked_level = 1
		gm.level_records.clear()
		gm._init_level_records()
		gm.save_game()
		_refresh_level_buttons()
	settings_panel.visible = false
	_open_level_select()

func _open_shop() -> void:
	if shop_menu:
		shop_menu.open()

func _on_shop_closed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		_update_hero_preview(gm.selected_character)

func _update_hero_preview(idx: int) -> void:
	if idx >= 0 and idx < HERO_TEXTURES.size():
		current_hero_preview.texture = load(HERO_TEXTURES[idx])

func _open_settings() -> void:
	settings_panel.visible = true

func _open_controls() -> void:
	controls_panel.visible = true

func _on_music_volume_changed(val: float) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.music_volume = val / 100.0
		gm.save_game()

func _on_sfx_volume_changed(val: float) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.sfx_volume = val / 100.0
		gm.save_game()

func _on_shake_toggled(toggled: bool) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.screen_shake_enabled = toggled
		gm.save_game()

func _toggle_fullscreen() -> void:
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
