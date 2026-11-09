extends Area2D

@onready var pole_sprite: Sprite2D = $PoleSprite
@onready var flag_sprite: Sprite2D = $FlagSprite

var is_activated: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	flag_sprite.position.y = 4.0 # start lowered

func _on_body_entered(body: Node2D) -> void:
	if is_activated or not body.is_in_group("player"):
		return
	activate()

func activate() -> void:
	is_activated = true
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.set_checkpoint(global_position + Vector2(0, -6))
		
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("checkpoint")
		
	_spawn_popup("CHECKPOINT!")
	
	# Raise flag animation
	var tween = create_tween()
	tween.tween_property(flag_sprite, "position:y", -6.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _spawn_popup(txt: String) -> void:
	var ft_scene = load("res://scenes/effects/floating_text.tscn")
	if ft_scene:
		var ft = ft_scene.instantiate()
		ft.global_position = global_position + Vector2(0, -18)
		get_parent().add_child(ft)
		ft.setup(txt, Color(0.3, 0.9, 1.0))
