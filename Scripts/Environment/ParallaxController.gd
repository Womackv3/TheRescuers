extends Node2D
class_name ParallaxController

@export var main_camera: Camera2D

# This script mainly serves as a hook for dynamic background changes
# Standard ParallaxBackground nodes should be used for the actual scrolling

func set_theme(tint: Color) -> void:
    modulate = tint
