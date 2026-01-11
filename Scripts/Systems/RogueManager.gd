extends Node

# Singleton: RogueManager
# Tracks run progression (Gold, Keys, Unlocks).

var gold: int = 0
var keys: int = 0
var unlocked_spells: Dictionary = {} # Key: ClassType (int), Value: Array[Resource]

func _ready() -> void:
    pass

func add_gold(amount: int) -> void:
    gold += amount
    print("Gold: %d" % gold)

func unlock_spell(char_class: int, spell: Resource) -> void:
    if not unlocked_spells.has(char_class):
        unlocked_spells[char_class] = []
        
    unlocked_spells[char_class].append(spell)
    print("Unlocked spell for class ID %d!" % char_class)
