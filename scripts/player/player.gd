extends CharacterBody2D
class_name Player

# Movement Parameters
const SPEED: float = 140.0
const ACCELERATION: float = 900.0
const FRICTION: float = 1100.0
const GRAVITY: float = 950.0
const FALL_GRAVITY_MULT: float = 1.4
const JUMP_VELOCITY: float = -310.0
const DOUBLE_JUMP_VELOCITY: float = -270.0
const WALL_SLIDE_SPEED: float = 65.0
const WALL_JUMP_VELOCITY: Vector2 = Vector2(180.0, -290.0)

# Dash Parameters
const DASH_SPEED: float = 330.0
const DASH_DURATION: float = 0.16
const DASH_COOLDOWN: float = 0.6
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.RIGHT

# Slam Parameters
var is_slamming: bool = false
const SLAM_SPEED: float = 460.0

# Jump Timing (Juice)
const COYOTE_TIME: float = 0.12
var coyote_timer: float = 0.0
const JUMP_BUFFER_TIME: float = 0.12
var jump_buffer_timer: float = 0.0
var can_double_jump: bool = true

# Invulnerability & State
var is_invulnerable: bool = false
var is_dead: bool = false
var facing_direction: int = 1 # 1 = right, -1 = left

# Upgrades & Attributes
var effective_speed: float = SPEED
var effective_jump_velocity: float = JUMP_VELOCITY
var effective_double_jump_velocity: float = DOUBLE_JUMP_VELOCITY
var effective_dash_cooldown: float = DASH_COOLDOWN
var max_midair_jumps: int = 1
var midair_jumps_left: int = 1
var dash_has_iframe: bool = false
var has_shield: bool = false
var has_shockwave: bool = false

# Character Skin Textures: 0=Green, 1=Pink, 2=Blue, 3=Yellow, 4=Shadow Ninja
const SKIN_TEXTURES = {
	0: ["res://asset/Tiles/Characters/tile_0000.png", "res://asset/Tiles/Characters/tile_0001.png"],
	1: ["res://asset/Tiles/Characters/tile_0004.png", "res://asset/Tiles/Characters/tile_0005.png"],
	2: ["res://asset/Tiles/Characters/tile_0002.png", "res://asset/Tiles/Characters/tile_0003.png"],
	3: ["res://asset/Tiles/Characters/tile_0006.png", "res://asset/Tiles/Characters/tile_0007.png"],
	4: ["res://asset/Tiles/Characters/tile_0008.png", "res://asset/Tiles/Characters/tile_0009.png"]
}

# Node References
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var anim_timer: Timer = $AnimationTimer
@onready var dust_particles: CPUParticles2D = $DustParticles
@onready var stomp_area: Area2D = $StompArea
@onready var hit_box: Area2D = $HitBox

var walk_frame: int = 0
var was_on_floor: bool = false

func _ready() -> void:
	add_to_group("player")
	_apply_skin()
	anim_timer.timeout.connect(_on_anim_timer_timeout)
	stomp_area.area_entered.connect(_on_stomp_area_entered)
	hit_box.area_entered.connect(_on_hit_box_entered)
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		var speed_lvl = gm.get_upgrade_level("speed_level")
		effective_speed = SPEED * (1.0 + speed_lvl * 0.15)
		
		var jump_lvl = gm.get_upgrade_level("jump_level")
		effective_jump_velocity = JUMP_VELOCITY * (1.0 + jump_lvl * 0.08)
		effective_double_jump_velocity = DOUBLE_JUMP_VELOCITY * (1.0 + jump_lvl * 0.08)
		
		var dash_lvl = gm.get_upgrade_level("dash_level")
		effective_dash_cooldown = maxf(0.22, DASH_COOLDOWN - dash_lvl * 0.12)
		dash_has_iframe = (dash_lvl > 0)
		
		max_midair_jumps = 2 if gm.has_upgrade("triple_jump") else 1
		midair_jumps_left = max_midair_jumps
		has_shield = gm.has_upgrade("guardian_shield")
		has_shockwave = gm.has_upgrade("shockwave_slam")
		
		if gm.has_upgrade("skeleton_key") and gm.keys == 0:
			gm.add_key()
			
		if gm.has_upgrade("checkpoint_charm") and not gm.has_checkpoint:
			gm.set_checkpoint(global_position)
		
		if gm.has_checkpoint:
			global_position = gm.checkpoint_position

func _apply_skin() -> void:
	var skin_idx = 0
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		skin_idx = gm.selected_character
	if not SKIN_TEXTURES.has(skin_idx):
		skin_idx = 0
	var paths = SKIN_TEXTURES[skin_idx]
	sprite.texture = load(paths[0])

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Handle Dash Timer
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	if is_dashing:
		_process_dash(delta)
		return

	# Timers update
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		can_double_jump = true
		midair_jumps_left = max_midair_jumps
		if is_slamming:
			_land_slam()
	else:
		coyote_timer -= delta

	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	# Input Buffering
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME

	# Dash Input
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0:
		_start_dash()
		return

	# Ground Slam Input (Down + Attack or Down in air)
	if not is_on_floor() and Input.is_action_pressed("move_down") and Input.is_action_just_pressed("attack"):
		_start_slam()
		return

	# Gravity & Vertical Movement
	if not is_on_floor():
		var applied_gravity = GRAVITY
		if velocity.y > 0.0:
			applied_gravity *= FALL_GRAVITY_MULT
		
		# Wall sliding
		var is_wall_sliding = is_on_wall_only() and velocity.y > 0.0 and (
			(facing_direction == 1 and Input.is_action_pressed("move_right")) or
			(facing_direction == -1 and Input.is_action_pressed("move_left"))
		)
		
		if is_wall_sliding:
			velocity.y = minf(velocity.y + applied_gravity * delta, WALL_SLIDE_SPEED)
			can_double_jump = true
			midair_jumps_left = max_midair_jumps
			dust_particles.emitting = true
		elif is_slamming:
			velocity.y = SLAM_SPEED
		else:
			velocity.y += applied_gravity * delta

	# Jump Execution
	if jump_buffer_timer > 0.0:
		if coyote_timer > 0.0:
			_execute_jump(effective_jump_velocity)
		elif is_on_wall_only():
			_execute_wall_jump()
		elif midair_jumps_left > 0:
			midair_jumps_left -= 1
			_execute_jump(effective_double_jump_velocity, true)

	# Variable Jump Height
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.5

	# Horizontal Movement
	var input_x = Input.get_axis("move_left", "move_right")
	if input_x != 0.0:
		velocity.x = move_toward(velocity.x, input_x * effective_speed, ACCELERATION * delta)
		facing_direction = 1 if input_x > 0 else -1
		sprite.flip_h = (facing_direction == -1)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	move_and_slide()

	# Landing juice detection
	if not was_on_floor and is_on_floor():
		_squash_and_stretch(Vector2(1.25, 0.75))
		dust_particles.emitting = true
	was_on_floor = is_on_floor()

	_update_animation(input_x)

func _execute_jump(jump_power: float, is_double: bool = false) -> void:
	velocity.y = jump_power
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	_squash_and_stretch(Vector2(0.75, 1.25))
	
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("jump")
		
	if is_double:
		_flip_effect()
	else:
		dust_particles.emitting = true

func _execute_wall_jump() -> void:
	var wall_normal = get_wall_normal()
	velocity.x = wall_normal.x * WALL_JUMP_VELOCITY.x
	velocity.y = WALL_JUMP_VELOCITY.y
	facing_direction = int(sign(wall_normal.x))
	sprite.flip_h = (facing_direction == -1)
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	_squash_and_stretch(Vector2(0.75, 1.25))
	
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("jump")
	dust_particles.emitting = true

func _start_dash() -> void:
	is_dashing = true
	dash_timer = DASH_DURATION
	dash_cooldown_timer = effective_dash_cooldown
	if dash_has_iframe:
		is_invulnerable = true
	
	var input_vec = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	if input_vec == Vector2.ZERO:
		dash_direction = Vector2(facing_direction, 0.0)
	else:
		dash_direction = input_vec.normalized()
		
	velocity = dash_direction * DASH_SPEED
	
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("dash")
		
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.trigger_screen_shake(3.0, 0.15)
		
	_spawn_ghost_trail()

func _process_dash(delta: float) -> void:
	dash_timer -= delta
	velocity = dash_direction * DASH_SPEED
	move_and_slide()
	
	if fmod(dash_timer, 0.04) < delta:
		_spawn_ghost_trail()
		
	if dash_timer <= 0.0:
		is_dashing = false
		if dash_has_iframe:
			is_invulnerable = false
		velocity = dash_direction * (effective_speed * 0.8)

func _start_slam() -> void:
	is_slamming = true
	velocity.x = 0.0
	velocity.y = SLAM_SPEED

func _land_slam() -> void:
	is_slamming = false
	_squash_and_stretch(Vector2(1.4, 0.6))
	dust_particles.emitting = true
	
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("stomp")
		
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.trigger_screen_shake(6.0, 0.25)
		
	if has_shockwave:
		_trigger_slam_shockwave()

func _trigger_slam_shockwave() -> void:
	_spawn_floating_text("SHOCKWAVE!", Color(1.0, 0.6, 0.2))
	var enemies = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if is_instance_valid(e) and e != self:
			var d = global_position.distance_to(e.global_position)
			if d < 85.0:
				if e.has_method("take_damage"):
					e.take_damage(2)

func _spawn_floating_text(txt: String, col: Color = Color.WHITE) -> void:
	var ft_scene = load("res://scenes/effects/floating_text.tscn")
	if ft_scene:
		var ft = ft_scene.instantiate()
		ft.global_position = global_position + Vector2(0, -18)
		get_parent().add_child(ft)
		ft.setup(txt, col)

func _spawn_ghost_trail() -> void:
	var ghost = Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.flip_h = sprite.flip_h
	ghost.global_position = sprite.global_position
	ghost.scale = sprite.scale
	ghost.modulate = Color(0.3, 0.8, 1.0, 0.6)
	get_parent().add_child(ghost)
	
	var tween = ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(ghost.queue_free)

func _squash_and_stretch(target_scale: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "scale", target_scale, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _flip_effect() -> void:
	var tween = create_tween()
	var rot_target = TAU if facing_direction > 0 else -TAU
	tween.tween_property(sprite, "rotation", rot_target, 0.25)
	tween.tween_callback(func(): sprite.rotation = 0.0)

func _update_animation(input_x: float) -> void:
	if is_on_floor() and abs(velocity.x) > 10.0:
		if anim_timer.is_stopped():
			anim_timer.start(0.14)
	else:
		anim_timer.stop()
		walk_frame = 0
		_update_sprite_frame()

func _on_anim_timer_timeout() -> void:
	walk_frame = (walk_frame + 1) % 2
	_update_sprite_frame()

func _update_sprite_frame() -> void:
	var skin_idx = 0
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		skin_idx = gm.selected_character
	if not SKIN_TEXTURES.has(skin_idx):
		skin_idx = 0
	var paths = SKIN_TEXTURES[skin_idx]
	sprite.texture = load(paths[walk_frame])

# Combat & Interaction
func bounce(bounce_force: float = -290.0) -> void:
	velocity.y = bounce_force
	can_double_jump = true
	_squash_and_stretch(Vector2(0.8, 1.25))

func take_damage(amount: int = 1, knockback_source: Vector2 = Vector2.ZERO) -> void:
	if is_invulnerable or is_dead:
		return
		
	# Guardian Shield absorption (absorbs standard hit, but not instant-kill pit falls > 90)
	if has_shield and amount < 90:
		has_shield = false
		var am_s = get_node_or_null("/root/AudioManager")
		if am_s:
			am_s.play_sfx("door")
		var gm_s = get_node_or_null("/root/GameManager")
		if gm_s:
			gm_s.trigger_screen_shake(6.0, 0.25)
		_spawn_floating_text("SHIELD BLOCKED!", Color.GOLD)
		is_invulnerable = true
		var tween_s = create_tween().set_loops(4)
		tween_s.tween_property(sprite, "modulate", Color(2.0, 2.0, 0.5, 1.0), 0.08)
		tween_s.tween_property(sprite, "modulate", Color.WHITE, 0.08)
		tween_s.chain().tween_callback(func(): is_invulnerable = false; sprite.modulate = Color.WHITE)
		return

	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
		
	var dead = gm.take_damage(amount)
	gm.trigger_screen_shake(5.0, 0.2)
	
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("hurt")
		
	if dead:
		_die()
		return
		
	# Knockback
	if knockback_source != Vector2.ZERO:
		var knock_dir = (global_position - knockback_source).normalized()
		velocity = Vector2(sign(knock_dir.x) * 160.0, -180.0)
	else:
		velocity = Vector2(-facing_direction * 120.0, -180.0)
		
	# Invulnerability Flash
	is_invulnerable = true
	var tween = create_tween().set_loops(6)
	tween.tween_property(sprite, "modulate:a", 0.2, 0.1)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
	tween.chain().tween_callback(func(): is_invulnerable = false; sprite.modulate.a = 1.0)

func _die() -> void:
	is_dead = true
	velocity = Vector2(0.0, -250.0)
	collision_shape.set_deferred("disabled", true)
	stomp_area.set_deferred("monitoring", false)
	hit_box.set_deferred("monitoring", false)
	
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("game_over")
		
	var tween = create_tween()
	tween.tween_property(sprite, "rotation", PI * 2, 0.6)
	tween.parallel().tween_property(self, "position:y", position.y + 120.0, 0.8)
	tween.tween_callback(func():
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_checkpoint:
			_respawn_at_checkpoint()
		else:
			_show_game_over()
	)

func _respawn_at_checkpoint() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		global_position = gm.checkpoint_position
		gm.health = gm.max_health
		gm.emit_signal("health_changed", gm.health, gm.max_health)
	is_dead = false
	velocity = Vector2.ZERO
	sprite.rotation = 0.0
	collision_shape.set_deferred("disabled", false)
	stomp_area.set_deferred("monitoring", true)
	hit_box.set_deferred("monitoring", true)
	is_invulnerable = false
	sprite.modulate.a = 1.0

func _show_game_over() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_game_over"):
		hud.show_game_over()

func _on_stomp_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hurtbox") and velocity.y > 0.0:
		var enemy = area.get_parent()
		if enemy and enemy.has_method("take_stomp_damage"):
			enemy.take_stomp_damage()
			bounce(JUMP_VELOCITY * 0.85)
			var am = get_node_or_null("/root/AudioManager")
			if am:
				am.play_sfx("stomp")

func _on_hit_box_entered(area: Area2D) -> void:
	if area.is_in_group("hazard"):
		take_damage(1, area.global_position)
	elif area.is_in_group("enemy_hitbox"):
		take_damage(1, area.global_position)
