extends Node

# Simple Procedural SFX Generator
# Creates basic sound effects programmatically

static func play_footstep(audio_player: AudioStreamPlayer):
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050
	
	var playback = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if not playback:
		audio_player.stream = generator
		audio_player.play()
		playback = audio_player.get_stream_playback()
	
	# Generate soft footstep (short low thump)
	var frames = 2000  # Very short
	for i in range(frames):
		var t = float(i) / frames
		var envelope = exp(-t * 8.0)  # Quick decay
		var freq = 80.0 + (1.0 - t) * 40.0  # Descending pitch
		var sample = sin(t * freq * 0.1) * envelope * 0.15  # Very quiet
		playback.push_frame(Vector2(sample, sample))

static func play_sword_swing(audio_player: AudioStreamPlayer):
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050
	
	var playback = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if not playback:
		audio_player.stream = generator
		audio_player.play()
		playback = audio_player.get_stream_playback()
	
	# Generate whoosh sound
	var frames = 4000
	for i in range(frames):
		var t = float(i) / frames
		var envelope = sin(t * PI)  # Bell curve
		var noise = randf() * 2.0 - 1.0  # White noise
		var sample = noise * envelope * 0.3
		playback.push_frame(Vector2(sample, sample))

static func play_arrow_shoot(audio_player: AudioStreamPlayer):
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050
	
	var playback = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if not playback:
		audio_player.stream = generator
		audio_player.play()
		playback = audio_player.get_stream_playback()
	
	# Generate twang + whoosh
	var frames = 3000
	for i in range(frames):
		var t = float(i) / frames
		var envelope = exp(-t * 5.0)
		var freq = 800.0 - t * 400.0  # Descending pitch
		var tone = sin(t * freq * 0.5) * envelope
		var noise = (randf() * 2.0 - 1.0) * (1.0 - envelope) * 0.2
		var sample = (tone + noise) * 0.4
		playback.push_frame(Vector2(sample, sample))

static func play_impact(audio_player: AudioStreamPlayer):
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050
	
	var playback = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if not playback:
		audio_player.stream = generator
		audio_player.play()
		playback = audio_player.get_stream_playback()
	
	# Generate impact sound
	var frames = 2500
	for i in range(frames):
		var t = float(i) / frames
		var envelope = exp(-t * 10.0)  # Very quick decay
		var noise = randf() * 2.0 - 1.0
		var sample = noise * envelope * 0.5
		playback.push_frame(Vector2(sample, sample))
