extends StaticBody3D
class_name MiniVoxelModel

# Mini-voxel system for detailed decoration models
# Uses 0.1 unit voxels for 10x more detail than terrain

const MINI_VOXEL_SIZE = 0.1
const GRID_SIZE = 100  # Increased for larger buildings

# Store mini-voxels as a 3D dictionary
var mini_voxels = {}  # Vector3i -> TileType

# Reference to VoxelWorld for materials
var voxel_world: Node = null

func add_mini_voxel(x: int, y: int, z: int, tile_type: int):
	"""Add a mini-voxel to the model"""
	if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE or z < 0 or z >= GRID_SIZE:
		return
	
	mini_voxels[Vector3i(x, y, z)] = tile_type

func generate_mesh():
	"""Generate optimized mesh from mini-voxels"""
	if mini_voxels.size() == 0:
		print("MiniVoxelModel: No voxels to generate!")
		return
	
	print("MiniVoxelModel: Generating mesh with ", mini_voxels.size(), " voxels")
	
	# Group voxels by material type for multi-material support
	var voxels_by_type = {}
	for pos in mini_voxels:
		var tile_type = mini_voxels[pos]
		if not voxels_by_type.has(tile_type):
			voxels_by_type[tile_type] = []
		voxels_by_type[tile_type].append(pos)
	
	# Create separate mesh for each material type
	for tile_type in voxels_by_type:
		var surface_tool = SurfaceTool.new()
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		var positions = voxels_by_type[tile_type]
		for pos in positions:
			_add_voxel_faces(surface_tool, pos, tile_type)
		
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = surface_tool.commit()
		
		# Apply correct material
		if voxel_world and voxel_world.materials.has(tile_type):
			mesh_instance.material_override = voxel_world.materials[tile_type]
			print("MiniVoxelModel: Applied material for type ", tile_type)
		
		add_child(mesh_instance)
	
	# Add collision
	var col_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	var min_pos = Vector3(999, 999, 999)
	var max_pos = Vector3(-999, -999, -999)
	for pos in mini_voxels:
		var world_pos = Vector3(pos) * MINI_VOXEL_SIZE
		min_pos = min_pos.min(world_pos)
		max_pos = max_pos.max(world_pos + Vector3.ONE * MINI_VOXEL_SIZE)
	
	var size = max_pos - min_pos
	var center = (min_pos + max_pos) / 2.0
	box.size = size
	col_shape.shape = box
	col_shape.position = center
	add_child(col_shape)
	
	print("MiniVoxelModel: Mesh generated successfully!")

func _add_voxel_faces(surface_tool: SurfaceTool, pos: Vector3i, tile_type: int):
	"""Add faces for a single mini-voxel with culling"""
	var world_pos = Vector3(pos) * MINI_VOXEL_SIZE
	var size = MINI_VOXEL_SIZE
	
	var color = Color.WHITE
	if voxel_world and voxel_world.tile_colors.has(tile_type):
		color = voxel_world.tile_colors[tile_type]
	
	var faces = [
		{"dir": Vector3i(0, 1, 0), "normal": Vector3(0, 1, 0), "verts": _get_top_face(world_pos, size)},
		{"dir": Vector3i(0, -1, 0), "normal": Vector3(0, -1, 0), "verts": _get_bottom_face(world_pos, size)},
		{"dir": Vector3i(1, 0, 0), "normal": Vector3(1, 0, 0), "verts": _get_right_face(world_pos, size)},
		{"dir": Vector3i(-1, 0, 0), "normal": Vector3(-1, 0, 0), "verts": _get_left_face(world_pos, size)},
		{"dir": Vector3i(0, 0, 1), "normal": Vector3(0, 0, 1), "verts": _get_front_face(world_pos, size)},
		{"dir": Vector3i(0, 0, -1), "normal": Vector3(0, 0, -1), "verts": _get_back_face(world_pos, size)},
	]
	
	for face in faces:
		var neighbor_pos = pos + face.dir
		# Only render face if neighbor is empty or different material (culling)
		if not mini_voxels.has(neighbor_pos) or mini_voxels[neighbor_pos] != tile_type:
			for vert in face.verts:
				surface_tool.set_color(color)
				surface_tool.set_normal(face.normal)
				surface_tool.add_vertex(vert)

# Face helpers
func _get_top_face(pos: Vector3, size: float) -> Array:
	return [pos + Vector3(0, size, 0), pos + Vector3(size, size, 0), pos + Vector3(size, size, size),
			pos + Vector3(0, size, 0), pos + Vector3(size, size, size), pos + Vector3(0, size, size)]

func _get_bottom_face(pos: Vector3, size: float) -> Array:
	return [pos + Vector3(0, 0, size), pos + Vector3(size, 0, size), pos + Vector3(size, 0, 0),
			pos + Vector3(0, 0, size), pos + Vector3(size, 0, 0), pos + Vector3(0, 0, 0)]

func _get_right_face(pos: Vector3, size: float) -> Array:
	return [pos + Vector3(size, 0, 0), pos + Vector3(size, size, 0), pos + Vector3(size, size, size),
			pos + Vector3(size, 0, 0), pos + Vector3(size, size, size), pos + Vector3(size, 0, size)]

func _get_left_face(pos: Vector3, size: float) -> Array:
	return [pos + Vector3(0, 0, size), pos + Vector3(0, size, size), pos + Vector3(0, size, 0),
			pos + Vector3(0, 0, size), pos + Vector3(0, size, 0), pos + Vector3(0, 0, 0)]

func _get_front_face(pos: Vector3, size: float) -> Array:
	return [pos + Vector3(0, 0, size), pos + Vector3(size, 0, size), pos + Vector3(size, size, size),
			pos + Vector3(0, 0, size), pos + Vector3(size, size, size), pos + Vector3(0, size, size)]

func _get_back_face(pos: Vector3, size: float) -> Array:
	return [pos + Vector3(size, 0, 0), pos + Vector3(0, 0, 0), pos + Vector3(0, size, 0),
			pos + Vector3(size, 0, 0), pos + Vector3(0, size, 0), pos + Vector3(size, size, 0)]

# Building templates
func build_detailed_barrel():
	var TileType = voxel_world.TileType if voxel_world else null
	if not TileType: return
	
	var center = 5
	for h in [0, 1, 8, 9]:
		for x in range(3, 8):
			for z in range(3, 8):
				if Vector2(x - center, z - center).length() < 2.5:
					add_mini_voxel(x, h, z, TileType.WOOD)
	
	for h in range(2, 8):
		for x in range(2, 9):
			for z in range(2, 9):
				var dist = Vector2(x - center, z - center).length()
				var max_radius = 3.5 if h in [4, 5] else 3.0
				if dist < max_radius:
					add_mini_voxel(x, h, z, TileType.WOOD)
	
	for h in [3, 6]:
		for x in range(2, 9):
			for z in range(2, 9):
				var dist = Vector2(x - center, z - center).length()
				if dist >= 2.5 and dist < 3.5:
					add_mini_voxel(x, h, z, TileType.COBBLESTONE)
	
	generate_mesh()

func build_detailed_market_stall():
	var TileType = voxel_world.TileType if voxel_world else null
	if not TileType: return
	
	for x in range(30):
		for z in range(20):
			add_mini_voxel(x, 0, z, TileType.WOOD_PLANKS)
			add_mini_voxel(x, 1, z, TileType.WOOD_PLANKS)
	
	for h in range(2, 15):
		for post in [[0, 0], [29, 0], [0, 19], [29, 19]]:
			add_mini_voxel(post[0], h, post[1], TileType.WOOD)
			if post[0] > 0: add_mini_voxel(post[0] - 1, h, post[1], TileType.WOOD)
			if post[1] > 0: add_mini_voxel(post[0], h, post[1] - 1, TileType.WOOD)
	
	for x in range(30):
		for z in range(20):
			if (x + z) % 2 == 0:
				add_mini_voxel(x, 15, z, TileType.WOOD_PLANKS)
			else:
				add_mini_voxel(x, 15, z, TileType.WOOD)
	
	for crate_x in [5, 15, 24]:
		for cx in range(3):
			for cz in range(3):
				for cy in range(3):
					add_mini_voxel(crate_x + cx, 2 + cy, 8 + cz, TileType.WOOD)
	
	generate_mesh()

func build_detailed_house(width_blocks: int = 5, depth_blocks: int = 6):
	var TileType = voxel_world.TileType if voxel_world else null
	if not TileType: return
	
	var width = width_blocks * 10
	var depth = depth_blocks * 10
	var wall_height = 40
	
	# Thin walls
	for h in range(wall_height):
		for x in range(width):
			add_mini_voxel(x, h, 0, TileType.BRICK)
			add_mini_voxel(x, h, 1, TileType.BRICK)
			add_mini_voxel(x, h, depth - 2, TileType.BRICK)
			add_mini_voxel(x, h, depth - 1, TileType.BRICK)
		for z in range(depth):
			add_mini_voxel(0, h, z, TileType.BRICK)
			add_mini_voxel(1, h, z, TileType.BRICK)
			add_mini_voxel(width - 2, h, z, TileType.BRICK)
			add_mini_voxel(width - 1, h, z, TileType.BRICK)
	
	# Sloped roof
	var roof_peak = wall_height + (width / 2)
	for z in range(depth):
		for x in range(width):
			var dist_from_center = abs(x - width / 2)
			var roof_y = roof_peak - dist_from_center
			if roof_y > wall_height:
				for y in range(int(wall_height), int(roof_y)):
					add_mini_voxel(x, y, z, TileType.WOOD)
	
	generate_mesh()

func build_detailed_well():
	var TileType = voxel_world.TileType if voxel_world else null
	if not TileType: return
	
	var center = 15
	for h in range(8):
		for x in range(30):
			for z in range(30):
				var dist = Vector2(x - center, z - center).length()
				if dist >= 10 and dist < 12:
					add_mini_voxel(x, h, z, TileType.COBBLESTONE)
	
	for x in range(30):
		for z in range(30):
			var dist = Vector2(x - center, z - center).length()
			if dist < 10:
				add_mini_voxel(x, 0, z, TileType.WATER)
				add_mini_voxel(x, 1, z, TileType.WATER)
	
	generate_mesh()
