extends Node
## Small procedural arcade sound bank. Keeping the effects synthesized means the
## game has no external audio licenses or asset-loading delay.

const MIX_RATE := 22050
const VOICE_COUNT := 10
const MIX_HEADROOM_DB := -3.0
const MUSIC_HEADROOM_DB := -10.0

var streams: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var next_voice := 0
var effects_volume := 0.7
var bgm_volume := 0.45
var muted := false

func _ready() -> void:
	_build_sound_bank()
	for i in range(VOICE_COUNT):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = _effects_volume_db()
		add_child(voice)
		voices.append(voice)
	music_player = AudioStreamPlayer.new()
	music_player.stream = _music_loop()
	music_player.volume_db = _bgm_volume_db()
	add_child(music_player)
	music_player.play()

func set_mix_volumes(new_bgm_volume: float, new_effects_volume: float,
		should_mute: bool = false) -> void:
	bgm_volume = clampf(new_bgm_volume, 0.0, 1.0)
	effects_volume = clampf(new_effects_volume, 0.0, 1.0)
	muted = should_mute
	var effects_level := _effects_volume_db()
	for voice in voices:
		voice.volume_db = effects_level
	if is_instance_valid(music_player):
		music_player.volume_db = _bgm_volume_db()

func _effects_volume_db() -> float:
	if muted or effects_volume <= 0.001:
		return -80.0
	return linear_to_db(effects_volume) + MIX_HEADROOM_DB

func _bgm_volume_db() -> float:
	if muted or bgm_volume <= 0.001:
		return -80.0
	return linear_to_db(bgm_volume) + MUSIC_HEADROOM_DB

func play_cue(cue: String, pitch: float = 1.0) -> void:
	if not streams.has(cue) or voices.is_empty():
		return
	var voice := _available_voice()
	voice.stream = streams[cue]
	voice.pitch_scale = pitch
	voice.play()

func _available_voice() -> AudioStreamPlayer:
	for voice in voices:
		if not voice.playing:
			return voice
	var voice := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	return voice

func _build_sound_bank() -> void:
	streams = {
		"ui": _tone(480.0, 700.0, 0.08, 0.22, "sine"),
		"barrier": _tone(620.0, 1050.0, 0.14, 0.25, "triangle"),
		"error": _tone(190.0, 145.0, 0.16, 0.22, "square"),
		"bounce": _tone(260.0, 440.0, 0.12, 0.30, "square"),
		"bonk": _tone(185.0, 70.0, 0.20, 0.42, "triangle"),
		"hurt": _tone(145.0, 58.0, 0.34, 0.38, "square"),
		"defeat": _tone(230.0, 42.0, 0.78, 0.34, "triangle"),
		"boss_hit": _tone(105.0, 210.0, 0.22, 0.38, "square"),
		"boss_defeat": _tone(290.0, 38.0, 0.85, 0.42, "triangle"),
		"bomb": _tone(95.0, 26.0, 0.62, 0.55, "square"),
		"heal": _tone(430.0, 980.0, 0.34, 0.30, "sine"),
		"ready": _tone(610.0, 1120.0, 0.28, 0.26, "triangle"),
		"victory": _tone(390.0, 1040.0, 0.72, 0.30, "triangle"),
	}

func _tone(start_frequency: float, end_frequency: float, duration: float,
		amplitude: float, waveform: String) -> AudioStreamWAV:
	var sample_count := maxi(1, int(duration * MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var phase := 0.0
	var attack := minf(0.012, duration * 0.2)
	var release := minf(0.075, duration * 0.35)
	for i in range(sample_count):
		var time := i / float(MIX_RATE)
		var progress := time / duration
		var frequency := lerpf(start_frequency, end_frequency, progress)
		phase += TAU * frequency / MIX_RATE
		var wave := sin(phase)
		if waveform == "square":
			wave = 1.0 if wave >= 0.0 else -1.0
		elif waveform == "triangle":
			wave = asin(wave) * 2.0 / PI
		var envelope := minf(1.0, minf(time / attack, (duration - time) / release))
		var sample := int(clampf(wave * envelope * amplitude, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream

func _music_loop() -> AudioStreamWAV:
	var duration := 4.0
	var sample_count := int(duration * MIX_RATE)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var melody := PackedFloat32Array([220.0, 277.18, 329.63, 277.18, 246.94, 293.66, 369.99, 293.66])
	for i in range(sample_count):
		var time := i / float(MIX_RATE)
		var note_index := mini(int(time / 0.5), melody.size() - 1)
		var note_time := fmod(time, 0.5)
		var note_envelope := pow(sin(PI * note_time / 0.5), 2.0)
		var bass := sin(TAU * 55.0 * time) * 0.13
		var pad := (sin(TAU * 110.0 * time) + sin(TAU * 165.0 * time) * 0.6) * 0.045
		var lead := sin(TAU * melody[note_index] * note_time) * note_envelope * 0.075
		var sample := int(clampf(bass + pad + lead, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream
