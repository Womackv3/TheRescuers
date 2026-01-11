extends CanvasLayer

@onready var panel = $PanelContainer

func _ready():
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS # Work even when paused (if we decided to pause)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_QUOTELEFT: # Tilde `
			visible = !visible
			# Optional: Pause game? 
			# get_tree().paused = visible
			
			if visible:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # Keep cursor visible for game

# Signal handlers
func _on_god_mode_toggled(toggled_on):
	var player = get_tree().get_first_node_in_group("Player")
	if player and "is_god_mode" in player:
		player.is_god_mode = toggled_on
		print("God Mode: ", toggled_on)

func _on_level_up_pressed():
	PlayerStats.add_xp(PlayerStats.xp_to_next_level)
	print("Dev: Level Up Triggered")

func _on_spawn_enemy_pressed(type_index: int):
	var player = get_tree().get_first_node_in_group("Player")
	if not player: return
	
	var spawn_pos = player.global_position + player.global_transform.basis.z * -3.0 # 3 meters in front
	
	var world = get_tree().get_first_node_in_group("VoxelWorld")
	if world and world.has_method("spawn_enemy"):
		# 0: Snake, 1: Knight
		var enemy_type = "snake" if type_index == 0 else "k_guard"
		# Actually VoxelWorld interacts with VoxelEnemyFactory, usually we just spawn manually or ask Factory
		
		var factory = load("res://Scripts/Actors/VoxelEnemyFactory.gd").new()
		var enemy = null
		if type_index == 0:
			enemy = factory.create_enemy("snake")
		elif type_index == 1:
			enemy = factory.create_enemy("k_guard")
			
		if enemy:
			# Find parent (VoxelWorld or Game)
			player.get_parent().add_child(enemy)
			enemy.global_position = spawn_pos
			print("Spawned Entity ", type_index)
