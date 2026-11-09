extends Control

@onready var respawn_btn: Button = $Panel/VBoxContainer/RespawnButton
@onready var restart_btn: Button = $Panel/VBoxContainer/RestartButton
@onready var menu_btn: Button = $Panel/VBoxContainer/MenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	respawn_btn.pressed.connect(_on_respawn_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)
	
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if visible:
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_checkpoint:
			respawn_btn.visible = true
		else:
			respawn_btn.visible = false

func _on_respawn_pressed() -> void:
	visible = false
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("_respawn_at_checkpoint"):
		player._respawn_at_checkpoint()

func _on_restart_pressed() -> void:
	visible = false
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.start_level(gm.current_level_index)

func _on_menu_pressed() -> void:
	visible = false
	if has_node("/root/ScreenTransition"):
		get_node("/root/ScreenTransition").change_scene_to_file("res://scenes/ui/main_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
