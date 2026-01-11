extends Node

# Resolution Manager
# Add this as an Autoload singleton

var resolutions = {
	"1280x720 (16:9)": Vector2i(1280, 720),
	"1920x1080 (16:9)": Vector2i(1920, 1080),
	"2560x1440 (16:9)": Vector2i(2560, 1440),
	"3840x2160 (16:9)": Vector2i(3840, 2160),
	"2560x1080 (21:9)": Vector2i(2560, 1080),
	"3440x1440 (21:9)": Vector2i(3440, 1440),
	"5120x2160 (21:9)": Vector2i(5120, 2160),
	"1920x1200 (16:10)": Vector2i(1920, 1200),
	"2560x1600 (16:10)": Vector2i(2560, 1600),
}

func _ready():
	# Set default resolution
	set_resolution(Vector2i(1920, 1080))

func set_resolution(size: Vector2i):
	DisplayServer.window_set_size(size)
	# Center window
	var screen_size = DisplayServer.screen_get_size()
	var window_pos = (screen_size - size) / 2
	DisplayServer.window_set_position(window_pos)

func set_fullscreen(enabled: bool):
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func toggle_fullscreen():
	var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	set_fullscreen(not is_fullscreen)
