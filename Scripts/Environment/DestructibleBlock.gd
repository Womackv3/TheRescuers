extends StaticBody2D
class_name DestructibleBlock

@export var health: int = 1
@export var drop_prefab: PackedScene

func _ready() -> void:
    add_to_group("Destructible")

func take_damage(dmg: int) -> void:
    health -= dmg
    if health <= 0:
        _destroy()

func _destroy() -> void:
    if drop_prefab:
        var drop = drop_prefab.instantiate()
        drop.global_position = global_position
        get_parent().call_deferred("add_child", drop)
        
    queue_free()
