extends Node

# Autoload: CharacterDB
# Stores the definitions for all characters.

var characters: Dictionary = {}

func _ready() -> void:
    _initialize_database()

func _initialize_database() -> void:
    # Ray Jack (Knight)
    var ray = CharacterStats.new()
    ray.character_name = "Ray Jack"
    ray.character_class = CharacterStats.ClassType.KNIGHT
    ray.base_health = 100
    ray.base_attack = 10
    ray.base_speed = 150
    ray.melee_type = CharacterStats.WeaponType.SWORD
    ray.ranged_type = CharacterStats.WeaponType.AXE
    characters["ray"] = ray

    # Kaliva (Wizard)
    var kaliva = CharacterStats.new()
    kaliva.character_name = "Kaliva"
    kaliva.character_class = CharacterStats.ClassType.WIZARD
    kaliva.base_health = 60
    kaliva.base_attack = 15
    kaliva.base_speed = 140
    characters["kaliva"] = kaliva

    # Barusa (Monster)
    var barusa = CharacterStats.new()
    barusa.character_name = "Barusa"
    barusa.character_class = CharacterStats.ClassType.MONSTER
    barusa.base_health = 150
    barusa.base_attack = 12
    barusa.base_speed = 120
    characters["barusa"] = barusa

    # Toby (Thief)
    var toby = CharacterStats.new()
    toby.character_name = "Toby"
    toby.character_class = CharacterStats.ClassType.THIEF
    toby.base_health = 70
    toby.base_attack = 8
    toby.base_speed = 180
    characters["toby"] = toby

    # Archer
    var archer = CharacterStats.new()
    archer.character_name = "Archer"
    archer.character_class = CharacterStats.ClassType.ARCHER
    archer.base_health = 80
    archer.base_attack = 9
    archer.base_speed = 160
    characters["archer"] = archer

    # Cleric
    var cleric = CharacterStats.new()
    cleric.character_name = "Cleric"
    cleric.character_class = CharacterStats.ClassType.CLERIC
    cleric.base_health = 90
    cleric.base_attack = 5
    cleric.base_speed = 130
    characters["cleric"] = cleric

func get_character(id: String) -> CharacterStats:
    if characters.has(id):
        return characters[id]
    return null
