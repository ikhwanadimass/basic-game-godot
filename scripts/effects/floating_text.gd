extends Node2D

@onready var label: Label = $Label

func setup(text: String, color: Color = Color.WHITE, duration: float = 0.8) -> void:
	if not is_inside_tree():
		await ready
	label.text = text
	label.modulate = color
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 28.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), duration * 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "scale", Vector2(0.8, 0.8), duration * 0.7)
	tween.tween_property(self, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
