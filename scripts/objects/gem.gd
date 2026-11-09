extends Area2D

@export var gem_index: int = 0
@onready var sprite: Sprite2D = $Sprite2D

var base_y: float = 0.0
var time_passed: float = 0.0
var is_collected: bool = false

func _ready() -> void:
	base_y = position.y
	body_entered.connect(_on_body_entered)
	
	# If already collected in current run
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.current_level_gems[gem_index]:
		modulate.a = 0.4

func _process(delta: float) -> void:
	if is_collected:
		return
		
	time_passed += delta
	position.y = base_y + sin(time_passed * 3.0) * 3.0
	sprite.rotation = sin(time_passed * 2.0) * 0.15

func _on_body_entered(body: Node2D) -> void:
	if is_collected or not body.is_in_group("player"):
		return
	collect()

func collect() -> void:
	is_collected = true
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.add_gem(gem_index)
		
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("gem")
		
	_spawn_popup("GEM " + str(gem_index + 1) + "!")
	
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.8, 1.8), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "position:y", sprite.position.y - 18.0, 0.2)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)

func _spawn_popup(txt: String) -> void:
	var ft_scene = load("res://scenes/effects/floating_text.tscn")
	if ft_scene:
		var ft = ft_scene.instantiate()
		ft.global_position = global_position
		get_parent().add_child(ft)
		ft.setup(txt, Color(0.2, 0.85, 1.0))
