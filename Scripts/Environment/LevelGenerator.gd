extends Node2D
class_name LevelGenerator

@export var chunk_prefabs: Array[PackedScene]
@export var boss_chunk_prefab: PackedScene
@export var main_camera: Camera2D
@export var target_chunks: int = 25

var _active_chunks: Array[LevelChunk] = []
var _next_spawn_x: float = 0.0
var _chunks_spawned: int = 0

func _ready() -> void:
    for i in range(3):
        _spawn_next_chunk()

func _process(delta: float) -> void:
    if not main_camera: return
    
    var cam_right_edge = main_camera.global_position.x + get_viewport_rect().size.x
    if _next_spawn_x < cam_right_edge + 640.0:
        _spawn_next_chunk()
        
    _cleanup_chunks(main_camera.global_position.x - 640.0 * 2.0)

func _spawn_next_chunk() -> void:
    if _chunks_spawned >= target_chunks:
        if _chunks_spawned == target_chunks:
            _spawn_boss_chunk()
        return

    if chunk_prefabs.is_empty(): return
    
    var prefab = chunk_prefabs.pick_random()
    var chunk = prefab.instantiate()
    
    add_child(chunk)
    chunk.global_position = Vector2(_next_spawn_x, 0)
    
    _active_chunks.append(chunk)
    _next_spawn_x += chunk.chunk_width
    _chunks_spawned += 1

func _spawn_boss_chunk() -> void:
    if not boss_chunk_prefab: return
    
    var chunk = boss_chunk_prefab.instantiate()
    add_child(chunk)
    chunk.global_position = Vector2(_next_spawn_x, 0)
    _active_chunks.append(chunk)
    
    _chunks_spawned += 1

func _cleanup_chunks(threshold_x: float) -> void:
    for i in range(_active_chunks.size() - 1, -1, -1):
        var chunk = _active_chunks[i]
        if chunk.global_position.x + chunk.chunk_width < threshold_x:
            _active_chunks.remove_at(i)
            chunk.queue_free()
