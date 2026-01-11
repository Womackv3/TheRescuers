extends Node

# Singleton: FormationManager
# Handles squad positioning.

var _active_leaders: Dictionary = {} # Key: PlayerIndex (int), Value: PlayerController (Node)

func _ready() -> void:
    pass

# Called by PlayerController when it spawns? 
# Or PlayerController registers itself.

func register_leader(player_index: int, controller: Node) -> void:
    _active_leaders[player_index] = controller

func rotate_squad(player_index: int) -> void:
    print("P%d swapped formation!" % player_index)
    # Visual swap logic implementation
