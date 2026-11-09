extends Node2D
class_name LevelBase

@export var level_index: int = 1
@export var bgm_track: String = "level"
@export var camera_limit_left: int = 0
@export var camera_limit_top: int = -200
@export var camera_limit_right: int = 1600
@export var camera_limit_bottom: int = 350

var time_elapsed: float = 0.0
var is_level_active: bool = true

@onready var player: Player = $Player
@onready var camera: Camera2D = $GameCamera
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	add_to_group("level")
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.current_level_index = level_index
		gm.reset_level_stats()
		
	# Setup Camera
	if camera:
		camera.limit_left = camera_limit_left
		camera.limit_top = camera_limit_top
		camera.limit_right = camera_limit_right
		camera.limit_bottom = camera_limit_bottom
		if player:
			camera.target = player
			camera.global_position = player.global_position
			
	# Start Music
	var am = get_node_or_null("/root/AudioManager")
	if am and bgm_track != "":
		am.play_music(bgm_track)

func _process(delta: float) -> void:
	if not is_level_active:
		return
		
	time_elapsed += delta
	if hud and hud.has_method("update_timer"):
		hud.update_timer(time_elapsed)
		
	# Fall death boundary check
	if player and is_instance_valid(player) and not player.is_dead:
		if player.global_position.y > camera_limit_bottom + 50:
			player.take_damage(99)

func on_level_completed() -> void:
	if not is_level_active:
		return
	is_level_active = false
	
	var gm = get_node_or_null("/root/GameManager")
	var stats = {}
	if gm:
		stats = gm.complete_level(time_elapsed)
		
	if hud and hud.has_method("show_level_complete"):
		hud.show_level_complete(stats)
