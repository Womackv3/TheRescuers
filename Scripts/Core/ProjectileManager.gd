extends Node
# Note: This is NOT an Autoload in the C# version plan, it was a node in the scene.
# However, for ease of access, making it accessible via group or unique name is good.
# Or we can make it an Autoload if we want global access without reference passing.
# The C# plan had "Instance" static. Let's stick to Scene-based for now but maybe add to group "ProjectileManager".

class_name ProjectileManager

@export var default_projectile_prefab: PackedScene
var _pool: Array[ProjectileBase] = []

func spawn_player_projectile(pos: Vector2, dir: Vector2) -> void:
    var proj = _get_free_projectile()
    if proj:
        proj.is_player_projectile = true
        proj.collision_mask = 0b101 # Example
        proj.initialize(pos, dir)

func _get_free_projectile() -> ProjectileBase:
    for p in _pool:
        if not p._active:
            return p
            
    if default_projectile_prefab:
        var new_proj = default_projectile_prefab.instantiate()
        add_child(new_proj)
        _pool.append(new_proj)
        return new_proj
    
    return null
