class_name VoxelEnemyFactory

const VOXEL_SIZE = 0.05 # Smaller voxels for enemies

static func create_enemy_node(type_name: String) -> Node3D:
	var root = Node3D.new()
	root.name = "Visuals"
	
	var mesh_inst: MeshInstance3D
	
	match type_name:
		"squirrel":
			mesh_inst = _create_squirrel_mesh()
		"snake":
			mesh_inst = _create_snake_mesh()
		"badger":
			mesh_inst = _create_badger_mesh()
		"knight":
			# Complex knight mesh assembly
			return _create_knight_visuals(root)
		_:
			mesh_inst = _create_box_mesh(Color.MAGENTA) # Fallback
			
	if mesh_inst:
		root.add_child(mesh_inst)
		
	return root

static func _create_box_mesh(color: Color) -> MeshInstance3D:
	var m = MeshInstance3D.new()
	m.mesh = BoxMesh.new()
	m.mesh.size = Vector3(0.5, 0.5, 0.5)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	m.material_override = mat
	return m

static func _create_squirrel_mesh() -> MeshInstance3D:
	# Simple composed mesh or just built from voxels. 
	# For simplicity in factory, we return a representative mesh.
	# Ideally we'd use SurfaceTool like VoxelKnight, but for these critters simpler shapes work.
	
	var node = MeshInstance3D.new()
	node.mesh = BoxMesh.new()
	node.mesh.size = Vector3(0.3, 0.3, 0.5) # Body
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.3, 0.1) # Brown
	node.material_override = mat
	
	# Tail (Child)
	var tail = MeshInstance3D.new()
	tail.mesh = BoxMesh.new()
	tail.mesh.size = Vector3(0.15, 0.4, 0.4)
	var t_mat = StandardMaterial3D.new()
	t_mat.albedo_color = Color(0.8, 0.4, 0.1) # Orange/Bushy
	tail.material_override = t_mat
	tail.position = Vector3(0, 0.2, -0.3)
	tail.rotation_degrees.x = 45
	node.add_child(tail)
	
	return node

static func _create_snake_mesh() -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = BoxMesh.new()
	node.mesh.size = Vector3(0.2, 0.15, 0.8) # Long body
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.6, 0.2) # Green
	node.material_override = mat
	
	return node

static func _create_badger_mesh() -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = BoxMesh.new()
	node.mesh.size = Vector3(0.4, 0.3, 0.6) # Sturdy body
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.1) # Black base
	node.material_override = mat
	
	# White Stripe
	var stripe = MeshInstance3D.new()
	stripe.mesh = BoxMesh.new()
	stripe.mesh.size = Vector3(0.15, 0.31, 0.6)
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = Color(0.9, 0.9, 0.9) # White
	stripe.material_override = s_mat
	node.add_child(stripe)
	
	return node

static func _create_knight_visuals(root: Node3D) -> Node3D:
	# We need to replicate VoxelKnightVisuals but with swapped palette.
	# Since VoxelKnightVisuals is a script on a node, maybe we can instantiate a script that behaves similarly but with overridden materials?
	# Or we manually build a simplified one here.
	# Let's try to reuse the VoxelKnightVisuals script logic if possible, or copy-paste relevant parts for the factory.
	# Given the complexity, let's create a specialized "EnemyKnightVisuals.gd" that extends VoxelKnightVisuals or is a copy.
	
	# For now, let's make a simplified blocky knight placeholder until we can dupe the full visual script.
	
	var body = MeshInstance3D.new()
	body.mesh = BoxMesh.new()
	body.mesh.size = Vector3(0.4, 0.6, 0.3)
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.1, 0.1, 0.1) # Dark Grey
	body.material_override = b_mat
	body.position.y = 0.3
	root.add_child(body)
	
	var head = MeshInstance3D.new()
	head.mesh = BoxMesh.new()
	head.mesh.size = Vector3(0.3, 0.3, 0.3)
	var h_mat = StandardMaterial3D.new()
	h_mat.albedo_color = Color(0.1, 0.1, 0.1)
	head.material_override = h_mat
	head.position.y = 0.75
	root.add_child(head)
	
	# Red Plume
	var plume = MeshInstance3D.new()
	plume.mesh = BoxMesh.new()
	plume.mesh.size = Vector3(0.1, 0.15, 0.3)
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color(0.5, 0.0, 0.5) # Purple
	plume.material_override = p_mat
	plume.position.y = 0.95
	root.add_child(plume)
	
	return root
