extends Area3D

var speed = 20.0
var direction = Vector3.FORWARD
var type = 0 # 1=Sword(Beam), 2=Axe

var mesh_instance : Node3D

func _ready():
	monitorable = true
	monitoring = true
	body_entered.connect(_on_body_entered)
	
	# Auto destroy after 3 seconds
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.autostart = true
	timer.connect("timeout", queue_free)
	add_child(timer)
	
	_setup_visuals()

var damage: int = 10

func setup(start_pos: Vector3, dir: Vector3, weapon_type: int, base_damage: int):
	position = start_pos
	direction = dir.normalized()
	type = weapon_type
	look_at(position + direction)
	
	# Apply stat multipliers
	speed *= PlayerStats.shot_speed_mult
	damage = int(base_damage * PlayerStats.damage_mult)

func _physics_process(delta):
	position += direction * speed * delta
	
	if type == 2: # Axe spins
		if mesh_instance:
			mesh_instance.rotate_object_local(Vector3.RIGHT, 15.0 * delta)

func _setup_visuals():
	var visual_node : Node3D
	
	if type == 2: # AXE
		visual_node = VoxelWeaponFactory.create_axe()
		# Rotate axe to spin nicely
		# Default axe handle is vertical Y.
		# We want it to spin around X axis as it flies forward (Z)
		visual_node.rotation_degrees.z = -90 # Lay flat? or Vertical?
		# Actually let's just let physics process rotate it
	else: # SWORD / Beam (Fallback)
		visual_node = VoxelWeaponFactory.create_sword()
		visual_node.rotation_degrees.x = 90 # Point forward
		
	mesh_instance = visual_node # Keep reference for rotation
	add_child(visual_node)
	
	# Make visuals unshaded
	_setup_visuals_recursive(visual_node)
	
	# Apply size multiplier
	visual_node.scale = Vector3.ONE * PlayerStats.shot_size_mult

func _setup_visuals_recursive(node: Node):
	if node is MeshInstance3D:
		var mat = node.material_override if node.material_override else node.mesh.surface_get_material(0)
		if mat is StandardMaterial3D:
			mat = mat.duplicate()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			# mat.albedo_color = Color(2.0, 2.0, 1.0) # Boost brightness
			node.material_override = mat
		elif mat == null:
			var new_mat = StandardMaterial3D.new()
			new_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			node.material_override = new_mat
			
	for child in node.get_children():
		_setup_visuals_recursive(child)
	
	# Collider
	# Approximate box
	var col = CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = Vector3(0.4, 0.4, 0.4) * PlayerStats.shot_size_mult
	add_child(col)

func _on_body_entered(body):
	# damage is calculated in setup()
	
	if body.has_meta("grid_pos"):
		# Hit Voxel
		var grid_pos = body.get_meta("grid_pos")
		
		# Find VoxelWorld
		var world = get_tree().get_first_node_in_group("VoxelWorld")
		if world:
			world.damage_block(grid_pos, damage)
		
		queue_free()
	
	elif body.has_method("take_damage"):
		# Generic Damageable (Enemy, Tree, etc)
		# Pass projectile position as knockback source (so enemies fly away from impact)
		body.take_damage(damage, global_position)
		queue_free()
	
	else:
		# Hit something else (Indestructible wall, etc)
		queue_free()
