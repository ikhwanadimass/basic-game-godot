extends CharacterBody2D
class_name EnemyBase

@export var max_hp: int = 1
var hp: int = 1
@export var score_points: int = 100
var is_dead: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")

func take_damage(amount: int = 1) -> void:
	if is_dead:
		return
	hp -= amount
	if hp <= 0:
		die()
	else:
		_flash_hurt()

func take_stomp_damage() -> void:
	take_damage(1)

func _flash_hurt() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(2.0, 0.4, 0.4, 1.0), 0.08)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.08)

func die() -> void:
	is_dead = true
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.score += score_points
		gm.emit_signal("score_changed", gm.score)
		
	_spawn_floating_score("+" + str(score_points), Color.YELLOW)
	_squish_death_animation()

func _spawn_floating_score(text: String, color: Color) -> void:
	var ft_scene = load("res://scenes/effects/floating_text.tscn")
	if ft_scene:
		var ft = ft_scene.instantiate()
		ft.global_position = global_position
		get_parent().add_child(ft)
		ft.setup(text, color)

func _squish_death_animation() -> void:
	set_physics_process(false)
	collision_shape.set_deferred("disabled", true)
	
	for child in get_children():
		if child is Area2D:
			child.set_deferred("monitoring", false)
			child.set_deferred("monitorable", false)
			
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.4, 0.2), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)
