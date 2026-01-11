extends Node3D

@export var chunk_size : Vector3i = Vector3i(64, 5, 64)
@export var block_size : float = 1.0

# Tile types
enum TileType {
	GRASS,
	DESERT,
	WATER,
	WALL,
	PATH,
	DIRT,           # Subsurface layer
	STONE,          # Deep subsurface
	GRASS_TUFT,     # Decoration
	ROCK,           # Decoration
	FLOWER,         # Decoration
	COBBLESTONE     # Path variant
}

# Color palette matching King's Knight reference
var tile_colors = {
	TileType.GRASS: Color(0.2, 0.7, 0.2),           # Bright green
	TileType.DESERT: Color(0.9, 0.5, 0.3),          # Orange/brown
	TileType.WATER: Color(0.2, 0.4, 0.9),           # Blue
	TileType.WALL: Color(0.5, 0.5, 0.5),            # Gray
	TileType.PATH: Color(0.6, 0.5, 0.4),            # Brown path
	TileType.DIRT: Color(1.0, 0.0, 1.0),            # MAGENTA (DEBUG)
	TileType.STONE: Color(0.0, 1.0, 1.0),           # CYAN (DEBUG)
	TileType.GRASS_TUFT: Color(0.1, 0.8, 0.1),      # Bright green
	TileType.ROCK: Color(0.3, 0.2, 0.15),           # Dark brown
	TileType.FLOWER: Color(1.0, 0.3, 0.5),          # Pink (will vary)
	TileType.COBBLESTONE: Color(0.45, 0.45, 0.45)   # Medium gray
}

# Voxel data storage - now 3D for height
var voxel_data : Array = []

# Height map - stores surface height and tile type for each X,Z position
var height_map : Array = []

func _ready():
	generate_terrain()

func generate_terrain():
	# Initialize voxel data
	initialize_voxel_data()
	
	# Generate terrain with height variation
	generate_heightmap()
	
	# Generate mesh with face culling
	generate_mesh()
	
	# Generate collision
	generate_collision()

func initialize_voxel_data():
	voxel_data.clear()
	for x in range(chunk_size.x):
		voxel_data.append([])
		for y in range(chunk_size.y):
			voxel_data[x].append([])
			for z in range(chunk_size.z):
				voxel_data[x][y].append({
					"solid": false,
					"type": TileType.GRASS
				})

func set_voxel(x: int, y: int, z: int, solid: bool, tile_type: int = TileType.GRASS):
	if x >= 0 and x < chunk_size.x and y >= 0 and y < chunk_size.y and z >= 0 and z < chunk_size.z:
		voxel_data[x][y][z]["solid"] = solid
		voxel_data[x][y][z]["type"] = tile_type

func get_voxel(x: int, y: int, z: int) -> bool:
	if x < 0 or x >= chunk_size.x or y < 0 or y >= chunk_size.y or z < 0 or z >= chunk_size.z:
		return false
	return voxel_data[x][y][z]["solid"]

func get_voxel_type(x: int, y: int, z: int) -> int:
	if x < 0 or x >= chunk_size.x or y < 0 or y >= chunk_size.y or z < 0 or z >= chunk_size.z:
		return TileType.GRASS
	return voxel_data[x][y][z]["type"]

func generate_heightmap():
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.08
	
	# Temporary tile type map (2D)
	var tile_types : Array = []
	for x in range(chunk_size.x):
		tile_types.append([])
		for z in range(chunk_size.z):
			tile_types[x].append(TileType.GRASS)
	
	# Initial noise-based generation
	for x in range(chunk_size.x):
		for z in range(chunk_size.z):
			var noise_val = noise.get_noise_2d(x, z)
			
			if noise_val < -0.3:
				tile_types[x][z] = TileType.WATER
			elif noise_val < 0.0:
				tile_types[x][z] = TileType.GRASS
			elif noise_val < 0.4:
				tile_types[x][z] = TileType.DESERT
			else:
				tile_types[x][z] = TileType.GRASS
	
	# Smooth biomes using cellular automata (3 passes)
	for pass_num in range(3):
		var new_tile_types : Array = []
		for x in range(chunk_size.x):
			new_tile_types.append([])
			for z in range(chunk_size.z):
				new_tile_types[x].append(tile_types[x][z])
		
		for x in range(1, chunk_size.x - 1):
			for z in range(1, chunk_size.z - 1):
				# Count neighbor types
				var neighbor_counts = {
					TileType.GRASS: 0,
					TileType.DESERT: 0,
					TileType.WATER: 0
				}
				
				# Check 8 neighbors
				for dx in range(-1, 2):
					for dz in range(-1, 2):
						if dx == 0 and dz == 0:
							continue
						var nx = x + dx
						var nz = z + dz
						if nx >= 0 and nx < chunk_size.x and nz >= 0 and nz < chunk_size.z:
							var neighbor_type = tile_types[nx][nz]
							if neighbor_type in neighbor_counts:
								neighbor_counts[neighbor_type] += 1
				
				# Find most common neighbor type
				var max_count = 0
				var most_common = tile_types[x][z]
				for tile_type in neighbor_counts:
					if neighbor_counts[tile_type] > max_count:
						max_count = neighbor_counts[tile_type]
						most_common = tile_type
				
				# If 5+ neighbors are same type, convert to that type
				if max_count >= 5:
					new_tile_types[x][z] = most_common
		
		tile_types = new_tile_types
	
	# Initialize height map
	height_map.clear()
	for x in range(chunk_size.x):
		height_map.append([])
		for z in range(chunk_size.z):
			height_map[x].append({"height": 0, "type": TileType.GRASS})
	
	# Apply smoothed tile types to voxel data with layering
	for x in range(chunk_size.x):
		for z in range(chunk_size.z):
			var tile_type = tile_types[x][z]
			var height = 1  # Default height
			
			# Set height based on tile type
			if tile_type == TileType.WATER:
				height = 0
			elif tile_type == TileType.GRASS:
				height = 1
			elif tile_type == TileType.DESERT:
				height = 2
			
			# Store in height map
			height_map[x][z] = {"height": height, "type": tile_type}
			
			# Fill column with layered blocks
			for y in range(height + 1):
				var layer_type = tile_type
				
				# Add subsurface layers
				if y < height:  # Not the top layer
					if tile_type == TileType.GRASS:
						layer_type = TileType.DIRT
					elif tile_type == TileType.DESERT:
						layer_type = TileType.DIRT if y == height - 1 else TileType.STONE
					elif tile_type == TileType.WATER:
						layer_type = TileType.STONE
				
				set_voxel(x, y, z, true, layer_type)
	
	# Add raised castle platforms and update height map
	add_raised_platform(10, 10, 15, 15, 3, TileType.WALL)
	add_raised_platform(40, 30, 10, 12, 2, TileType.WALL)

func add_raised_platform(start_x: int, start_z: int, width: int, depth: int, height: int, tile_type: int):
	for x in range(start_x, start_x + width):
		for z in range(start_z, start_z + depth):
			if x >= 0 and x < chunk_size.x and z >= 0 and z < chunk_size.z:
				# Update height map
				height_map[x][z] = {"height": height, "type": tile_type}
				
				for y in range(height + 1):
					if y < chunk_size.y:
						set_voxel(x, y, z, true, tile_type)

func generate_mesh():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create single material with vertex colors enabled
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	st.set_material(mat)
	
	# Pre-calculate surface tile type for each column by scanning actual voxel data
	var surface_types : Array = []
	for x in range(chunk_size.x):
		surface_types.append([])
		for z in range(chunk_size.z):
			var surface_type = TileType.GRASS  # Default fallback
			
			# Scan from top down to find the highest solid voxel
			var found_surface = false
			for y in range(chunk_size.y - 1, -1, -1):
				if get_voxel(x, y, z):
					surface_type = get_voxel_type(x, y, z)
					found_surface = true
					break
			
			if not found_surface:
				# If column is empty, type doesn't matter (won't be drawn)
				surface_type = TileType.GRASS
				
			surface_types[x].append(surface_type)
	
	# Generate voxels with face culling
	for x in range(chunk_size.x):
		for y in range(chunk_size.y):
			for z in range(chunk_size.z):
				if get_voxel(x, y, z):
					var pos = Vector3(x, y, z) * block_size
					
					# Use scanned surface color for this column
					var surface_tile_type = surface_types[x][z]
					var color = tile_colors.get(surface_tile_type, Color.MAGENTA) # Safety fallback
					
					# Force bright colors for DIRT/STONE if they somehow end up on top (debug)
					if surface_tile_type == TileType.DIRT:
						color = tile_colors[TileType.GRASS] # Fallback to grass
					elif surface_tile_type == TileType.STONE:
						color = tile_colors[TileType.WALL] # Fallback to wall

					add_voxel_with_culling(st, pos, x, y, z, color)
	
	st.generate_normals()
	var mesh = st.commit()
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	add_child(mesh_instance)

func add_voxel_with_culling(st: SurfaceTool, pos: Vector3, x: int, y: int, z: int, color: Color):
	var s = block_size
	
	# Top Face (+Y) - Add texture details
	if not get_voxel(x, y + 1, z):
		add_textured_face(st, pos, x, y, z, color, "top")
	
	# Bottom Face (-Y)
	if not get_voxel(x, y - 1, z):
		var dark_color = Color(color.r * 0.7, color.g * 0.7, color.b * 0.7, 1.0)
		st.set_color(dark_color)
		st.add_vertex(pos + Vector3(0, 0, 0))
		st.add_vertex(pos + Vector3(s, 0, s))
		st.add_vertex(pos + Vector3(s, 0, 0))
		st.add_vertex(pos + Vector3(0, 0, 0))
		st.add_vertex(pos + Vector3(0, 0, s))
		st.add_vertex(pos + Vector3(s, 0, s))
	
	# Front Face (+Z)
	if not get_voxel(x, y, z + 1):
		var dark_color = Color(color.r * 0.9, color.g * 0.9, color.b * 0.9, 1.0)
		st.set_color(dark_color)
		st.add_vertex(pos + Vector3(0, 0, s))
		st.add_vertex(pos + Vector3(s, 0, s))
		st.add_vertex(pos + Vector3(s, s, s))
		st.add_vertex(pos + Vector3(0, 0, s))
		st.add_vertex(pos + Vector3(s, s, s))
		st.add_vertex(pos + Vector3(0, s, s))
	
	# Back Face (-Z)
	if not get_voxel(x, y, z - 1):
		var dark_color = Color(color.r * 0.9, color.g * 0.9, color.b * 0.9, 1.0)
		st.set_color(dark_color)
		st.add_vertex(pos + Vector3(s, 0, 0))
		st.add_vertex(pos + Vector3(0, 0, 0))
		st.add_vertex(pos + Vector3(0, s, 0))
		st.add_vertex(pos + Vector3(s, 0, 0))
		st.add_vertex(pos + Vector3(0, s, 0))
		st.add_vertex(pos + Vector3(s, s, 0))
	
	# Right Face (+X)
	if not get_voxel(x + 1, y, z):
		var dark_color = Color(color.r * 0.8, color.g * 0.8, color.b * 0.8, 1.0)
		st.set_color(dark_color)
		st.add_vertex(pos + Vector3(s, 0, s))
		st.add_vertex(pos + Vector3(s, 0, 0))
		st.add_vertex(pos + Vector3(s, s, 0))
		st.add_vertex(pos + Vector3(s, 0, s))
		st.add_vertex(pos + Vector3(s, s, 0))
		st.add_vertex(pos + Vector3(s, s, s))
	
	# Left Face (-X)
	if not get_voxel(x - 1, y, z):
		var dark_color = Color(color.r * 0.8, color.g * 0.8, color.b * 0.8, 1.0)
		st.set_color(dark_color)
		st.add_vertex(pos + Vector3(0, 0, 0))
		st.add_vertex(pos + Vector3(0, 0, s))
		st.add_vertex(pos + Vector3(0, s, s))
		st.add_vertex(pos + Vector3(0, 0, 0))
		st.add_vertex(pos + Vector3(0, s, s))
		st.add_vertex(pos + Vector3(0, s, 0))

# Add textured face with sub-voxel details
func add_textured_face(st: SurfaceTool, pos: Vector3, x: int, y: int, z: int, color: Color, face: String):
	var s = block_size
	var detail_size = 6  # 6x6 grid of potential texture details
	var speckle_size = s / (detail_size * 2.0)  # Small speckles
	
	# Create noise for texture pattern
	var texture_seed = x * 1000 + y * 100 + z
	
	# First, render the base face
	match face:
		"top":
			st.set_color(color)
			st.add_vertex(pos + Vector3(0, s, 0))
			st.add_vertex(pos + Vector3(s, s, 0))
			st.add_vertex(pos + Vector3(s, s, s))
			st.add_vertex(pos + Vector3(0, s, 0))
			st.add_vertex(pos + Vector3(s, s, s))
			st.add_vertex(pos + Vector3(0, s, s))
			
			# Add texture speckles on top - different patterns per tile type
			var tile_type = get_voxel_type(x, y, z)
			
			for i in range(detail_size):
				for j in range(detail_size):
					var hash_val = (texture_seed + i * 7 + j * 13) % 100
					var should_add_speckle = false
					var speckle_color = color
					
					# Different texture patterns for different tiles
					if tile_type == TileType.WATER:
						# White flow lines/ripples (horizontal lines)
						if i % 2 == 0 and hash_val < 30:  # Horizontal ripple pattern
							should_add_speckle = true
							speckle_color = Color(0.8, 0.9, 1.0)  # Light blue/white
					elif tile_type == TileType.GRASS:
						# Dark green speckles
						if hash_val < 25:
							should_add_speckle = true
							speckle_color = color * 0.7  # Darker
					elif tile_type == TileType.DIRT:
						# Brown variation
						if hash_val < 30:
							should_add_speckle = true
							speckle_color = color * 0.8  # Slightly darker
					elif tile_type == TileType.DESERT:
						# Light sand variation
						if hash_val < 20:
							should_add_speckle = true
							speckle_color = color * 1.1  # Slightly lighter
					elif tile_type == TileType.WALL:
						# Gray cobblestone pattern
						if hash_val < 35:
							should_add_speckle = true
							speckle_color = color * 0.85  # Darker gray
					
					if should_add_speckle:
						var offset_x = (i + 0.5) * (s / detail_size)
						var offset_z = (j + 0.5) * (s / detail_size)
						# Offset slightly above surface to prevent Z-fighting
						add_small_cube(st, pos + Vector3(offset_x, s + 0.001, offset_z), speckle_size, speckle_color)
		
		"front":
			st.set_color(color)
			st.add_vertex(pos + Vector3(0, 0, s))
			st.add_vertex(pos + Vector3(s, 0, s))
			st.add_vertex(pos + Vector3(s, s, s))
			st.add_vertex(pos + Vector3(0, 0, s))
			st.add_vertex(pos + Vector3(s, s, s))
			st.add_vertex(pos + Vector3(0, s, s))
		
		"back":
			st.set_color(color)
			st.add_vertex(pos + Vector3(s, 0, 0))
			st.add_vertex(pos + Vector3(0, 0, 0))
			st.add_vertex(pos + Vector3(0, s, 0))
			st.add_vertex(pos + Vector3(s, 0, 0))
			st.add_vertex(pos + Vector3(0, s, 0))
			st.add_vertex(pos + Vector3(s, s, 0))
		
		"right":
			st.set_color(color)
			st.add_vertex(pos + Vector3(s, 0, s))
			st.add_vertex(pos + Vector3(s, 0, 0))
			st.add_vertex(pos + Vector3(s, s, 0))
			st.add_vertex(pos + Vector3(s, 0, s))
			st.add_vertex(pos + Vector3(s, s, 0))
			st.add_vertex(pos + Vector3(s, s, s))
		
		"left":
			st.set_color(color)
			st.add_vertex(pos + Vector3(0, 0, 0))
			st.add_vertex(pos + Vector3(0, 0, s))
			st.add_vertex(pos + Vector3(0, s, s))
			st.add_vertex(pos + Vector3(0, 0, 0))
			st.add_vertex(pos + Vector3(0, s, s))
			st.add_vertex(pos + Vector3(0, s, 0))

# Add small cube for texture detail
func add_small_cube(st: SurfaceTool, pos: Vector3, size: float, color: Color):
	st.set_color(color)
	var s = size
	
	# Just add top face for speckle
	st.add_vertex(pos + Vector3(-s/2, 0, -s/2))
	st.add_vertex(pos + Vector3(s/2, 0, -s/2))
	st.add_vertex(pos + Vector3(s/2, 0, s/2))
	st.add_vertex(pos + Vector3(-s/2, 0, -s/2))
	st.add_vertex(pos + Vector3(s/2, 0, s/2))
	st.add_vertex(pos + Vector3(-s/2, 0, s/2))

func generate_collision():
	var static_body = StaticBody3D.new()
	static_body.name = "TerrainCollision"
	add_child(static_body)
	
	# Create box colliders for solid voxels (simplified - one per column)
	for x in range(chunk_size.x):
		for z in range(chunk_size.z):
			var max_height = 0
			for y in range(chunk_size.y):
				if get_voxel(x, y, z):
					max_height = y + 1
			
			if max_height > 0:
				var col_shape = CollisionShape3D.new()
				var box = BoxShape3D.new()
				box.size = Vector3(block_size, max_height * block_size, block_size)
				col_shape.shape = box
				col_shape.position = Vector3(
					x * block_size + block_size * 0.5,
					(max_height * block_size) * 0.5,
					z * block_size + block_size * 0.5
				)
				static_body.add_child(col_shape)
