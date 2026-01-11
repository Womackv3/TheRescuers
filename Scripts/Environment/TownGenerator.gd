# Town Generation Helper Functions
# This is a separate file to keep VoxelWorld.gd cleaner

static func generate_town_layout(world: Node, center_x: int, center_z: int):
	var town_radius = 18 # Increased from 12 for more space
	
	# Clear and flatten area
	for x in range(center_x - town_radius, center_x + town_radius):
		for z in range(center_z - town_radius, center_z + town_radius):
			if x >= 0 and x < world.chunk_size.x and z >= 0 and z < world.chunk_size.z:
				world.clear_column(x, z)
				# Set to flat grass
				world.columns[x][z]["height"] = 1
				world.columns[x][z]["type"] = world.TileType.GRASS
				world.spawn_voxel(x, 0, z, world.TileType.DIRT)
				world.spawn_voxel(x, 1, z, world.TileType.GRASS)
	
	# Build structures with more spacing
	# Center is at (center_x, center_z) - keep it clear!
	# Arrange buildings in a wider circle
	
	# North side
	build_house(world, center_x - 3, center_z - 14, 0)
	
	# South side  
	build_house(world, center_x - 3, center_z + 8, 1)
	
	# West side
	build_shop(world, center_x - 14, center_z - 3)
	
	# East side
	build_blacksmith(world, center_x + 9, center_z - 3)
	
	# North-East (larger building)
	build_town_hall(world, center_x + 8, center_z - 13)
	
	# Center fountain (offset so player doesn't spawn in it)
	build_fountain(world, center_x + 3, center_z + 3)
	
	# Smaller fence perimeter
	build_fence(world, center_x, center_z, town_radius - 2)
	
	# Add decorative clutter
	add_town_decorations(world, center_x, center_z)
	
	print("Town generated at (", center_x, ", ", center_z, ")")

static func build_house(world: Node, start_x: int, start_z: int, variant: int):
	var width = 5  # Reduced from 8
	var depth = 6  # Reduced from 10
	var height = 4 # Reduced from 6
	
	var roof_voxels = [] # Track roof blocks
	
	# Foundation (Cobblestone)
	for x in range(width):
		for z in range(depth):
			world.spawn_voxel(start_x + x, 2, start_z + z, world.TileType.COBBLESTONE)
			world.voxel_map[Vector3i(start_x + x, 2, start_z + z)].set_meta("building_id", "house")
	
	# Walls (Wood Planks)
	for y in range(3, 3 + height - 2):
		# Front and back walls
		for x in range(width):
			# Door opening - 2 blocks tall (y=3 and y=4)
			if (y == 3 or y == 4) and x >= 2 and x <= 4:
				continue
			world.spawn_building_voxel(start_x + x, y, start_z, world.TileType.WOOD_PLANKS, "house")
			world.spawn_building_voxel(start_x + x, y, start_z + depth - 1, world.TileType.WOOD_PLANKS, "house")
		
		# Side walls
		for z in range(1, depth - 1):
			world.spawn_building_voxel(start_x, y, start_z + z, world.TileType.WOOD_PLANKS, "house")
			world.spawn_building_voxel(start_x + width - 1, y, start_z + z, world.TileType.WOOD_PLANKS, "house")
	
	# Roof (Thatch) - Track these!
	var roof_y = 3 + height - 2
	for x in range(-1, width + 1):
		for z in range(-1, depth + 1):
			var roof_voxel = world.spawn_voxel(start_x + x, roof_y, start_z + z, world.TileType.THATCH)
			world.voxel_map[Vector3i(start_x + x, roof_y, start_z + z)].set_meta("building_id", "house")
			roof_voxels.append(roof_voxel)
	
	# Add interior detection zone
	add_interior_zone(world, start_x, start_z, width, depth, roof_voxels, "house")

static func build_shop(world: Node, start_x: int, start_z: int):
	var width = 6  # Reduced from 9
	var depth = 6  # Reduced from 10
	var height = 5 # Reduced from 7
	
	var roof_voxels = [] # Track roof blocks
	
	# Similar to house but with brick accents
	for x in range(width):
		for z in range(depth):
			world.spawn_voxel(start_x + x, 2, start_z + z, world.TileType.COBBLESTONE)
			world.voxel_map[Vector3i(start_x + x, 2, start_z + z)].set_meta("building_id", "shop")
	
	for y in range(3, 3 + height - 2):
		for x in range(width):
			# Door opening - 2 blocks tall
			if (y == 3 or y == 4) and x >= 3 and x <= 5:
				continue
			var mat = world.TileType.WOOD_PLANKS if x % 2 == 0 else world.TileType.BRICK
			world.spawn_building_voxel(start_x + x, y, start_z, mat, "shop")
			world.spawn_building_voxel(start_x + x, y, start_z + depth - 1, mat, "shop")
		
		for z in range(1, depth - 1):
			world.spawn_building_voxel(start_x, y, start_z + z, world.TileType.WOOD_PLANKS, "shop")
			world.spawn_building_voxel(start_x + width - 1, y, start_z + z, world.TileType.WOOD_PLANKS, "shop")
	
	var roof_y = 3 + height - 2
	for x in range(-1, width + 1):
		for z in range(-1, depth + 1):
			var roof_voxel = world.spawn_voxel(start_x + x, roof_y, start_z + z, world.TileType.BRICK)
			world.voxel_map[Vector3i(start_x + x, roof_y, start_z + z)].set_meta("building_id", "shop")
			roof_voxels.append(roof_voxel)
	
	# Add interior detection zone
	add_interior_zone(world, start_x, start_z, width, depth, roof_voxels, "shop")

static func build_blacksmith(world: Node, start_x: int, start_z: int):
	var width = 5  # Reduced from 8
	var depth = 5  # Reduced from 8
	var height = 4 # Reduced from 6
	
	var roof_voxels = [] # Track roof blocks
	
	# All stone structure with roof
	for x in range(width):
		for z in range(depth):
			for y in range(2, 2 + height):
				if y == 2 or x == 0 or x == width - 1 or z == 0 or z == depth - 1:
					# Door opening - 2 blocks tall
					if (y == 3 or y == 4) and z == 0 and x >= 3 and x <= 4:
						continue
					world.spawn_voxel(start_x + x, y, start_z + z, world.TileType.COBBLESTONE)
					world.voxel_map[Vector3i(start_x + x, y, start_z + z)].set_meta("building_id", "blacksmith")
	
	# Roof (top layer of stone)
	var roof_y = 2 + height
	for x in range(width):
		for z in range(depth):
			var roof_voxel = world.spawn_voxel(start_x + x, roof_y, start_z + z, world.TileType.COBBLESTONE)
			world.voxel_map[Vector3i(start_x + x, roof_y, start_z + z)].set_meta("building_id", "blacksmith")
			roof_voxels.append(roof_voxel)
	
	# Chimney (always visible)
	for y in range(roof_y + 1, roof_y + 4):
		world.spawn_voxel(start_x + 1, y, start_z + 1, world.TileType.BRICK)
		world.voxel_map[Vector3i(start_x + 1, y, start_z + 1)].set_meta("building_id", "blacksmith")
	
	# Add interior detection zone
	add_interior_zone(world, start_x, start_z, width, depth, roof_voxels, "blacksmith")

static func build_town_hall(world: Node, start_x: int, start_z: int):
	var width = 8  # Reduced from 12
	var depth = 9  # Reduced from 14
	var height = 6 # Reduced from 8
	
	var roof_voxels = [] # Track roof blocks
	
	# Large stone building
	for x in range(width):
		for z in range(depth):
			world.spawn_voxel(start_x + x, 2, start_z + z, world.TileType.COBBLESTONE)
			world.voxel_map[Vector3i(start_x + x, 2, start_z + z)].set_meta("building_id", "town_hall")
	
	for y in range(3, 3 + height - 2):
		for x in range(width):
			# Door opening - 2 blocks tall
			if (y == 3 or y == 4) and x >= 5 and x <= 6:
				continue
			world.spawn_voxel(start_x + x, y, start_z, world.TileType.BRICK)
			world.spawn_voxel(start_x + x, y, start_z + depth - 1, world.TileType.BRICK)
			world.voxel_map[Vector3i(start_x + x, y, start_z)].set_meta("building_id", "town_hall")
			world.voxel_map[Vector3i(start_x + x, y, start_z + depth - 1)].set_meta("building_id", "town_hall")
		
		for z in range(1, depth - 1):
			world.spawn_voxel(start_x, y, start_z + z, world.TileType.BRICK)
			world.spawn_voxel(start_x + width - 1, y, start_z + z, world.TileType.BRICK)
			world.voxel_map[Vector3i(start_x, y, start_z + z)].set_meta("building_id", "town_hall")
			world.voxel_map[Vector3i(start_x + width - 1, y, start_z + z)].set_meta("building_id", "town_hall")
	
	var roof_y = 3 + height - 2
	for x in range(-1, width + 1):
		for z in range(-1, depth + 1):
			var roof_voxel = world.spawn_voxel(start_x + x, roof_y, start_z + z, world.TileType.WOOD_PLANKS)
			world.voxel_map[Vector3i(start_x + x, roof_y, start_z + z)].set_meta("building_id", "town_hall")
			roof_voxels.append(roof_voxel)
	
	# Add interior detection zone
	add_interior_zone(world, start_x, start_z, width, depth, roof_voxels, "town_hall")

static func build_fountain(world: Node, center_x: int, center_z: int):
	# Use detailed mini-voxel well model
	var well = preload("res://Scripts/Environment/MiniVoxelModel.gd").new()
	well.voxel_world = world
	well.build_detailed_well()
	
	# Position at world coordinates
	well.position = Vector3(center_x * world.block_size, 2 * world.block_size, center_z * world.block_size)
	world.add_child(well)
	print("Built detailed well at (", center_x, ", ", center_z, ")")

static func build_fence(world: Node, center_x: int, center_z: int, radius: int):
	# Simple fence around perimeter
	for angle in range(0, 360, 10):
		var rad = deg_to_rad(angle)
		var x = center_x + int(cos(rad) * radius)
		var z = center_z + int(sin(rad) * radius)
		
		if x >= 0 and x < world.chunk_size.x and z >= 0 and z < world.chunk_size.z:
			world.spawn_voxel(x, 2, z, world.TileType.WOOD)
			world.spawn_voxel(x, 3, z, world.TileType.WOOD)

static func add_interior_zone(world: Node, start_x: int, start_z: int, width: int, depth: int, roof_blocks: Array, building_name: String):
	# Create an Area3D to detect when player enters building
	var interior_zone = Area3D.new()
	interior_zone.set_script(load("res://Scripts/Environment/BuildingInterior.gd"))
	interior_zone.name = building_name + "_Interior"
	
	# Create collision shape for the interior
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(width * world.block_size, 3.0, depth * world.block_size)
	col.shape = box
	
	# Position in center of building, raised up
	var center_x = start_x + width / 2.0
	var center_z = start_z + depth / 2.0
	interior_zone.position = Vector3(center_x * world.block_size, 3.5, center_z * world.block_size)
	
	interior_zone.add_child(col)
	world.add_child(interior_zone)
	
	# Setup the script
	interior_zone.setup(building_name, roof_blocks)

static func add_town_decorations(world: Node, center_x: int, center_z: int):
	# Add decorative clutter to make town feel alive
	
	# Barrels scattered around
	var barrel_positions = [
		Vector2i(center_x - 10, center_z - 5),
		Vector2i(center_x + 6, center_z - 8),
		Vector2i(center_x - 2, center_z + 10),
		Vector2i(center_x + 12, center_z + 5),
		Vector2i(center_x - 8, center_z + 8),
	]
	
	for pos in barrel_positions:
		build_barrel(world, pos.x, pos.y)
	
	# Shop stands (detailed market stalls)
	build_detailed_market_stall(world, center_x - 6, center_z + 2)
	build_detailed_market_stall(world, center_x + 2, center_z - 6)
	
	# Flower patches
	var flower_patches = [
		Vector2i(center_x - 12, center_z + 10),
		Vector2i(center_x + 10, center_z + 10),
		Vector2i(center_x - 5, center_z - 10),
		Vector2i(center_x + 8, center_z - 8),
	]
	
	for patch_center in flower_patches:
		# 3x3 flower patch
		for x_off in range(-1, 2):
			for z_off in range(-1, 2):
				if randf() < 0.7:  # Not every spot has a flower
					world.spawn_voxel(patch_center.x + x_off, 2, patch_center.y + z_off, world.TileType.FLOWER)

static func build_barrel(world: Node, x: int, z: int):
	# Use detailed mini-voxel model
	var barrel = preload("res://Scripts/Environment/MiniVoxelModel.gd").new()
	barrel.voxel_world = world
	barrel.build_detailed_barrel()
	
	# Position at world coordinates (convert grid to world space)
	barrel.position = Vector3(x * world.block_size, 2 * world.block_size, z * world.block_size)
	world.add_child(barrel)

static func build_detailed_market_stall(world: Node, x: int, z: int):
	# Use detailed mini-voxel model
	var stall = preload("res://Scripts/Environment/MiniVoxelModel.gd").new()
	stall.voxel_world = world
	stall.build_detailed_market_stall()
	
	# Position at world coordinates
	stall.position = Vector3(x * world.block_size, 2 * world.block_size, z * world.block_size)
	world.add_child(stall)
