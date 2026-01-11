extends Node

# Singleton: AudioManager
# Manages Music and SFX pooling.

var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 16

func _ready() -> void:
	_setup_audio()

func _setup_audio() -> void:
	# Music
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)
	
	# SFX Pool
	for i in range(POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_pool.append(player)

func play_music(stream: AudioStream, loop: bool = true) -> void:
	if _music_player.stream == stream and _music_player.playing:
		return
		
	_music_player.stream = stream
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()

func play_sfx(stream: AudioStream, pitch: float = 1.0) -> void:
	var player = _get_free_stream_player()
	if player:
		player.stream = stream
		player.pitch_scale = pitch
		player.play()

func _get_free_stream_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	return null
