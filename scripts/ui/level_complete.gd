extends Control

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var stats_label: Label = $Panel/VBoxContainer/StatsLabel
@onready var stars_container: HBoxContainer = $Panel/VBoxContainer/StarsContainer
@onready var next_btn: Button = $Panel/VBoxContainer/ButtonsHBox/NextButton
@onready var replay_btn: Button = $Panel/VBoxContainer/ButtonsHBox/ReplayButton
@onready var menu_btn: Button = $Panel/VBoxContainer/ButtonsHBox/MenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	next_btn.pressed.connect(_on_next_pressed)
	replay_btn.pressed.connect(_on_replay_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)

func setup_stats(stats: Dictionary) -> void:
	var stars = stats.get("stars", 1)
	var time_val = stats.get("time", 0.0)
	var coins_val = stats.get("coins", 0)
	var gems_count = stats.get("gems_count", 0)
	var level_num = stats.get("level", 1)
	
	title_label.text = "LEVEL " + str(level_num) + " COMPLETE!"
	var mins = int(time_val) / 60
	var secs = int(time_val) % 60
	var tenths = int((time_val - floor(time_val)) * 10)
	var time_str = "%02d:%02d.%d" % [mins, secs, tenths]
	
	stats_label.text = "Time: " + time_str + "\nCoins: " + str(coins_val) + "\nGems: " + str(gems_count) + "/3"
	
	# Update Star icons
	var star_nodes = stars_container.get_children()
	for i in range(star_nodes.size()):
		var star_icon = star_nodes[i] as TextureRect
		if star_icon:
			star_icon.modulate = Color.YELLOW if i < stars else Color(0.3, 0.3, 0.3, 0.4)
			
	if level_num >= 50:
		next_btn.text = "FINAL VICTORY!"
	else:
		next_btn.text = "NEXT LEVEL"

func _on_next_pressed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		if gm.current_level_index < 50:
			gm.start_level(gm.current_level_index + 1)
		else:
			if has_node("/root/ScreenTransition"):
				get_node("/root/ScreenTransition").change_scene_to_file("res://scenes/ui/victory_screen.tscn")
			else:
				get_tree().change_scene_to_file("res://scenes/ui/victory_screen.tscn")

func _on_replay_pressed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.start_level(gm.current_level_index)

func _on_menu_pressed() -> void:
	if has_node("/root/ScreenTransition"):
		get_node("/root/ScreenTransition").change_scene_to_file("res://scenes/ui/main_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
