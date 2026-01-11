extends CanvasLayer

# Pause Menu - Press ESC to open

@onready var panel = $Panel
@onready var tab_container = $Panel/MarginContainer/VBoxContainer/TabContainer

# Controls Tab
@onready var forward_button = $Panel/MarginContainer/VBoxContainer/TabContainer/Controls/ScrollContainer/VBoxContainer/ForwardButton
@onready var backward_button = $Panel/MarginContainer/VBoxContainer/TabContainer/Controls/ScrollContainer/VBoxContainer/BackwardButton
@onready var left_button = $Panel/MarginContainer/VBoxContainer/TabContainer/Controls/ScrollContainer/VBoxContainer/LeftButton
@onready var right_button = $Panel/MarginContainer/VBoxContainer/TabContainer/Controls/ScrollContainer/VBoxContainer/RightButton

# Graphics Tab
@onready var resolution_option = $Panel/MarginContainer/VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/ResolutionOption
@onready var fullscreen_check = $Panel/MarginContainer/VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/FullscreenCheck
@onready var vsync_check = $Panel/MarginContainer/VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/VsyncCheck

# Audio Tab
@onready var master_slider = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/ScrollContainer/VBoxContainer/MasterSlider
@onready var music_slider = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/ScrollContainer/VBoxContainer/MusicSlider
@onready var sfx_slider = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/ScrollContainer/VBoxContainer/SfxSlider

# Buttons
@onready var resume_button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/ResumeButton
@onready var quit_button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/QuitButton

var is_paused = false
var awaiting_input_for_action = ""

# Pause menu music
var pause_music: AudioStreamPlayer

func _ready():
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Setup pause menu music
	pause_music = AudioStreamPlayer.new()
	pause_music.stream = load("res://Assets/Audio/Music/FunkPauseUpgrade.mp3")
	pause_music.bus = "Music"
	pause_music.volume_db = -3  # Slightly quieter
	add_child(pause_music)
	
	# Setup controls
	_setup_controls_tab()
	_setup_graphics_tab()
	_setup_audio_tab()
	
	# Connect buttons
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _input(event):
	if event.is_action_pressed("ui_cancel"): # ESC key
		toggle_pause()
	
	# Handle key rebinding
	if awaiting_input_for_action != "" and event is InputEventKey and event.pressed:
		_rebind_key(awaiting_input_for_action, event)
		awaiting_input_for_action = ""

func toggle_pause():
	is_paused = !is_paused
	
	if is_paused:
		show()
		get_tree().paused = true
		# Pause background music and play pause menu music
		var bg_music = get_tree().get_first_node_in_group("BackgroundMusic")
		if bg_music and bg_music is AudioStreamPlayer:
			bg_music.stream_paused = true
		if pause_music:
			pause_music.play()
	else:
		hide()
		get_tree().paused = false
		# Resume background music and stop pause menu music
		var bg_music = get_tree().get_first_node_in_group("BackgroundMusic")
		if bg_music and bg_music is AudioStreamPlayer:
			bg_music.stream_paused = false
		if pause_music:
			pause_music.stop()

func _on_resume_pressed():
	toggle_pause()

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().quit()

# ===== CONTROLS TAB =====
func _setup_controls_tab():
	forward_button.pressed.connect(_start_rebind.bind("p1_move_up"))
	backward_button.pressed.connect(_start_rebind.bind("p1_move_down"))
	left_button.pressed.connect(_start_rebind.bind("p1_move_left"))
	right_button.pressed.connect(_start_rebind.bind("p1_move_right"))
	
	_update_control_labels()

func _start_rebind(action_name: String):
	awaiting_input_for_action = action_name
	var button = get_button_for_action(action_name)
	if button:
		button.text = "Press any key..."

func _rebind_key(action_name: String, event: InputEventKey):
	# Clear existing bindings
	InputMap.action_erase_events(action_name)
	
	# Add new binding
	InputMap.action_add_event(action_name, event)
	
	_update_control_labels()

func _update_control_labels():
	forward_button.text = "Forward: " + _get_key_name("p1_move_up")
	backward_button.text = "Backward: " + _get_key_name("p1_move_down")
	left_button.text = "Left: " + _get_key_name("p1_move_left")
	right_button.text = "Right: " + _get_key_name("p1_move_right")

func _get_key_name(action_name: String) -> String:
	var events = InputMap.action_get_events(action_name)
	if events.size() > 0 and events[0] is InputEventKey:
		return OS.get_keycode_string(events[0].keycode)
	return "None"

func get_button_for_action(action_name: String) -> Button:
	match action_name:
		"p1_move_up": return forward_button
		"p1_move_down": return backward_button
		"p1_move_left": return left_button
		"p1_move_right": return right_button
	return null

# ===== GRAPHICS TAB =====
func _setup_graphics_tab():
	# Populate resolutions
	for res_name in ResolutionManager.resolutions.keys():
		resolution_option.add_item(res_name)
	
	resolution_option.selected = 1 # Default 1920x1080
	resolution_option.item_selected.connect(_on_resolution_changed)
	
	# Fullscreen
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	
	# VSync
	vsync_check.button_pressed = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	vsync_check.toggled.connect(_on_vsync_toggled)

func _on_resolution_changed(index: int):
	var res_name = resolution_option.get_item_text(index)
	var resolution = ResolutionManager.resolutions[res_name]
	ResolutionManager.set_resolution(resolution)

func _on_fullscreen_toggled(enabled: bool):
	ResolutionManager.set_fullscreen(enabled)

func _on_vsync_toggled(enabled: bool):
	if enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

# ===== AUDIO TAB =====
func _setup_audio_tab():
	# Setup sliders
	master_slider.min_value = 0
	master_slider.max_value = 100
	master_slider.value = 30  # Default 30%
	master_slider.value_changed.connect(_on_master_volume_changed)
	
	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.value = 80
	music_slider.value_changed.connect(_on_music_volume_changed)
	
	sfx_slider.min_value = 0
	sfx_slider.max_value = 100
	sfx_slider.value = 100
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Apply initial volume
	_on_master_volume_changed(30)

func _on_master_volume_changed(value: float):
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func _on_music_volume_changed(value: float):
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)

func _on_sfx_volume_changed(value: float):
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)
