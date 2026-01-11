class_name VoxelWeaponFactory
extends Node

# Config
const VOXEL_SIZE = 0.025 # Matches VoxelKnightVisuals

# Materials (Shared instance would be better, but re-init for now is fine)
static var materials = {}

static func _init_materials():
	if not materials.is_empty(): return
	
	# Metal / Silver
	var mat_metal = StandardMaterial3D.new()
	mat_metal.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_metal.albedo_color = Color(0.9, 0.9, 0.95)
	materials["metal"] = mat_metal
	
	# Wood / Brown
	var mat_wood = StandardMaterial3D.new()
	mat_wood.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_wood.albedo_color = Color(0.4, 0.25, 0.1)
	materials["wood"] = mat_wood
	
	# Gold
	var mat_gold = StandardMaterial3D.new()
	mat_gold.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_gold.albedo_color = Color(1.0, 0.8, 0.2)
	materials["gold"] = mat_gold

static func create_sword() -> Node3D:
	_init_materials()
	# Design:
	# Blade: 2x16x2? Thin.
	# Hilt: 2x6x2
	# Guard: 6x2x2
	
	var part = _create_part(Vector3i(8, 24, 2), Callable(VoxelWeaponFactory, "_color_sword"))
	
	var pivot = Node3D.new()
	part.position = Vector3(-4, -6, -1) * VOXEL_SIZE # Handle at origin
	pivot.add_child(part)
	return pivot

static func create_axe() -> Node3D:
	_init_materials()
	# Design:
	# Handle: 2x16x2
	# Head: 6x8x2 (Side)
	
	var part = _create_part(Vector3i(8, 16, 2), Callable(VoxelWeaponFactory, "_color_axe"))
	
	var pivot = Node3D.new()
	part.position = Vector3(-4, -6, -1) * VOXEL_SIZE # Handle at origin
	pivot.add_child(part)
	return pivot

# --- Color Functions ---

static func _color_sword(x, y, z, w, h, d) -> Material:
	# Hilt (Bottom 5)
	if y < 5:
		# Pommel (Bottom 1)
		if y == 0: return materials["gold"]
		return materials["wood"]
		
	# Guard (y=5,6)
	if y >= 5 and y <= 6:
		return materials["gold"]
		
	# Blade (y > 6)
	# Center width (w=8) -> Blade width ~3-4
	if x >= 2 and x <= 5:
		return materials["metal"]
	
	return null # Empty air for non-blade parts? 
	# Note: _create_part logic below assumes we return Material or skip if null?
	# Or we design the box size tighter.
	# Here box is 8 wide. Guard needs to be wide. Blade narrow.
	# So we return null (or transparent?) if not part of it.
	# Wait, surface tool needs to know to skip.
	# Let's return null to signify "Air".

static func _color_axe(x, y, z, w, h, d) -> Material:
	# Handle (Center x)
	# w=8. Center=3,4
	if x >= 3 and x <= 4:
		return materials["wood"]
		
	# Axe Head (Top)
	if y >= 10 and y <= 15:
		# Single Bit Axe (One side) or Double?
		# Let's do Double Bit or asymmetrical?
		# Right side (x > 4)
		if x > 4:
			# Curve shape?
			return materials["metal"]
		# Left side (x < 3)
		if x < 3:
			return materials["metal"]
			
	return null

# --- Generator ---

static func _create_part(size: Vector3i, color_func: Callable) -> MeshInstance3D:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for x in range(size.x):
		for y in range(size.y):
			for z in range(size.z):
				var mat = color_func.call(x, y, z, size.x, size.y, size.z)
				if mat == null: continue # Skip air
				
				var color = mat.albedo_color
				_add_voxel_face(st, Vector3(x, y, z), color)
	
	st.generate_normals()
	var mesh = st.commit()
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	
	# Master material logic same as Knight - but UNSHADED for voxel lighting
	var master_mat = StandardMaterial3D.new()
	master_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	master_mat.vertex_color_use_as_albedo = true
	mesh_instance.material_override = master_mat
	
	return mesh_instance

static func _add_voxel_face(st: SurfaceTool, pos: Vector3, color: Color):
	var s = VOXEL_SIZE
	pos *= s
	
	var v = [
		Vector3(0,0,0), Vector3(s,0,0), Vector3(s,0,s), Vector3(0,0,s),
		Vector3(0,s,0), Vector3(s,s,0), Vector3(s,s,s), Vector3(0,s,s)
	]
	for i in range(8): v[i] += pos
	
	st.set_color(color)
	
	# Top
	st.add_vertex(v[7]); st.add_vertex(v[6]); st.add_vertex(v[5])
	st.add_vertex(v[5]); st.add_vertex(v[4]); st.add_vertex(v[7])
	# Bottom
	st.add_vertex(v[0]); st.add_vertex(v[1]); st.add_vertex(v[2])
	st.add_vertex(v[2]); st.add_vertex(v[3]); st.add_vertex(v[0])
	# Front
	st.add_vertex(v[3]); st.add_vertex(v[2]); st.add_vertex(v[6])
	st.add_vertex(v[6]); st.add_vertex(v[7]); st.add_vertex(v[3])
	# Back
	st.add_vertex(v[1]); st.add_vertex(v[0]); st.add_vertex(v[4])
	st.add_vertex(v[4]); st.add_vertex(v[5]); st.add_vertex(v[1])
	# Left
	st.add_vertex(v[0]); st.add_vertex(v[3]); st.add_vertex(v[7])
	st.add_vertex(v[7]); st.add_vertex(v[4]); st.add_vertex(v[0])
	# Right
	st.add_vertex(v[2]); st.add_vertex(v[1]); st.add_vertex(v[5])
	st.add_vertex(v[5]); st.add_vertex(v[6]); st.add_vertex(v[2])
