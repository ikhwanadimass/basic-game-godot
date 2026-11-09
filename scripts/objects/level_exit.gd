extends Area2D

@onready var pole_sprite: Sprite2D = $PoleSprite
@onready var flag_sprite: Sprite2D = $FlagSprite

var is_activated: bool = false
const FLAG_FRAMES = [
	"res://asset/Tiles/tile_0111.png",
	"res://asset/Tiles/tile_0112.png"
]
var flag_frame_idx: int = 0
var anim_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	anim_timer += delta
	if anim_timer >= 0.2:
		anim_timer = 0.0
		flag_frame_idx = (flag_frame_idx + 1) % FLAG_FRAMES.size()
		flag_sprite.texture = load(FLAG_FRAMES[flag_frame_idx])

func _on_body_entered(body: Node2D) -> void:
	if is_activated or not body.is_in_group("player"):
		return
	is_activated = true
	
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("clear")
		am.stop_music()
		
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.trigger_screen_shake(4.0, 0.4)
		
	var lvl = get_tree().get_first_node_in_group("level")
	if lvl and lvl.has_method("on_level_completed"):
		lvl.on_level_completed()
	else:
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_level_complete"):
			hud.show_level_complete()
