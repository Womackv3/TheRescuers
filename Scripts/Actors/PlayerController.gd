extends CharacterBody2D
class_name PlayerController

@export var player_index: int = 1 # 1 or 2
@export var stats: Resource # CharacterStats

var _input_dir: Vector2
var _move_speed: float = 150.0

func _physics_process(delta: float) -> void:
    _handle_input()
    _handle_movement(delta)
    move_and_slide()
    _constrain_to_bounds()

func _handle_input() -> void:
    var prefix = "p1_" if player_index == 1 else "p2_"
    _input_dir = Input.get_vector(prefix + "move_left", prefix + "move_right", prefix + "move_up", prefix + "move_down")

    if Input.is_action_just_pressed(prefix + "shoot"):
        _shoot()
    
    if Input.is_action_just_pressed(prefix + "spell"):
        _cast_spell()

func _handle_movement(delta: float) -> void:
    velocity = _input_dir * _move_speed

func _shoot() -> void:
    # Call ProjectileManager to spawn bullet
    # ProjectileManager.spawn_player_projectile(global_position, Vector2.UP)
    print("P%d Shoot!" % player_index)

func _cast_spell() -> void:
    print("P%d Cast Spell!" % player_index)

func _constrain_to_bounds() -> void:
    # Simple clamp logic if needed
    pass
