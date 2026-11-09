extends Node

# Audio Players Pool
var sfx_players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 12

var music_player_lead: AudioStreamPlayer
var music_player_bass: AudioStreamPlayer

# Pre-synthesized sound streams cache
var sfx_streams: Dictionary = {}

# Music Sequencer state
var music_timer: float = 0.0
var music_step: int = 0
var current_track: String = ""
var tempo_bpm: float = 135.0
var step_duration: float = 0.111 # 16th note at 135 BPM

# Note frequencies (in Hz)
const NOTES = {
	"C3": 130.81, "D3": 146.83, "E3": 164.81, "F3": 174.61, "G3": 196.00, "A3": 220.00, "B3": 246.94,
	"C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23, "G4": 392.00, "A4": 440.00, "B4": 493.88,
	"C5": 523.25, "D5": 587.33, "E5": 659.25, "F5": 698.46, "G5": 783.99, "A5": 880.00, "B5": 987.77,
	"C6": 1046.50, "REST": 0.0
}

# Music tracks sequences (16-step patterns)
const TRACKS = {
	"title": {
		"bpm": 125.0,
		"lead": ["C5", "E5", "G5", "C6", "B5", "G5", "E5", "REST", "A5", "C6", "E6", "REST", "G5", "F5", "E5", "D5"],
		"bass": ["C3", "REST", "C3", "REST", "G3", "REST", "G3", "REST", "A3", "REST", "A3", "REST", "F3", "REST", "G3", "REST"]
	},
	"level": {
		"bpm": 135.0,
		"lead": ["C5", "REST", "G4", "C5", "E5", "REST", "D5", "REST", "C5", "D5", "E5", "F5", "G5", "REST", "C6", "REST"],
		"bass": ["C3", "C3", "E3", "C3", "F3", "F3", "G3", "REST", "A3", "A3", "G3", "REST", "F3", "REST", "G3", "G3"]
	},
	"boss": {
		"bpm": 150.0,
		"lead": ["D5", "D5", "F5", "D5", "G#5", "G5", "F5", "D5", "D5", "F5", "D5", "C5", "D5", "REST", "G5", "REST"],
		"bass": ["D3", "D3", "D3", "D3", "G#3", "G#3", "G3", "F3", "D3", "D3", "D3", "D3", "F3", "F3", "G3", "A3"]
	}
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_sfx_pool()
	_synthesize_all_sfx()
	_init_music_players()

func _init_sfx_pool() -> void:
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)

func _init_music_players() -> void:
	music_player_lead = AudioStreamPlayer.new()
	music_player_lead.bus = "Master"
	add_child(music_player_lead)
	
	music_player_bass = AudioStreamPlayer.new()
	music_player_bass.bus = "Master"
	add_child(music_player_bass)

func _process(delta: float) -> void:
	if current_track == "" or not TRACKS.has(current_track):
		return
		
	var gm = get_node_or_null("/root/GameManager")
	var vol_mult = gm.music_volume if gm else 0.8
	if vol_mult <= 0.01:
		return
		
	music_timer += delta
	if music_timer >= step_duration:
		music_timer -= step_duration
		_play_sequencer_step()

func _play_sequencer_step() -> void:
	var trk = TRACKS[current_track]
	var lead_seq = trk["lead"]
	var bass_seq = trk["bass"]
	
	var lead_note = lead_seq[music_step % lead_seq.size()]
	var bass_note = bass_seq[music_step % bass_seq.size()]
	
	var gm = get_node_or_null("/root/GameManager")
	var vol = gm.music_volume if gm else 0.8
	
	if lead_note != "REST" and NOTES.has(lead_note):
		var lead_wav = _create_wave_tone(NOTES[lead_note], step_duration * 0.85, "square", 0.18 * vol)
		music_player_lead.stream = lead_wav
		music_player_lead.play()
		
	if bass_note != "REST" and NOTES.has(bass_note):
		var bass_wav = _create_wave_tone(NOTES[bass_note], step_duration * 0.9, "triangle", 0.28 * vol)
		music_player_bass.stream = bass_wav
		music_player_bass.play()
		
	music_step = (music_step + 1) % 16

func play_music(track_name: String) -> void:
	if current_track == track_name:
		return
	current_track = track_name
	music_step = 0
	music_timer = 0.0
	if TRACKS.has(track_name):
		tempo_bpm = TRACKS[track_name]["bpm"]
		step_duration = (60.0 / tempo_bpm) / 4.0

func stop_music() -> void:
	current_track = ""
	music_player_lead.stop()
	music_player_bass.stop()

# Sound Synthesis Helper
func _create_wave_tone(freq: float, duration: float, type: String = "square", volume: float = 0.3) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var val = 0.0
		var phase = fmod(t * freq, 1.0)
		
		if type == "square":
			val = 1.0 if phase < 0.5 else -1.0
		elif type == "triangle":
			val = 4.0 * abs(phase - 0.5) - 1.0
		elif type == "sine":
			val = sin(TAU * phase)
		elif type == "noise":
			val = randf_range(-1.0, 1.0)
			
		# Linear fade out decay
		var decay = maxf(0.0, 1.0 - (float(i) / float(num_samples)))
		var sample_val = int(clampf(val * volume * decay, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav

# Synthesize all SFX on boot
func _synthesize_all_sfx() -> void:
	sfx_streams["jump"] = _synth_sweep(180.0, 480.0, 0.12, "square", 0.25)
	sfx_streams["coin"] = _synth_twotone(987.77, 1318.51, 0.07, 0.18, "square", 0.22)
	sfx_streams["gem"] = _synth_arpeggio([523.25, 659.25, 1046.50], 0.08, "square", 0.25)
	sfx_streams["dash"] = _synth_noise_burst(0.12, 0.28)
	sfx_streams["stomp"] = _synth_sweep(240.0, 60.0, 0.14, "triangle", 0.35)
	sfx_streams["spring"] = _synth_bend(200.0, 750.0, 0.22, 0.28)
	sfx_streams["hurt"] = _synth_sweep(220.0, 50.0, 0.22, "noise_sweep", 0.35)
	sfx_streams["key"] = _synth_arpeggio([440.0, 554.37, 659.25, 880.0], 0.07, "triangle", 0.25)
	sfx_streams["door"] = _synth_sweep(80.0, 30.0, 0.35, "triangle", 0.4)
	sfx_streams["checkpoint"] = _synth_arpeggio([440.0, 659.25, 880.0, 1046.50], 0.09, "square", 0.25)
	sfx_streams["clear"] = _synth_fanfare()
	sfx_streams["boss_roar"] = _synth_roar()
	sfx_streams["boss_hit"] = _synth_sweep(120.0, 40.0, 0.25, "square", 0.4)
	sfx_streams["game_over"] = _synth_arpeggio([440.0, 415.3, 392.0, 349.2], 0.18, "triangle", 0.3)

func _synth_sweep(f_start: float, f_end: float, duration: float, type: String, volume: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / float(num_samples)
		var freq = lerpf(f_start, f_end, t)
		phase += (freq / float(sample_rate))
		if phase >= 1.0:
			phase -= floor(phase)
			
		var val = 0.0
		if type == "square":
			val = 1.0 if phase < 0.5 else -1.0
		elif type == "triangle":
			val = 4.0 * abs(phase - 0.5) - 1.0
		elif type == "noise_sweep":
			val = (1.0 if phase < 0.5 else -1.0) * 0.6 + randf_range(-0.4, 0.4)
			
		var decay = maxf(0.0, 1.0 - t)
		var sample_val = int(clampf(val * volume * decay, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav

func _synth_twotone(f1: float, f2: float, d1: float, d2: float, _type: String, volume: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var total_dur = d1 + d2
	var num_samples = int(sample_rate * total_dur)
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var freq = f1 if t < d1 else f2
		phase += (freq / float(sample_rate))
		if phase >= 1.0:
			phase -= floor(phase)
		var val = 1.0 if phase < 0.5 else -1.0
		var decay = maxf(0.0, 1.0 - (t / total_dur))
		var sample_val = int(clampf(val * volume * decay, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav

func _synth_arpeggio(freqs: Array, note_duration: float, _type: String, volume: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var total_dur = note_duration * freqs.size()
	var num_samples = int(sample_rate * total_dur)
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var note_idx = mini(int(t / note_duration), freqs.size() - 1)
		var freq = freqs[note_idx]
		phase += (freq / float(sample_rate))
		if phase >= 1.0:
			phase -= floor(phase)
			
		var val = 1.0 if phase < 0.5 else -1.0
		var note_t = fmod(t, note_duration) / note_duration
		var decay = maxf(0.0, 1.0 - note_t * 0.8)
		var sample_val = int(clampf(val * volume * decay, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav

func _synth_noise_burst(duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / float(num_samples)
		var val = randf_range(-1.0, 1.0)
		var decay = (1.0 - t) * (1.0 - t)
		var sample_val = int(clampf(val * volume * decay, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav

func _synth_bend(f_start: float, f_peak: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / float(num_samples)
		var freq = lerpf(f_start, f_peak, sin(t * PI))
		phase += (freq / float(sample_rate))
		if phase >= 1.0:
			phase -= floor(phase)
		var val = 1.0 if phase < 0.5 else -1.0
		var decay = maxf(0.0, 1.0 - t * 0.5)
		var sample_val = int(clampf(val * volume * decay, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav

func _synth_fanfare() -> AudioStreamWAV:
	return _synth_arpeggio([523.25, 659.25, 783.99, 1046.50, 1318.51], 0.12, "square", 0.3)

func _synth_roar() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.65
	var num_samples = int(sample_rate * duration)
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / float(num_samples)
		var freq = lerpf(110.0, 45.0, t) + sin(t * 40.0) * 15.0
		phase += (freq / float(sample_rate))
		if phase >= 1.0:
			phase -= floor(phase)
		var sq = 1.0 if phase < 0.5 else -1.0
		var val = sq * 0.6 + randf_range(-0.4, 0.4)
		var decay = maxf(0.0, 1.0 - t * 0.8)
		var sample_val = int(clampf(val * 0.4 * decay, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav

# Public SFX Playback
func play_sfx(sfx_name: String) -> void:
	if not sfx_streams.has(sfx_name):
		return
		
	var gm = get_node_or_null("/root/GameManager")
	var vol_mult = gm.sfx_volume if gm else 1.0
	if vol_mult <= 0.01:
		return
		
	# Find available player in pool
	for player in sfx_players:
		if not player.playing:
			player.stream = sfx_streams[sfx_name]
			player.volume_db = linear_to_db(vol_mult)
			player.play()
			return
			
	# If all busy, steal the first player
	var fallback_player = sfx_players[0]
	fallback_player.stream = sfx_streams[sfx_name]
	fallback_player.volume_db = linear_to_db(vol_mult)
	fallback_player.play()
