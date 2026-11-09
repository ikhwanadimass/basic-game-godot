extends EnemyBase

const SPEED: float = 35.0
const GRAVITY: float = 800.0

var direction: int = 1
var frames = [
	"res://asset/Tiles/Characters/tile_0018.png",
	"res://asset/Tiles/Characters/tile_0019.png"
]
var frame_idx: int = 0
var anim_timer: float = 0.0

@onready var ledge_check: RayCast2D = $LedgeCheck

func _ready() -> void:
	super._ready()
	sprite.texture = load(frames[0])

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Check wall or cliff
	if is_on_wall() or (is_on_floor() and not ledge_check.is_colliding()):
		direction *= -1
		sprite.flip_h = (direction > 0)
		ledge_check.position.x = direction * 10.0

	velocity.x = direction * SPEED
	move_and_slide()

	# Animation
	anim_timer += delta
	if anim_timer >= 0.2:
		anim_timer = 0.0
		frame_idx = (frame_idx + 1) % frames.size()
		sprite.texture = load(frames[frame_idx])

# Spike beetle cannot be stomped normally
func take_stomp_damage() -> void:
	# Armored shell bounces player or hurts them
	pass
