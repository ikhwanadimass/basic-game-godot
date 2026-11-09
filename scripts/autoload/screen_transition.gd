extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

var is_transitioning: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func change_scene_to_file(target_scene: String, duration: float = 0.35) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	
	get_tree().change_scene_to_file(target_scene)
	
	var tween_in = create_tween()
	tween_in.tween_property(color_rect, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween_in.finished
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false

func fade_out(duration: float = 0.3) -> void:
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, duration).set_trans(Tween.TRANS_SINE)
	await tween.finished

func fade_in(duration: float = 0.3) -> void:
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE)
	await tween.finished
