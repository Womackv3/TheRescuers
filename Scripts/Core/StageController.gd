extends Node2D
class_name StageController

@export var scroll_speed: float = 50.0
@export var main_camera: Camera2D

var _is_scrolling: bool = true

func _process(delta: float) -> void:
    if _is_scrolling and main_camera:
        main_camera.position.x += scroll_speed * delta

func stop_scrolling() -> void:
    _is_scrolling = false

func resume_scrolling() -> void:
    _is_scrolling = true
