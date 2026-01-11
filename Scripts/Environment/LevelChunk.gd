extends Node2D
class_name LevelChunk

@export var chunk_width: float = 640.0
@export var entry_point: Marker2D
@export var exit_point: Marker2D
@export var difficulty: int = 1

func initialize() -> void:
    # Setup enemies or randomized elements
    pass
