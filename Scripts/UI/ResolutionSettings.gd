extends Control

# Simple resolution settings UI
# Add this to your main menu or settings screen

@onready var resolution_option = $VBoxContainer/ResolutionOption
@onready var fullscreen_check = $VBoxContainer/FullscreenCheck

func _ready():
	# Populate resolution dropdown
	for res_name in ResolutionManager.resolutions.keys():
		resolution_option.add_item(res_name)
	
	# Set current resolution
	resolution_option.selected = 1 # Default to 1920x1080
	
	# Fullscreen toggle
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func _on_resolution_option_item_selected(index):
	var res_name = resolution_option.get_item_text(index)
	var resolution = ResolutionManager.resolutions[res_name]
	ResolutionManager.set_resolution(resolution)

func _on_fullscreen_check_toggled(button_pressed):
	ResolutionManager.set_fullscreen(button_pressed)
