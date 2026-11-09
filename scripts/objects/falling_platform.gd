extends AnimatableBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detect_area: Area2D = $DetectArea

var initial_position: Vector2
var is_triggered: bool = false
var is_falling: bool = false
var fall_velocity: float = 0.0

func _ready() -> void:
	initial_position = position
	detect_area.body_entered.connect(_on_detect_area_entered)

func _physics_process(delta: float) -> void:
	if is_falling:
		fall_velocity += 600.0 * delta
		position.y += fall_velocity * delta

func _on_detect_area_entered(body: Node2D) -> void:
	if is_triggered or not body.is_in_group("player"):
		return
	is_triggered = true
	_shake_and_fall()

func _shake_and_fall() -> void:
	var tween = create_tween()
	# Shiver / rumble
	for i in range(5):
		tween.tween_property(sprite, "position:x", 2.0, 0.04)
		tween.tween_property(sprite, "position:x", -2.0, 0.04)
	tween.tween_property(sprite, "position:x", 0.0, 0.04)
	tween.tween_callback(func():
		is_falling = true
		collision_shape.set_deferred("disabled", true)
	)
	tween.tween_interval(1.2)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_respawn)

func _respawn() -> void:
	is_falling = false
	fall_velocity = 0.0
	position = initial_position
	sprite.position = Vector2.ZERO
	sprite.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, 0.3)
	tween.tween_callback(func():
		collision_shape.set_deferred("disabled", false)
		is_triggered = false
	)
