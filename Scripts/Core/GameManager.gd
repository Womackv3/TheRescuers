extends Node

# Singleton: GameManager
# Manages global state, party data, and game loop (Bosses, Ending).

signal boss_defeated(new_count)
signal game_ended

# Party Data
var recruited_characters: Array[Resource] = [] # List of CharacterStats
var p1_squad: Array[Resource] = [null, null]
var p2_squad: Array[Resource] = [null, null]

# Game State
var current_stage: int = 1
var bosses_defeated: int = 0
const BOSSES_REQUIRED_TO_WIN: int = 6

func _ready() -> void:
	# In Godot 4, Autoloads are added to root, so no need for explicit singleton pattern check like C#
	call_deferred("_debug_init")

func _debug_init() -> void:
	# CharacterDatabase is an Autoload named "CharacterDB"
	if CharacterDB:
		recruit_character(CharacterDB.get_character("ray"))
		recruit_character(CharacterDB.get_character("kaliva"))
		recruit_character(CharacterDB.get_character("barusa"))
		recruit_character(CharacterDB.get_character("toby"))

func recruit_character(character: Resource) -> void:
	if recruited_characters.size() >= 4:
		return
	
	recruited_characters.append(character)
	_assign_to_squad(character)

func _assign_to_squad(character: Resource) -> void:
	# Auto-assign logic: P1 gets 1st/2nd, P2 gets 3rd/4th
	if recruited_characters.size() <= 2:
		if p1_squad[0] == null:
			p1_squad[0] = character
		else:
			p1_squad[1] = character
	else:
		if p2_squad[0] == null:
			p2_squad[0] = character
		else:
			p2_squad[1] = character

func on_boss_defeated() -> void:
	bosses_defeated += 1
	boss_defeated.emit(bosses_defeated)
	
	if bosses_defeated >= BOSSES_REQUIRED_TO_WIN:
		trigger_ending()
	else:
		current_stage += 1
		# Logic to load next level would go here

func trigger_ending() -> void:
	print("YOU SAVED THE PRINCESS! GAME OVER.")
	game_ended.emit()
	get_tree().change_scene_to_file("res://Scenes/UI/EndingScreen.tscn")

func spawn_damage_number(pos: Vector3, value: int, color: Color = Color.WHITE):
	if value <= 0: return
	
	var label = Label3D.new()
	label.text = str(value)
	label.position = pos + Vector3(0, 1.5, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.003 # Smaller for less clutter
	label.fixed_size = true 
	label.no_depth_test = true 
	label.modulate = color
	label.render_priority = 100
	
	# Make visible with outline
	label.outline_size = 4
	label.outline_modulate = Color.BLACK
	
	add_child(label)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + 1.5, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)
