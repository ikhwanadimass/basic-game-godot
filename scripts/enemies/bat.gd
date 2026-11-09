extends EnemyBase

const PATROL_SPEED: float = 45.0
const CHASE_SPEED: float = 65.0
const DETECTION_RANGE: float = 120.0

var home_position: Vector2
var direction: int = -1
var time_passed: float = 0.0

var frames = [
	"res://asset/Tiles/Characters/tile_0024.png",
	"res://asset/Tiles/Characters/tile_0025.png",
	"res://asset/Tiles/Characters/tile_0026.png"
]
var frame_idx: int = 0
var anim_timer: float = 0.0

func _ready() -> void:
	super._ready()
	home_position = global_position
	sprite.texture = load(frames[0])

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	time_passed += delta
	var player = get_tree().get_first_node_in_group("player")
	
	if player and is_instance_valid(player) and global_position.distance_to(player.global_position) < DETECTION_RANGE:
		# Chase player smoothly
		var dir_to_player = (player.global_position - global_position).normalized()
		velocity = velocity.lerp(dir_to_player * CHASE_SPEED, 4.0 * delta)
		sprite.flip_h = (velocity.x > 0)
	else:
		# Wave patrol around home position
		var target_x = home_position.x + sin(time_passed * 1.5) * 50.0
		var target_y = home_position.y + cos(time_passed * 3.0) * 12.0
		var target_pos = Vector2(target_x, target_y)
		velocity = (target_pos - global_position) * 2.0
		sprite.flip_h = (sin(time_passed * 1.5) > 0)

	move_and_slide()

	# Animation
	anim_timer += delta
	if anim_timer >= 0.12:
		anim_timer = 0.0
		frame_idx = (frame_idx + 1) % frames.size()
		sprite.texture = load(frames[frame_idx])
