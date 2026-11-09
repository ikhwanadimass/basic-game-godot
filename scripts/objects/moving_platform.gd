extends AnimatableBody2D

@export var move_offset: Vector2 = Vector2(80.0, 0.0)
@export var duration: float = 2.5

var start_pos: Vector2
var time_passed: float = 0.0

func _ready() -> void:
	sync_to_physics = true
	start_pos = global_position

func _physics_process(delta: float) -> void:
	time_passed += delta
	var progress = (sin(time_passed * (TAU / duration) - PI * 0.5) + 1.0) * 0.5
	global_position = start_pos.lerp(start_pos + move_offset, progress)
