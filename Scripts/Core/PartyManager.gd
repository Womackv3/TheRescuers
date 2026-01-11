extends Node

# Singleton: PartyManager
# Handles character recruitment and squad input logic.

func _ready() -> void:
    pass

# Logic to handle "Swap" input from P1/P2
func swap_character(player_index: int) -> void:
    # Access global squad data via GameManager
    var squad = []
    if player_index == 1:
        squad = GameManager.p1_squad
    else:
        squad = GameManager.p2_squad
        
    # Allow swap if both slots have characters
    if squad[0] != null and squad[1] != null:
        # Tell FormationManager to rotate
        if FormationManager:
            FormationManager.rotate_squad(player_index)
