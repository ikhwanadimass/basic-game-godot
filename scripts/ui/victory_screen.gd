extends Control

@onready var stats_label: Label = $VBoxContainer/StatsLabel
@onready var play_again_btn: Button = $VBoxContainer/PlayAgainButton
@onready var menu_btn: Button = $VBoxContainer/MenuButton

func _ready() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_music("title")
		
	var gm = get_node_or_null("/root/GameManager")
	var total_score = gm.score if gm else 0
	var total_coins = gm.coins if gm else 0
	
	stats_label.text = "You defeated The Stone Guardian!\n\nFinal Score: %d\nTotal Coins: %d" % [total_score, total_coins]
	
	play_again_btn.pressed.connect(_on_play_again_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)

func _on_play_again_pressed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.start_level(1)

func _on_menu_pressed() -> void:
	if has_node("/root/ScreenTransition"):
		get_node("/root/ScreenTransition").change_scene_to_file("res://scenes/ui/main_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
