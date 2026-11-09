extends Area2D

@export var bounce_power: float = -440.0
@onready var sprite: Sprite2D = $Sprite2D

const TEX_COMPRESSED = "res://asset/Tiles/tile_0107.png"
const TEX_EXTENDED = "res://asset/Tiles/tile_0108.png"

func _ready() -> void:
	sprite.texture = load(TEX_COMPRESSED)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
		
	var player = body as CharacterBody2D
	if player and player.has_method("bounce"):
		player.bounce(bounce_power)
		
		var am = get_node_or_null("/root/AudioManager")
		if am:
			am.play_sfx("spring")
			
		var gm = get_node_or_null("/root/GameManager")
		if gm:
			gm.trigger_screen_shake(3.0, 0.15)
			
		_play_spring_anim()

func _play_spring_anim() -> void:
	sprite.texture = load(TEX_EXTENDED)
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.4), 0.08)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.15)
	tween.tween_callback(func(): sprite.texture = load(TEX_COMPRESSED))
