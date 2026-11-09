extends EnemyBase
class_name BossGolem

enum State { INTRO, IDLE, MOVE, PREPARE_JUMP, JUMP_SLAM, RECOVER, ENRAGED_CHARGE, DEAD }

var state: State = State.INTRO
var state_timer: float = 0.0

const WALK_SPEED: float = 55.0
const ENRAGED_SPEED: float = 95.0
const GRAVITY: float = 900.0

var facing: int = -1
var frames = [
	"res://asset/Tiles/Characters/tile_0021.png",
	"res://asset/Tiles/Characters/tile_0022.png",
	"res://asset/Tiles/Characters/tile_0023.png"
]
var frame_idx: int = 0
var anim_timer: float = 0.0

@onready var hurt_box: Area2D = $HurtBox
@onready var hit_box: Area2D = $HitBox

func _ready() -> void:
	max_hp = 6
	hp = max_hp
	score_points = 2000
	scale = Vector2(2.0, 2.0)
	sprite.texture = load(frames[0])
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.emit_signal("boss_health_changed", hp, max_hp)
		
	# Boss Intro Roar
	state = State.INTRO
	state_timer = 1.2
	_play_roar()

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	state_timer -= delta
	var player = get_tree().get_first_node_in_group("player")

	match state:
		State.INTRO:
			velocity.x = 0.0
			if state_timer <= 0.0:
				_change_state(State.IDLE, 0.8)

		State.IDLE:
			velocity.x = 0.0
			if player and is_instance_valid(player):
				facing = 1 if player.global_position.x > global_position.x else -1
				sprite.flip_h = (facing > 0)
			if state_timer <= 0.0:
				var next = State.MOVE if randf() < 0.6 else State.PREPARE_JUMP
				_change_state(next, randf_range(1.5, 2.5))

		State.MOVE:
			if player and is_instance_valid(player):
				facing = 1 if player.global_position.x > global_position.x else -1
				sprite.flip_h = (facing > 0)
			var cur_speed = ENRAGED_SPEED if hp <= 3 else WALK_SPEED
			velocity.x = facing * cur_speed
			if state_timer <= 0.0:
				_change_state(State.PREPARE_JUMP, 0.6)

		State.PREPARE_JUMP:
			velocity.x = 0.0
			# Squish down before jump
			sprite.scale = Vector2(1.2, 0.8)
			if state_timer <= 0.0:
				_execute_slam_jump(player)

		State.JUMP_SLAM:
			# Falling fast towards ground
			if is_on_floor() and velocity.y >= 0.0:
				_on_slam_land()

		State.RECOVER:
			velocity.x = 0.0
			# Boss is dizzy/vulnerable after slam
			if state_timer <= 0.0:
				_change_state(State.IDLE, 0.8)

	move_and_slide()

	# Animation
	anim_timer += delta
	if anim_timer >= 0.16:
		anim_timer = 0.0
		frame_idx = (frame_idx + 1) % frames.size()
		sprite.texture = load(frames[frame_idx])

func _change_state(new_state: State, duration: float) -> void:
	state = new_state
	state_timer = duration
	sprite.scale = Vector2.ONE

func _execute_slam_jump(player: Node2D) -> void:
	state = State.JUMP_SLAM
	velocity.y = -380.0
	if player and is_instance_valid(player):
		var target_x = player.global_position.x
		velocity.x = clampf((target_x - global_position.x) * 1.5, -120.0, 120.0)
	else:
		velocity.x = facing * 60.0
	sprite.scale = Vector2(0.8, 1.25)
	
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("jump")

func _on_slam_land() -> void:
	velocity.x = 0.0
	sprite.scale = Vector2(1.35, 0.7)
	_change_state(State.RECOVER, 1.0)
	
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("stomp")
		
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.trigger_screen_shake(8.0, 0.3)
		
	# Summon minion if enraged and low HP
	if hp <= 3 and randf() < 0.5:
		_summon_minion()

func _summon_minion() -> void:
	var bat_scene = load("res://scenes/enemies/bat.tscn")
	if bat_scene:
		var bat = bat_scene.instantiate()
		bat.global_position = global_position + Vector2(randf_range(-30, 30), -50)
		get_parent().add_child(bat)

func _play_roar() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("boss_roar")
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.trigger_screen_shake(6.0, 0.5)

func take_damage(amount: int = 1) -> void:
	if state == State.DEAD:
		return
		
	hp -= amount
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.emit_signal("boss_health_changed", hp, max_hp)
		
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("boss_hit")
		
	_flash_hurt()
	_spawn_floating_score("-" + str(amount), Color.RED)
	
	if hp <= 0:
		die()
	elif hp == 3:
		# Enrage roar!
		_play_roar()
		modulate = Color(1.3, 0.7, 0.7, 1.0)

func take_stomp_damage() -> void:
	take_damage(1)

func die() -> void:
	state = State.DEAD
	set_physics_process(false)
	collision_shape.set_deferred("disabled", true)
	hurt_box.set_deferred("monitoring", false)
	hit_box.set_deferred("monitoring", false)
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.emit_signal("boss_defeated")
		gm.score += score_points
		gm.emit_signal("score_changed", gm.score)
		gm.trigger_screen_shake(10.0, 1.2)
		
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("clear")
		am.stop_music()
		
	# Dramatic death slow-mo and explosion
	Engine.time_scale = 0.4
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(3.0, 0.2, 0.2, 1.0), 0.3)
	tween.parallel().tween_property(sprite, "scale", Vector2(2.5, 0.2), 0.8)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.9)
	tween.tween_callback(func():
		Engine.time_scale = 1.0
		_spawn_trophy_and_win()
		queue_free()
	)

func _spawn_trophy_and_win() -> void:
	# Show level exit or level complete screen
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_victory"):
		hud.show_victory()
