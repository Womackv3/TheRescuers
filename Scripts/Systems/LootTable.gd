extends Node
class_name LootTable

@export var common_drops: Array[PackedScene]
@export var rare_drops: Array[PackedScene]

func roll_loot() -> Node:
    var roll = randf()
    if roll > 0.9: # 10% Rare
        if not rare_drops.is_empty():
            return rare_drops.pick_random().instantiate()
    elif roll > 0.5: # 40% Common
        if not common_drops.is_empty():
            return common_drops.pick_random().instantiate()
            
    return null
