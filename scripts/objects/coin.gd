extends Area2D

const FRAMES = [
	"res://asset/Tiles/tile_0151.png",
	"res://asset/Tiles/tile_0152.png"
]

@onready var sprite: Sprite2D = $Sprite2D
var frame_idx: int = 0
var anim_timer: float = 0.0
var base_y: float = 0.0
var time_passed: float = 0.0
var is_collected: bool = false
const MAGNET_DISTANCE: float = 38.0

func _ready() -> void:
	base_y = position.y
	sprite.texture = load(FRAMES[0])
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if is_collected:
		return
		
	time_passed += delta
	position.y = base_y + sin(time_passed * 4.0) * 2.0
	
	# Spinning animation
	anim_timer += delta
	if anim_timer >= 0.16:
		anim_timer = 0.0
		frame_idx = (frame_idx + 1) % FRAMES.size()
		sprite.texture = load(FRAMES[frame_idx])
		
	# Magnet attraction towards player
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		var magnet_range = MAGNET_DISTANCE
		var magnet_speed = 180.0
		var gm = get_node_or_null("/root/GameManager")
		if gm:
			var m_lvl = gm.get_upgrade_level("magnet_level")
			magnet_range += m_lvl * 55.0
			magnet_speed += m_lvl * 80.0
		if dist < magnet_range:
			global_position = global_position.move_toward(player.global_position, magnet_speed * delta)

func _on_body_entered(body: Node2D) -> void:
	if is_collected or not body.is_in_group("player"):
		return
	collect()

func collect() -> void:
	is_collected = true
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.add_coins(1)
		
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("coin")
		
	_spawn_popup("+10")
	
	# Collect animation
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.4, 1.4), 0.1)
	tween.parallel().tween_property(sprite, "position:y", sprite.position.y - 12.0, 0.15)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)

func _spawn_popup(txt: String) -> void:
	var ft_scene = load("res://scenes/effects/floating_text.tscn")
	if ft_scene:
		var ft = ft_scene.instantiate()
		ft.global_position = global_position
		get_parent().add_child(ft)
		ft.setup(txt, Color(1.0, 0.85, 0.2))
