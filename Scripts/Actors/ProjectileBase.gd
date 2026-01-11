extends Area2D
class_name ProjectileBase

@export var speed: float = 400.0
@export var damage: int = 1
@export var is_player_projectile: bool = true

var _direction: Vector2 = Vector2.ZERO
var _active: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    area_entered.connect(_on_area_entered)

func initialize(pos: Vector2, dir: Vector2) -> void:
    global_position = pos
    _direction = dir.normalized()
    _active = true
    visible = true
    monitoring = true
    monitorable = true
    rotation = _direction.angle()

func _physics_process(delta: float) -> void:
    if not _active:
        return
    global_position += _direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
    if not _active: return
    
    if body.is_in_group("Destructible"):
        if body.has_method("take_damage"):
            body.take_damage(damage)
        deactivate()
    elif body is TileMapLayer:
        deactivate()

func _on_area_entered(area: Area2D) -> void:
    if not _active: return
    
    if is_player_projectile and area.is_in_group("Enemy"):
        if area.has_method("take_damage"):
            area.take_damage(damage)
        deactivate()
    elif not is_player_projectile and area.is_in_group("Player"):
         if area.has_method("take_damage"):
            area.take_damage(damage)
         deactivate()

func deactivate() -> void:
    _active = false
    visible = false
    monitoring = false
    monitorable = false
    # Return to pool logic handled by manager or simply ignored/freed in simple implementation
