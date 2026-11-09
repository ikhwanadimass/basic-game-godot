extends StaticBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var unlock_area: Area2D = $UnlockArea

var is_unlocked: bool = false
var prompt_cooldown: float = 0.0

func _ready() -> void:
	unlock_area.body_entered.connect(_on_unlock_area_entered)

func _process(delta: float) -> void:
	if prompt_cooldown > 0.0:
		prompt_cooldown -= delta

func _on_unlock_area_entered(body: Node2D) -> void:
	if is_unlocked or not body.is_in_group("player"):
		return
		
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.use_key():
		unlock()
	else:
		if prompt_cooldown <= 0.0:
			prompt_cooldown = 2.0
			_spawn_popup("LOCKED! NEED KEY")

func unlock() -> void:
	is_unlocked = true
	collision_shape.set_deferred("disabled", true)
	
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("door")
		
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.trigger_screen_shake(4.0, 0.2)
		
	_spawn_popup("UNLOCKED!")
	
	var tween = create_tween()
	# Door shake and dissolve
	for i in range(4):
		tween.tween_property(sprite, "position:x", 2.0, 0.04)
		tween.tween_property(sprite, "position:x", -2.0, 0.04)
	tween.tween_property(sprite, "position:x", 0.0, 0.04)
	tween.parallel().tween_property(sprite, "scale:y", 0.0, 0.25).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)

func _spawn_popup(txt: String) -> void:
	var ft_scene = load("res://scenes/effects/floating_text.tscn")
	if ft_scene:
		var ft = ft_scene.instantiate()
		ft.global_position = global_position + Vector2(0, -12)
		get_parent().add_child(ft)
		ft.setup(txt, Color(1.0, 0.3, 0.3) if "LOCKED" in txt else Color(0.3, 1.0, 0.4))
