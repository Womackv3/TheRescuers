extends Area2D
class_name EnemyBase

enum EnemyRank {
    NORMAL,
    MINIBOSS,
    BOSS
}

@export var health: int = 10
@export var damage: int = 5
@export var speed: float = 100.0
@export var rank: EnemyRank = EnemyRank.NORMAL
# 0: Straight, 1: Sine, 2: Tracking
@export var pattern_type: int = 0
@export var is_boss: bool = false

var _time_alive: float = 0.0
var _start_pos: Vector2

func _ready() -> void:
    _start_pos = global_position
    add_to_group("Enemy")

func _process(delta: float) -> void:
    _time_alive += delta
    
    var move_vec = Vector2.ZERO
    
    match pattern_type:
        0: # Straight Left
            move_vec = Vector2.LEFT
        1: # Sine Wave
            move_vec = Vector2(-1, sin(_time_alive * 5.0) * 0.5)
        2: # Tracking
            # Simple tracking logic would go here
            move_vec = Vector2.LEFT
            
    global_position += move_vec * speed * delta

func take_damage(dmg: int) -> void:
    health -= dmg
    if health <= 0:
        _die()

func _die() -> void:
    if rank == EnemyRank.BOSS:
        GameManager.on_boss_defeated()
        
    # Spawn Loot logic would go here
    
    queue_free()
