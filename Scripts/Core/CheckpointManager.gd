extends Node

# Singleton: CheckpointManager
# Saves progress.

var _saved_stage: int = 1

func save_checkpoint() -> void:
    _saved_stage = GameManager.current_stage
    print("Checkpoint saved at Stage %d" % _saved_stage)

func load_checkpoint() -> void:
    pass
