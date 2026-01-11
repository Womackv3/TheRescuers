extends StaticBody3D

var health: int = 10
var material_override: Material
var tree_controller = null # Reference to TreeController if part of a tree
var is_trunk: bool = false

func _ready():
	# Try to find material from parent mesh if not set
	if not material_override:
		var parent = get_parent()
		if parent is MeshInstance3D:
			material_override = parent.material_override

func take_damage(amount: int, source_pos: Vector3 = Vector3.ZERO):
	health -= amount
	
	# Show damage number - DISABLED for trees to reduce visual clutter
	# if GameManager.has_method("spawn_damage_number"):
	# 	GameManager.spawn_damage_number(global_position, amount, Color(1, 1, 0)) # Yellow for props
	
	# Visual feedback - Always spawn small debris on hit
	var world = get_tree().get_first_node_in_group("VoxelWorld")
	if world and world.has_method("spawn_debris"):
		var color = Color.WHITE
		if material_override is StandardMaterial3D:
			color = material_override.albedo_color
		elif material_override is ShaderMaterial:
			# Try to get albedo param
			var c = material_override.get_shader_parameter("albedo")
			if c is Color: color = c
			
		world.spawn_debris(global_position, color)
		
	if health <= 0:
		if is_trunk and tree_controller and tree_controller.has_method("trigger_fall"):
			# Instead of just dying, trigger whole tree to fall
			# We pass the hit pos and a dummy damage source (or could pass from projectile)
			tree_controller.trigger_fall(global_position, global_position - Vector3(0,0,1))
		else:
			die()

func die():
	var world = get_tree().get_first_node_in_group("VoxelWorld")
	if world:
		# Explosion effect
		var color = Color.WHITE
		if material_override is StandardMaterial3D:
			color = material_override.albedo_color
			
		for i in range(3):
			world.spawn_debris(global_position, color)
		
		# Loot
		if world.has_method("spawn_loot"):
			world.spawn_loot(global_position)
			
	# Remove the voxel (MeshInstance parent)
	get_parent().queue_free()
