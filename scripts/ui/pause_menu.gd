extends Control

@onready var resume_btn: Button = $Panel/VBoxContainer/ResumeButton
@onready var restart_btn: Button = $Panel/VBoxContainer/RestartButton
@onready var shop_btn: Button = $Panel/VBoxContainer/ShopButton
@onready var menu_btn: Button = $Panel/VBoxContainer/MenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_btn.pressed.connect(_on_resume_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)
	if shop_btn:
		shop_btn.pressed.connect(_on_shop_pressed)

func _on_shop_pressed() -> void:
	var hud = get_parent()
	if hud and hud.has_node("ShopMenu"):
		hud.get_node("ShopMenu").open()

func _on_resume_pressed() -> void:
	get_tree().paused = false
	visible = false

func _on_restart_pressed() -> void:
	get_tree().paused = false
	visible = false
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.start_level(gm.current_level_index)

func _on_menu_pressed() -> void:
	get_tree().paused = false
	visible = false
	if has_node("/root/ScreenTransition"):
		get_node("/root/ScreenTransition").change_scene_to_file("res://scenes/ui/main_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
