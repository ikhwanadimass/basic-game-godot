extends Node

# Global Signals
@warning_ignore("unused_signal")
signal health_changed(current_hp: int, max_hp: int)
@warning_ignore("unused_signal")
signal coins_changed(coins: int)
@warning_ignore("unused_signal")
signal gems_changed(gem_index: int, collected: bool)
@warning_ignore("unused_signal")
signal keys_changed(keys: int)
@warning_ignore("unused_signal")
signal score_changed(score: int)
@warning_ignore("unused_signal")
signal player_died()
@warning_ignore("unused_signal")
signal player_respawned()
@warning_ignore("unused_signal")
signal level_completed(level_idx: int, stats: Dictionary)
@warning_ignore("unused_signal")
signal boss_health_changed(current_hp: int, max_hp: int)
@warning_ignore("unused_signal")
signal boss_defeated()
@warning_ignore("unused_signal")
signal screen_shake_requested(intensity: float, duration: float)

# Player Stats
var max_health: int = 3
var health: int = 3
var coins: int = 0
var score: int = 0
var keys: int = 0
var current_level_gems: Array[bool] = [false, false, false]

# Character Selection: 0 = Green, 1 = Pink, 2 = Blue, 3 = Yellow
var selected_character: int = 0

# Checkpoint system
var has_checkpoint: bool = false
var checkpoint_position: Vector2 = Vector2.ZERO

# Level Progression (Supports 50 Levels!)
const MAX_LEVELS: int = 50
var current_level_index: int = 1
var max_unlocked_level: int = 1
var level_records: Dictionary = {}

# Settings
var sfx_volume: float = 1.0
var music_volume: float = 0.8
var screen_shake_enabled: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_level_records()
	_setup_default_inputs()
	load_game()

func _init_level_records() -> void:
	for i in range(1, MAX_LEVELS + 1):
		if not level_records.has(i):
			level_records[i] = {"completed": false, "gems": [false, false, false], "best_time": 9999.0, "stars": 0}

func _setup_default_inputs() -> void:
	var actions = {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"jump": [KEY_SPACE, KEY_Z, KEY_UP, KEY_W],
		"dash": [KEY_SHIFT, KEY_X, KEY_K],
		"attack": [KEY_C, KEY_J],
		"interact": [KEY_E, KEY_ENTER],
		"pause": [KEY_ESCAPE, KEY_P]
	}
	
	for action in actions.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key_code in actions[action]:
			var ev = InputEventKey.new()
			ev.physical_keycode = key_code
			var has_ev = false
			for existing in InputMap.action_get_events(action):
				if existing is InputEventKey and existing.physical_keycode == key_code:
					has_ev = true
					break
			if not has_ev:
				InputMap.action_add_event(action, ev)
				
		# Add Joypad bindings
		if action == "move_left":
			_add_joy_button(action, JOY_BUTTON_DPAD_LEFT)
		elif action == "move_right":
			_add_joy_button(action, JOY_BUTTON_DPAD_RIGHT)
		elif action == "move_up":
			_add_joy_button(action, JOY_BUTTON_DPAD_UP)
		elif action == "move_down":
			_add_joy_button(action, JOY_BUTTON_DPAD_DOWN)
		elif action == "jump":
			_add_joy_button(action, JOY_BUTTON_A)
		elif action == "dash":
			_add_joy_button(action, JOY_BUTTON_X)
		elif action == "attack":
			_add_joy_button(action, JOY_BUTTON_B)
		elif action == "pause":
			_add_joy_button(action, JOY_BUTTON_START)

func _add_joy_button(action: String, button_index: JoyButton) -> void:
	var ev = InputEventJoypadButton.new()
	ev.button_index = button_index
	var has_ev = false
	for existing in InputMap.action_get_events(action):
		if existing is InputEventJoypadButton and existing.button_index == button_index:
			has_ev = true
			break
	if not has_ev:
		InputMap.action_add_event(action, ev)

func get_level_scene_path(level_idx: int) -> String:
	return "res://scenes/levels/level_%d.tscn" % level_idx

func start_level(level_idx: int) -> void:
	current_level_index = clampi(level_idx, 1, MAX_LEVELS)
	health = max_health
	keys = 0
	has_checkpoint = false
	checkpoint_position = Vector2.ZERO
	current_level_gems = [false, false, false]
	
	var scene_path = get_level_scene_path(current_level_index)
	if ResourceLoader.exists(scene_path):
		if has_node("/root/ScreenTransition"):
			get_node("/root/ScreenTransition").change_scene_to_file(scene_path)
		else:
			get_tree().change_scene_to_file(scene_path)
	else:
		push_error("Level scene not found: " + scene_path)

func reset_level_stats() -> void:
	health = max_health
	keys = 0
	current_level_gems = [false, false, false]
	emit_signal("health_changed", health, max_health)
	emit_signal("keys_changed", keys)
	for i in range(3):
		emit_signal("gems_changed", i, false)

func add_coins(amount: int) -> void:
	coins += amount
	score += amount * 10
	emit_signal("coins_changed", coins)
	emit_signal("score_changed", score)

func add_gem(gem_index: int) -> void:
	if gem_index >= 0 and gem_index < 3:
		if not current_level_gems[gem_index]:
			current_level_gems[gem_index] = true
			score += 100
			emit_signal("gems_changed", gem_index, true)
			emit_signal("score_changed", score)

func add_key() -> void:
	keys += 1
	emit_signal("keys_changed", keys)

func use_key() -> bool:
	if keys > 0:
		keys -= 1
		emit_signal("keys_changed", keys)
		return true
	return false

func heal(amount: int = 1) -> void:
	health = mini(health + amount, max_health)
	emit_signal("health_changed", health, max_health)

func take_damage(amount: int = 1) -> bool:
	health = maxi(0, health - amount)
	emit_signal("health_changed", health, max_health)
	if health <= 0:
		emit_signal("player_died")
		return true
	return false

func set_checkpoint(pos: Vector2) -> void:
	checkpoint_position = pos
	has_checkpoint = true

func complete_level(time_elapsed: float) -> Dictionary:
	var collected_gems_count: int = 0
	for g in current_level_gems:
		if g:
			collected_gems_count += 1
			
	var stars: int = 1
	if collected_gems_count >= 2:
		stars = 2
	if collected_gems_count == 3:
		stars = 3
		
	if not level_records.has(current_level_index):
		level_records[current_level_index] = {"completed": false, "gems": [false, false, false], "best_time": 9999.0, "stars": 0}
		
	var rec = level_records[current_level_index]
	rec["completed"] = true
	rec["stars"] = maxi(rec["stars"], stars)
	rec["best_time"] = minf(rec["best_time"], time_elapsed)
	for i in range(3):
		rec["gems"][i] = rec["gems"][i] or current_level_gems[i]
		
	if current_level_index + 1 <= MAX_LEVELS:
		max_unlocked_level = maxi(max_unlocked_level, current_level_index + 1)
		
	save_game()
	
	var stats = {
		"level": current_level_index,
		"time": time_elapsed,
		"coins": coins,
		"gems": current_level_gems.duplicate(),
		"gems_count": collected_gems_count,
		"stars": stars
	}
	emit_signal("level_completed", current_level_index, stats)
	return stats

func trigger_screen_shake(intensity: float = 4.0, duration: float = 0.2) -> void:
	if screen_shake_enabled:
		emit_signal("screen_shake_requested", intensity, duration)

func save_game() -> void:
	var save_data = {
		"max_unlocked_level": max_unlocked_level,
		"selected_character": selected_character,
		"coins": coins,
		"score": score,
		"level_records": level_records,
		"sfx_volume": sfx_volume,
		"music_volume": music_volume,
		"screen_shake_enabled": screen_shake_enabled
	}
	var file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	if file:
		var json_str = JSON.stringify(save_data, "\t")
		file.store_string(json_str)
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists("user://savegame.json"):
		return
	var file = FileAccess.open("user://savegame.json", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var json = JSON.new()
		var parse_result = json.parse(content)
		if parse_result == OK:
			var data = json.data
			if data is Dictionary:
				max_unlocked_level = data.get("max_unlocked_level", 1)
				selected_character = data.get("selected_character", 0)
				coins = data.get("coins", 0)
				score = data.get("score", 0)
				sfx_volume = data.get("sfx_volume", 1.0)
				music_volume = data.get("music_volume", 0.8)
				screen_shake_enabled = data.get("screen_shake_enabled", true)
				var saved_recs = data.get("level_records", {})
				for k in saved_recs.keys():
					var key_int = int(k)
					level_records[key_int] = saved_recs[k]
