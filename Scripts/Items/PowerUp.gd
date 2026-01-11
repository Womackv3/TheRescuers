extends Area2D
class_name PowerUp

enum PowerUpType {
    SPEED_UP,
    JUMP_UP,
    WEAPON_UP,
    HEALTH,
    CURRENCY,
    SPELL_UNLOCK
}

@export var type: PowerUpType
@export var value: int = 1

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if body is PlayerController:
        _apply_effect(body)
        queue_free()

func _apply_effect(player: PlayerController) -> void:
    match type:
        PowerUpType.CURRENCY:
            # RogueManager.add_gold(value)
            pass
        PowerUpType.HEALTH:
            # Heal logic
            pass
    print("Picked up %s" % PowerUpType.keys()[type])
    AudioManager.play_sfx(null) # Pass resource
