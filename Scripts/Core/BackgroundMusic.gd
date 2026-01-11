extends AudioStreamPlayer

# Background Music Manager

func _ready():
	# Add to group for PauseMenu access
	add_to_group("BackgroundMusic")
	
	# Set process mode to Always so it can be paused/unpaused even when tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Set to Music bus for volume control
	bus = "Music"
	
	# Loop the music
	if stream:
		if "loop" in stream:
			stream.loop = true
	
	# Start playing
	play()
	
	print("Background music started: ", stream.resource_path)

func play_music(path: String):
	if stream and stream.resource_path == path and playing:
		return # Already playing
		
	var new_stream = load(path)
	if new_stream:
		stream = new_stream
		if "loop" in stream:
			stream.loop = true
		play()
		print("Switched music to: ", path)

func resume_main_theme():
	play_music("res://Assets/Audio/Music/Harp.mp3")
