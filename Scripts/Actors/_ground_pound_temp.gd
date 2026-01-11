func _perform_ground_pound_impact():
	# Get player stats
	var stats = CharacterDB.get_character("ray")
	if not stats:
		return
	
	# Calculate damage: half of base attack, scaled by damage_mult
	var base_damage = stats.base_attack * 0.5
	var damage = int(base_damage * PlayerStats.damage_mult)
	
	# Get VoxelWorld
	var world = get_tree().get_first_node_in_group("VoxelWorld")
	if not world:
		return
	
	# Get player position in grid coordinates
	var player_grid_pos = global_position / world.block_size
	var center_x = int(player_grid_pos.x)
	var center_z = int(player_grid_pos.z)
	var y = int(player_grid_pos.y) - 1 # Block directly below
	
	# Damage 3x3 area below player
	for x_offset in range(-1, 2):
		for z_offset in range(-1, 2):
			var block_pos = Vector3i(center_x + x_offset, y, center_z + z_offset)
			world.damage_block(block_pos, damage)
	
	# Visual/Audio feedback
	var combat_player = get_node_or_null("CombatPlayer")
	if combat_player:
		combat_player.stream = sfx_sword_hit
		combat_player.pitch_scale = 0.7
		combat_player.play()
	
	# Camera shake
	if camera:
		var tween = create_tween()
		var original_pos = camera.position
		tween.tween_property(camera, "position", original_pos + Vector3(0.2, 0, 0.2), 0.05)
		tween.tween_property(camera, "position", original_pos - Vector3(0.2, 0, 0.2), 0.05)
		tween.tween_property(camera, "position", original_pos, 0.05)
	
	print("Ground Pound! Damage: ", damage)
