extends Camera2D

@export var target_path: NodePath
var target: Node2D = null

@export var smooth_speed: float = 8.0

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0

func _ready() -> void:
	if not target_path.is_empty():
		target = get_node_or_null(target_path)
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.screen_shake_requested.connect(_on_screen_shake)

func set_target(new_target: Node2D) -> void:
	target = new_target
	if target:
		global_position = target.global_position

func _process(delta: float) -> void:
	if target and is_instance_valid(target):
		global_position = global_position.lerp(target.global_position, smooth_speed * delta)
		
	# Process screen shake
	if shake_timer > 0.0:
		shake_timer -= delta
		var progress = shake_timer / shake_duration
		var current_amp = shake_intensity * progress
		offset = Vector2(
			randf_range(-current_amp, current_amp),
			randf_range(-current_amp, current_amp)
		)
	else:
		offset = Vector2.ZERO

func _on_screen_shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration
