extends CanvasLayer

@onready var hearts_container: HBoxContainer = $MarginContainer/TopBar/LeftSection/HeartsContainer
@onready var coins_label: Label = $MarginContainer/TopBar/LeftSection/CoinBox/CoinsLabel
@onready var keys_box: HBoxContainer = $MarginContainer/TopBar/LeftSection/KeyBox
@onready var keys_label: Label = $MarginContainer/TopBar/LeftSection/KeyBox/KeysLabel
@onready var gems_container: HBoxContainer = $MarginContainer/TopBar/CenterSection/GemsContainer
@onready var timer_label: Label = $MarginContainer/TopBar/RightSection/TimerLabel

# Boss bar
@onready var boss_bar_container: VBoxContainer = $BossBarContainer
@onready var boss_health_bar: ProgressBar = $BossBarContainer/BossProgressBar
@onready var boss_name_label: Label = $BossBarContainer/BossNameLabel

# Overlays
@onready var pause_menu: Control = $PauseMenu
@onready var level_complete_menu: Control = $LevelCompleteMenu
@onready var game_over_menu: Control = $GameOverMenu

const HEART_FULL_TEX = "res://asset/Tiles/tile_0044.png"
const HEART_EMPTY_TEX = "res://asset/Tiles/tile_0045.png"

func _ready() -> void:
	add_to_group("hud")
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.health_changed.connect(_on_health_changed)
		gm.coins_changed.connect(_on_coins_changed)
		gm.gems_changed.connect(_on_gems_changed)
		gm.keys_changed.connect(_on_keys_changed)
		gm.boss_health_changed.connect(_on_boss_health_changed)
		_update_all(gm)
		
	boss_bar_container.visible = false
	pause_menu.visible = false
	level_complete_menu.visible = false
	game_over_menu.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		toggle_pause()

func toggle_pause() -> void:
	if level_complete_menu.visible or game_over_menu.visible:
		return
	var is_paused = not get_tree().paused
	get_tree().paused = is_paused
	pause_menu.visible = is_paused

func update_timer(time_seconds: float) -> void:
	var mins = int(time_seconds) / 60
	var secs = int(time_seconds) % 60
	var tenths = int((time_seconds - floor(time_seconds)) * 10)
	timer_label.text = "%02d:%02d.%d" % [mins, secs, tenths]

func _update_all(gm: Node) -> void:
	_on_health_changed(gm.health, gm.max_health)
	_on_coins_changed(gm.coins)
	_on_keys_changed(gm.keys)
	for i in range(3):
		_on_gems_changed(i, gm.current_level_gems[i])

func _on_health_changed(cur_hp: int, max_hp: int) -> void:
	var hearts = hearts_container.get_children()
	for i in range(hearts.size()):
		var heart_rect = hearts[i] as TextureRect
		if heart_rect:
			heart_rect.texture = load(HEART_FULL_TEX if i < cur_hp else HEART_EMPTY_TEX)
			heart_rect.modulate = Color.WHITE if i < cur_hp else Color(0.6, 0.6, 0.6, 0.5)

func _on_coins_changed(new_coins: int) -> void:
	coins_label.text = str(new_coins)
	# Pulse animation
	var tween = coins_label.create_tween()
	tween.tween_property(coins_label, "scale", Vector2(1.2, 1.2), 0.08)
	tween.tween_property(coins_label, "scale", Vector2.ONE, 0.08)

func _on_keys_changed(new_keys: int) -> void:
	keys_box.visible = (new_keys > 0)
	keys_label.text = str(new_keys)

func _on_gems_changed(gem_idx: int, collected: bool) -> void:
	var gem_icons = gems_container.get_children()
	if gem_idx >= 0 and gem_idx < gem_icons.size():
		var gem_rect = gem_icons[gem_idx] as TextureRect
		if gem_rect:
			gem_rect.modulate = Color.WHITE if collected else Color(0.3, 0.3, 0.3, 0.4)
			if collected:
				var tween = gem_rect.create_tween()
				tween.tween_property(gem_rect, "scale", Vector2(1.3, 1.3), 0.1)
				tween.tween_property(gem_rect, "scale", Vector2.ONE, 0.1)

func _on_boss_health_changed(cur_hp: int, max_hp: int) -> void:
	boss_bar_container.visible = (cur_hp > 0)
	boss_health_bar.max_value = max_hp
	boss_health_bar.value = cur_hp

func show_level_complete(stats: Dictionary = {}) -> void:
	level_complete_menu.visible = true
	if level_complete_menu.has_method("setup_stats"):
		level_complete_menu.setup_stats(stats)

func show_game_over() -> void:
	game_over_menu.visible = true

func show_victory() -> void:
	if has_node("/root/ScreenTransition"):
		get_node("/root/ScreenTransition").change_scene_to_file("res://scenes/ui/victory_screen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/victory_screen.tscn")
