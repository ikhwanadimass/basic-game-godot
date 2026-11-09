extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
var base_y: float = 0.0
var time_passed: float = 0.0
var is_collected: bool = false

func _ready() -> void:
	base_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if is_collected:
		return
	time_passed += delta
	position.y = base_y + sin(time_passed * 3.5) * 2.0
	sprite.scale = Vector2.ONE * (1.0 + sin(time_passed * 5.0) * 0.1)

func _on_body_entered(body: Node2D) -> void:
	if is_collected or not body.is_in_group("player"):
		return
		
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.health < gm.max_health:
		is_collected = true
		gm.heal(1)
		var am = get_node_or_null("/root/AudioManager")
		if am:
			am.play_sfx("coin")
			
		_spawn_popup("+1 HP")
		
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.15)
		tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.15)
		tween.chain().tween_callback(queue_free)

func _spawn_popup(txt: String) -> void:
	var ft_scene = load("res://scenes/effects/floating_text.tscn")
	if ft_scene:
		var ft = ft_scene.instantiate()
		ft.global_position = global_position
		get_parent().add_child(ft)
		ft.setup(txt, Color(0.2, 1.0, 0.4))
