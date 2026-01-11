extends Resource
class_name CharacterStats

enum ClassType {
    KNIGHT,
    WIZARD,
    MONSTER,
    THIEF,
    ARCHER,
    CLERIC
}

@export var character_class: ClassType
@export var character_name: String
@export var base_health: int
@export var base_speed: int
@export var base_jump: int
@export var base_attack: int
@export var portrait: Texture2D

enum WeaponType {
	NONE,
	SWORD,
	AXE,
	FIREBALL,
	DAGGER,
	ARROW,
	MACE
}

@export var melee_type: WeaponType = WeaponType.NONE
@export var ranged_type: WeaponType = WeaponType.NONE
