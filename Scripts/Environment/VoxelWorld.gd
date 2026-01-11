extends Node3D

@export var chunk_size : Vector3i = Vector3i(64, 5, 64) # Flat world height
@export var block_size : float = 1.0

# ... (TileType enum unchanged)

# Terrain data
var columns = []
var voxel_map = {} # Vector3i -> MeshInstance3D

# Noise Generators
var height_noise: FastNoiseLite
var cave_noise: FastNoiseLite
enum TileType {
	GRASS,
	DESERT,
	WATER,
	WALL,
	DIRT,
	STONE,
	FLOWER,
	GRASS_TUFT,
	CACTUS,
	SAND_PEBBLE,
	WOOD,
	LEAVES,
	LEAVES_LIGHT,
	LEAVES_DARK,
	WOOD_PLANKS,
	COBBLESTONE,
	THATCH,
	BRICK
}

# Color palette (Brightened for visibility)
var tile_colors = {
	TileType.GRASS: Color(0.2, 0.7, 0.2),       # Bright Green
	TileType.DESERT: Color(0.9, 0.6, 0.3),      # Bright Sand
	TileType.WATER: Color(0.2, 0.4, 0.9),       # Bright Blue
	TileType.WALL: Color(0.6, 0.6, 0.6),        # Light Gray
	TileType.DIRT: Color(0.4, 0.25, 0.1),       # Brown
	TileType.STONE: Color(0.5, 0.5, 0.5),       # Gray
	TileType.FLOWER: Color(0.9, 0.3, 0.4),      # Pink/Red
	TileType.GRASS_TUFT: Color(0.2, 0.8, 0.2),  # Bright Green
	TileType.CACTUS: Color(0.1, 0.6, 0.1),      # Green
	TileType.SAND_PEBBLE: Color(0.7, 0.5, 0.3), # Sand
	TileType.WOOD: Color(0.4, 0.25, 0.1),       # Wood
	TileType.LEAVES: Color(0.1, 0.6, 0.1),      # Green
	TileType.LEAVES_LIGHT: Color(0.3, 0.8, 0.3), # Light Green
	TileType.LEAVES_DARK: Color(0.1, 0.4, 0.1),  # Dark Green
	TileType.WOOD_PLANKS: Color(0.6, 0.4, 0.2),  # Wood Planks
	TileType.COBBLESTONE: Color(0.4, 0.4, 0.45), # Cobblestone
	TileType.THATCH: Color(0.8, 0.7, 0.4),       # Thatch
	TileType.BRICK: Color(0.5, 0.5, 0.52)        # Grey Stone Brick
}

# Materials (cached for performance)
var materials = {}

# Container for all voxel nodes
var voxel_container : Node3D


# Lighting Data
var light_map = {} # Vector3i -> int (0-15)
var sunlight_map = {} # Vector3i -> int (0-15) for day/night cycle
var light_update_queue = [] # Array of Vector3i to process

func _ready():
	add_to_group("VoxelWorld")
	_init_materials()
	
	voxel_container = Node3D.new()
	voxel_container.name = "VoxelContainer"
	add_child(voxel_container)
	
	# Add DirectionalLight3D for DARK DUSK
	var sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = 1.0 # Brighter sun
	sun.light_color = Color(1.0, 0.7, 0.5) # Brighter orange/white
	sun.rotation_degrees = Vector3(-25, 35, 0) # Slightly higher sun
	
	# Shadow settings - STRONG and dramatic
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.75 # Softer shadows
	sun.shadow_blur = 1.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 50.0
	add_child(sun)
	
	# Add WorldEnvironment for dark dusk
	var world_env = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	
	var environment = Environment.new()
	
	# Minimal fog - just for atmosphere, not haze
	environment.volumetric_fog_enabled = true
	environment.volumetric_fog_density = 0.002 # Less fog (was 0.005)
	environment.volumetric_fog_albedo = Color(0.6, 0.5, 0.7) # Brighter fog
	environment.volumetric_fog_emission_energy = 0.1
	environment.volumetric_fog_gi_inject = 0.5
	environment.volumetric_fog_anisotropy = 0.4
	environment.volumetric_fog_length = 48.0
	
	# Ambient light - brighter
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.4, 0.35, 0.5) # Brighter purple ambient
	environment.ambient_light_energy = 0.6 # Brighter ambient (Was 0.3)
	
	# Minimal adjustments - let shadows do the work
	environment.adjustment_enabled = true
	environment.adjustment_brightness = 1.1 # Brighter overall
	environment.adjustment_contrast = 1.1 # Slightly less contrast
	environment.adjustment_saturation = 1.1 # More saturation
	
	# Tone mapping for dark, contrasty look
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.1 # Brighter exposure (Was 0.85)
	
	# Dark dusk sky
	var sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	
	# Dark twilight colors
	sky_material.sky_top_color = Color(0.15, 0.1, 0.25) # Very dark purple sky
	sky_material.sky_horizon_color = Color(0.5, 0.3, 0.4) # Muted purple/orange horizon
	sky_material.ground_bottom_color = Color(0.05, 0.05, 0.08) # Nearly black ground
	sky_material.ground_horizon_color = Color(0.2, 0.15, 0.2) # Dark purple ground
	
	# Small sunset sun
	sky_material.sun_angle_max = 10.0
	sky_material.sun_curve = 0.15
	
	sky.sky_material = sky_material
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	
	world_env.environment = environment
	add_child(world_env)
	
	world_env.environment = environment
	add_child(world_env)
	
	_init_noise()
	generate_terrain()

func _init_noise():
	# 1. Height Map Noise (Mountains)
	height_noise = FastNoiseLite.new()
	height_noise.seed = randi()
	height_noise.frequency = 0.01 # Lower frequency for larger mountains
	height_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	height_noise.fractal_octaves = 5
	
	# 2. Cave Noise (3D Worms/Swiss Cheese)
	cave_noise = FastNoiseLite.new()
	cave_noise.seed = randi()
	cave_noise.frequency = 0.05
	cave_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED # Good for tunnels
	cave_noise.fractal_octaves = 2



func generate_terrain():
	print("Generating 3D Voxel Terrain...")
	
	# Clear existing
	for child in voxel_container.get_children():
		child.queue_free()
	voxel_map.clear()
	columns.clear()
	
	# 2-Pass Generation for Culling
	# Pass 1: Data Calculation
	var grid_data = {} # Vector3i -> int (TileType)
	
	for x in range(chunk_size.x):
		columns.append([])
		for z in range(chunk_size.z):
			# Simple 2D noise for basic terrain
			var noise_val = height_noise.get_noise_2d(x, z)
			var type = TileType.GRASS
			var height = 1
			
			# Town area - force flat
			var town_center_x = 32
			var town_center_z = 32
			var town_radius = 20
			var dist_to_town = sqrt(pow(x - town_center_x, 2) + pow(z - town_center_z, 2))
			
			if dist_to_town < town_radius:
				# Town area - flat grass
				type = TileType.GRASS
				height = 1
			elif noise_val < -0.3:
				# Water areas
				type = TileType.WATER
				height = 0
			elif noise_val < 0.0:
				# Grass (slightly elevated)
				type = TileType.GRASS
				height = 1
			elif noise_val < 0.4:
				# Desert
				type = TileType.DESERT
				height = 2
			else:
				# Higher grass
				type = TileType.GRASS
				height = 2
			
			columns[x].append({"height": height, "type": type})
			
			# Fill column from bottom to surface
			for y in range(height + 1):
				var block_type = type
				
				# Subsurface logic
				if y < height:
					if type == TileType.GRASS or type == TileType.DESERT:
						block_type = TileType.DIRT
					elif type == TileType.WATER:
						block_type = TileType.STONE
				
				grid_data[Vector3i(x, y, z)] = block_type

	# Pass 2: Spawning (with Culling)
	for pos_key in grid_data:
		var x = pos_key.x
		var y = pos_key.y
		var z = pos_key.z
		var type = grid_data[pos_key]
		
		# Check Neighbors (Up, Down, Left, Right, Forward, Back)
		var is_visible = false
		var directions = [Vector3i.UP, Vector3i.DOWN, Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]
		
		for d in directions:
			var neighbor = pos_key + d
			if not grid_data.has(neighbor):
				is_visible = true
				break
		
		if is_visible:
			var voxel = spawn_voxel(x, y, z, type)
			
			# Decoration (Top only)
			if not grid_data.has(pos_key + Vector3i.UP):
				decorate_voxel(voxel, type, x, z)
				
				# Water surface effect
				if type == TileType.WATER:
					_spawn_water_surface(x, y, z)
	
	# Generate Town FIRST (before platforms/decorations)
	if has_method("generate_town"):
		generate_town(32, 32)
	
	# Build castles
	build_castle(10, 10, 15, 15, 3)
	build_castle(40, 30, 10, 12, 2)
	
	# Generate Forest Border
	print("Generating Forest Border...")
	var border_depth = 3
	for x in range(chunk_size.x):
		for z in range(chunk_size.z):
			# Check if in border zone
			if x < border_depth or x >= chunk_size.x - border_depth or z < border_depth or z >= chunk_size.z - border_depth:
				# Determine ground height
				var h = columns[x][z]["height"]
				var y = h + 1
				
				# Spawn
				if (x + z) % 2 == 0:
					# Let's do EVERY block for the outermost layer, then sparse inner
					var is_outer = (x == 0 or x == chunk_size.x - 1 or z == 0 or z == chunk_size.z - 1)
					if is_outer or randf() < 0.7:
						_create_border_tree(x, y, z)
	
	print("--- TRIED SPAWNING ENEMIES START ---")
	for i in range(15): # Spawn 15 random critters
		var rx = randf_range(5, chunk_size.x - 5)
		var rz = randf_range(5, chunk_size.z - 5)
		var spawn_pos = Vector3(rx * block_size, 10, rz * block_size) # Start high
		
		# Raycast down to find ground or simple y check if we had height map
		# Since we don't have easy height access here without looking up columns:
		var ix = int(rx)
		var iz = int(rz)
		if ix >= 0 and ix < chunk_size.x and iz >= 0 and iz < chunk_size.z:
			var h = columns[ix][iz]["height"]
			spawn_pos.y = (h + 1) * block_size
			
			# Decide type
			var type = "squirrel"
			if randf() < 0.3: type = "snake"
			if randf() < 0.1: type = "badger"
			
			spawn_enemy(type, spawn_pos)
			print("Simulating spawn of ", type, " at ", spawn_pos)
			
	# Spawn a few Knights near walls
	spawn_enemy("knight", Vector3(12, 5, 12))
	spawn_enemy("knight", Vector3(42, 5, 32))
	print("--- TRIED SPAWNING ENEMIES END ---")


	


func _spawn_water_surface(x, y, z):
	var mesh = MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	# Thin layer
	mesh.mesh.size = Vector3(block_size, block_size * 0.1, block_size)
	mesh.material_override = materials["water_surface"]
	# Position slightly higher (waist/knee deep?)
	# Water block is at y. Top is y + 0.5.
	# Raise to 0.75 (0.25 above block) to cover feet.
	mesh.position = Vector3(x, y + 0.75, z) * block_size
	# No collision
	voxel_container.add_child(mesh)

func build_castle(start_x, start_z, width, depth, wall_height):
	# Clear the entire area
	for x in range(start_x, start_x + width):
		for z in range(start_z, start_z + depth):
			clear_column(x, z)
	
	# Add grass floor to entire interior
	for x in range(start_x, start_x + width):
		for z in range(start_z, start_z + depth):
			spawn_voxel(x, 0, z, TileType.DIRT)
			spawn_voxel(x, 1, z, TileType.GRASS)
	
	# Build perimeter walls (hollow interior)
	for x in range(start_x, start_x + width):
		for z in range(start_z, start_z + depth):
			# Only build on perimeter
			var is_perimeter = (x == start_x or x == start_x + width - 1 or 
								z == start_z or z == start_z + depth - 1)
			
			if is_perimeter:
				# Build wall from ground to wall_height
				for y in range(wall_height + 1):
					spawn_voxel(x, y, z, TileType.BRICK)
				
				# Add battlements (crenellations) on top
				# Alternating pattern: solid, air, solid, air
				if (x + z) % 2 == 0:
					spawn_voxel(x, wall_height + 1, z, TileType.BRICK)
	
	# Build 4 corner watchtowers (3x3, taller than walls)
	var tower_height = wall_height + 3
	var corners = [
		Vector2i(start_x, start_z),                          # Bottom-left
		Vector2i(start_x + width - 3, start_z),              # Bottom-right
		Vector2i(start_x, start_z + depth - 3),              # Top-left
		Vector2i(start_x + width - 3, start_z + depth - 3)   # Top-right
	]
	
	for corner in corners:
		for tx in range(3):
			for tz in range(3):
				var x = corner.x + tx
				var z = corner.y + tz
				
				# Build tower from ground to tower_height
				for y in range(tower_height + 1):
					spawn_voxel(x, y, z, TileType.BRICK)
				
				# Tower battlements (only on outer edges)
				var is_outer = (tx == 0 or tx == 2 or tz == 0 or tz == 2)
				if is_outer and (tx + tz) % 2 == 0:
					spawn_voxel(x, tower_height + 1, z, TileType.BRICK)
	
	# Build central well (3x3 with water in center)
	var well_x = start_x + width / 2 - 1
	var well_z = start_z + depth / 2 - 1
	
	for wx in range(3):
		for wz in range(3):
			var x = well_x + wx
			var z = well_z + wz
			
			# Outer ring is cobblestone
			if wx == 0 or wx == 2 or wz == 0 or wz == 2:
				spawn_voxel(x, 1, z, TileType.COBBLESTONE)
				spawn_voxel(x, 2, z, TileType.COBBLESTONE)
			else:
				# Center is water
				spawn_voxel(x, 1, z, TileType.WATER)
				_spawn_water_surface(x, 1, z)
	
	# Spawn knights in castle courtyard
	var num_knights = randi_range(2, 4)
	for i in range(num_knights):
		var spawn_x = start_x + randi_range(3, width - 4)
		var spawn_z = start_z + randi_range(3, depth - 4)
		var spawn_pos = Vector3(spawn_x * block_size, 3.0, spawn_z * block_size)
		spawn_enemy("knight", spawn_pos)
func generate_town(center_x: int, center_z: int):
	print("Generating town at (", center_x, ", ", center_z, ")")
	var TownGen = load("res://Scripts/Environment/TownGenerator.gd")
	TownGen.generate_town_layout(self, center_x, center_z)

func clear_column(target_x: int, target_z: int):
	# Clear all Y positions for this X/Z column
	# Use chunk_size.y to handle the new increased height
	for y in range(chunk_size.y):
		var key = Vector3i(target_x, y, target_z)
		if voxel_map.has(key):
			voxel_map[key].queue_free()
			voxel_map.erase(key)

func spawn_voxel(x, y, z, type) -> MeshInstance3D:
	var key = Vector3i(x, y, z)
	if voxel_map.has(key):
		voxel_map[key].queue_free() # Replace existing
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = BoxMesh.new()
	mesh_instance.mesh.size = Vector3(block_size, block_size, block_size)
	
	if type in materials:
		mesh_instance.material_override = materials[type]
	
	mesh_instance.position = Vector3(x, y, z) * block_size
	voxel_container.add_child(mesh_instance)
	
	voxel_map[key] = mesh_instance
	
	# Add Collision
	var static_body = StaticBody3D.new()
	mesh_instance.add_child(static_body)
	# Store coords in metadata for projectile hit logic
	static_body.set_meta("grid_pos", key)
	
	# Initialize Health
	var max_hp = tile_durability.get(type, 20)
	mesh_instance.set_meta("health", max_hp)
	mesh_instance.set_meta("type", type)
	
	var col_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(block_size, block_size, block_size)
	col_shape.shape = box_shape
	static_body.add_child(col_shape)
	
	return mesh_instance

func spawn_building_voxel(x: int, y: int, z: int, type: int, building_id: String):
	var mesh = spawn_voxel(x, y, z, type)
	# Set metadata
	mesh.set_meta("building_id", building_id)
	
	# Attempt to decorate (e.g. torches on walls)
	var hash_val = x * 31337 + y * 73 + z * 101
	decorate_wall_face(mesh, x, z, hash_val)

var tile_durability = {
	TileType.GRASS: 15,  # Was 50
	TileType.DIRT: 15,   # Was 50
	TileType.DESERT: 25, # Was 100
	TileType.STONE: 30,  # Was 100
	TileType.WALL: 80,   # Was 300
	TileType.WATER: 1,   # Instant break
	TileType.WOOD_PLANKS: 20,  # Building material
	TileType.COBBLESTONE: 25,  # Building material
	TileType.THATCH: 10,       # Roof material
	TileType.BRICK: 30         # Building material
}

func damage_block(grid_pos: Vector3i, damage: int) -> bool:
	# Returns true if destroyed
	if not voxel_map.has(grid_pos):
		return false
		
	var node = voxel_map[grid_pos]
	
	# Check Indestructible (via StaticBody child? No, voxel_map stores MeshInstance)
	# wait, spawn_voxel adds StaticBody as child.
	# But _spawn_indestructible_voxel adds MeshInstance to container, but does NOT add to voxel_map (key based).
	# So normal `damage_block` calls `voxel_map[grid_pos]`. 
	# Border trees are "small voxels" (decorations), which usually don't have grid_pos entries in `voxel_map`.
	# Projectiles hitting them will hit their StaticBody.
	# Projectile.gd checks `body.has_meta("grid_pos")`.
	# Our border trees don't set "grid_pos" on their static body.
	# So Projectile will fall through to `body.has_method("take_damage")`. 
	# Our StaticBody doesn't have that.
	# So they will be naturally invincible unless we add logic!
	# BUT, we want them to stop projectiles/player.
	# The current logic is fine: they are just static bodies. 
	
	# However, if the user hits the GROUND under the tree, they might undermine it.
	# For now, that's acceptable unless "Indestructible" implies the ground too?
	# Let's assume just the trees.
	
	# If we want to support "mining" regular trees vs border trees:
	# Regular trees are also decoration "small voxels" without grid entries?
	# Looking at `create_tree` -> `_add_small_voxel` -> looks like they are just visual/small collision.
	# If `_add_small_voxel` is used, do they have collision? 
	# `create_tree` uses a `TreeController` root often!
	
	# Let's quick-check if we need to modify damage_block logic for completeness.
	# If `damage_block` is called, it means we hit a grid voxel.
	# If we hit the decoration, we hit whatever collision it has.
	
	var current_hp = node.get_meta("health", 10)
	current_hp -= damage
	node.set_meta("health", current_hp)
	
	# Visual feedback - Always spawn small debris on hit for better feel
	var debris_color = Color.WHITE
	if node.material_override is StandardMaterial3D:
		debris_color = node.material_override.albedo_color
	elif node.material_override is ShaderMaterial:
		# Water blocks use shader material
		debris_color = Color(0.2, 0.4, 0.9)
	spawn_debris(node.position, debris_color)
	
	if current_hp <= 0:
		return _destroy_block_internal(grid_pos)
	
	return false

func _destroy_block_internal(grid_pos: Vector3i) -> bool:
	if not voxel_map.has(grid_pos): return false
	
	var node = voxel_map[grid_pos]
	var pos = grid_pos 
	
	# Spawn Particles (Explosion) - get color safely
	var debris_color = Color.WHITE
	if node.material_override is StandardMaterial3D:
		debris_color = node.material_override.albedo_color
	elif node.material_override is ShaderMaterial:
		debris_color = Color(0.2, 0.4, 0.9)
	spawn_debris(node.position, debris_color)
	
	# Remove
	node.queue_free()
	voxel_map.erase(grid_pos)
	
	# 2. Infinite Water Table Logic
	if pos.y <= 1:
		var sea_level_pos = Vector3i(pos.x, 0, pos.z)
		call_deferred("_restore_water", sea_level_pos)

	# 3. Enemy Spawning Logic
	# Chance to spawn relevant enemy
	if randf() < 0.25: # 25% chance
		var enemy_type = ""
		var col_data = columns[pos.x][pos.z] 
		# Note: pos.y might be different from col_data height if digging down, but type usually consistent in column for spawning purposes
		# Or better, check the type of the block we just destroyed.
		# We don't easily have 'type' here as node is generic MeshInstance.
		# But we can infer or store it.
		# Actually, we can assume based on metadata if we stored it, or material?
		# Let's fallback to column data type for simplicity, or just simple heuristics.
		
		# VoxelWorld.gd stores everything in columns[x][z]["type"] which is the SURFACE type.
		# If we are destroying a deep block, it's likely dirt/stone.
		var surface_type = columns[pos.x][pos.z]["type"]
		
		# Don't spawn enemies from castle walls or structural blocks
		if surface_type == TileType.WALL or surface_type == TileType.BRICK:
			pass # No enemy spawning from castle blocks
		elif surface_type == TileType.GRASS:
			if randf() < 0.5: enemy_type = "snake"
			else: enemy_type = "squirrel"
		elif surface_type == TileType.DIRT:
			enemy_type = "snake"
		elif surface_type == TileType.DESERT:
			enemy_type = "badger"
		
		if enemy_type != "":
			spawn_enemy(enemy_type, node.position)

	# 4. Loot?
	spawn_loot(node.position)
		
	return true
	
func spawn_loot(pos: Vector3):
	var roll = randf()
	if roll < 0.1: # 10% Chance
		# Decide type
		var type = Pickup.PickupType.HEALTH
		var type_roll = randf()
		if type_roll < 0.5:
			type = Pickup.PickupType.HEALTH
		elif type_roll < 0.75:
			type = Pickup.PickupType.DAMAGE
		else:
			type = Pickup.PickupType.SPEED
			
		var pickup = PowerupFactory.create_powerup(type)
		pickup.position = pos + Vector3(0, 0.2, 0)  # Reduced from 0.5 to prevent floating overhead
		
		# Add to scene, not voxel container, to persist
		add_child(pickup)
		print("Spawned Powerup: ", type)


func _restore_water(pos: Vector3i):
	# Forces water at this location (Sea Level)
	
	# If there is already a block here (e.g. Dirt underneath the Grass we just broke)
	# We must remove it to make room for water.
	if voxel_map.has(pos):
		# Optimization: If it's already water, do nothing
		# We can check material override or metadata. 
		# For now, simplistic check: assume if we are calling this, we want to ensure water.
		var node = voxel_map[pos]
		node.queue_free()
		voxel_map.erase(pos)
	
	spawn_voxel(pos.x, pos.y, pos.z, TileType.WATER)
	_spawn_water_surface(pos.x, pos.y, pos.z)


func spawn_debris(pos: Vector3, color: Color):
	var particles = CPUParticles3D.new()
	particles.position = pos
	particles.emitting = true
	particles.amount = 6 # Reduced from 10
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.lifetime = 0.5
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.1, 0.1, 0.1) # Shrunk from 0.2
	particles.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	particles.material_override = mat
	particles.direction = Vector3(0, 1, 0)
	particles.initial_velocity_min = 1.0 # Reduced from 2.0
	particles.initial_velocity_max = 2.5 # Reduced from 5.0
	add_child(particles)
	# Manual timer for cleanup
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.autostart = true
	timer.connect("timeout", particles.queue_free)
	particles.add_child(timer)

func spawn_enemy(type: String, pos: Vector3):
	var enemy = Enemy3D.new()
	# Enemy3D is a class_name, so new() creates it with the script attached.
	
	# Setup visuals
	var visuals = VoxelEnemyFactory.create_enemy_node(type)
	enemy.add_child(visuals)
	
	# Setup collision
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.0
	col.shape = cap
	col.position.y = 0.5
	enemy.add_child(col)
	
	# Configure Stats based on type
	match type:
		"knight":
			enemy.max_health = 150 # Was 60
			enemy.speed = 2.5
			enemy.damage = 15
		"snake":
			enemy.max_health = 50 # Was 20
			enemy.speed = 3.5
			enemy.damage = 10
			enemy.enemy_type = "snake"
		"squirrel":
			enemy.max_health = 30 # Was 10
			enemy.speed = 6.0
			enemy.damage = 5
		"badger":
			enemy.max_health = 100 # Robust
			enemy.speed = 2.0
			enemy.damage = 8
			
	# Apply max health to current
	enemy.current_health = enemy.max_health
	
	enemy.position = pos
	add_child(enemy)
	print("(!) A wild ", type.to_upper(), " appeared at ", pos, " with ", enemy.max_health, " HP!")

func _init_materials():
	# Load Shaders
	var water_shader = load("res://Resources/Shaders/Water.gdshader")
	var building_shader = load("res://Resources/Shaders/Building.gdshader")
	var surface_shader = load("res://Resources/Shaders/WaterSurface.gdshader")
	
	# Common noise for buildings
	var b_noise = FastNoiseLite.new()
	b_noise.frequency = 0.05
	var b_tex = NoiseTexture2D.new(); b_tex.noise = b_noise; b_tex.width = 64; b_tex.height = 64;
	
	# Load Voxel Shader
	var voxel_shader = load("res://Resources/Shaders/Voxel.gdshader")
	
	# Create shared noise texture for voxel materials
	var voxel_noise = FastNoiseLite.new()
	voxel_noise.seed = randi()
	voxel_noise.frequency = 0.1
	voxel_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	
	var voxel_noise_tex = NoiseTexture2D.new()
	voxel_noise_tex.noise = voxel_noise
	voxel_noise_tex.seamless = true
	voxel_noise_tex.width = 128
	voxel_noise_tex.height = 128
	
	# Create a shared material for each color to improve performance
	for type in tile_colors:
		if type == TileType.WATER:
			# Special Shader Material for Water - Keep existing
			var mat = ShaderMaterial.new()
			mat.shader = water_shader
			
			# Generate Noise Texture for the shader
			var noise = FastNoiseLite.new()
			noise.seed = randi()
			noise.frequency = 0.008 
			noise.fractal_type = FastNoiseLite.FRACTAL_FBM
			
			var noise_tex = NoiseTexture2D.new()
			noise_tex.noise = noise
			noise_tex.seamless = true
			noise_tex.width = 256
			noise_tex.height = 256
			
			mat.set_shader_parameter("noise_texture", noise_tex)
			mat.set_shader_parameter("albedo", tile_colors[TileType.WATER])
			
			materials[type] = mat
			
		elif type == TileType.WALL or type == TileType.BRICK or type == TileType.WOOD_PLANKS or type == TileType.COBBLESTONE or type == TileType.WOOD:
			# Use Voxel Shader with patterns
			var mat = ShaderMaterial.new()
			mat.shader = voxel_shader
			mat.set_shader_parameter("albedo", tile_colors[type])
			mat.set_shader_parameter("texture_albedo", voxel_noise_tex)
			
			# Set pattern based on type
			if type == TileType.WOOD or type == TileType.WOOD_PLANKS:
				mat.set_shader_parameter("pattern_type", 1) # Wood grain
			elif type == TileType.COBBLESTONE or type == TileType.BRICK:
				mat.set_shader_parameter("pattern_type", 2) # Cracked
			else:
				mat.set_shader_parameter("pattern_type", 0) # Subtle
			
			materials[type] = mat
			
		else:
			# Use Voxel Shader instead of StandardMaterial3D
			var mat = ShaderMaterial.new()
			mat.shader = voxel_shader
			mat.set_shader_parameter("albedo", tile_colors[type])
			mat.set_shader_parameter("texture_albedo", voxel_noise_tex)
			
			# Set pattern and roughness based on material type
			if type == TileType.STONE or type == TileType.DESERT:
				mat.set_shader_parameter("pattern_type", 2) # Cracked look
				mat.set_shader_parameter("roughness", 0.7)
			elif type == TileType.GRASS:
				mat.set_shader_parameter("pattern_type", 0) # Subtle (keep as-is)
				mat.set_shader_parameter("roughness", 0.9)
			elif type == TileType.DIRT:
				mat.set_shader_parameter("pattern_type", 0) # Subtle
				mat.set_shader_parameter("roughness", 0.7)
			else:
				mat.set_shader_parameter("pattern_type", 0) # Subtle
				mat.set_shader_parameter("roughness", 0.8)
			
			materials[type] = mat

	# Create Water Surface Material (Opaque Translucent Layer)
	var mat_surface = ShaderMaterial.new()
	mat_surface.shader = surface_shader
	var s_noise = FastNoiseLite.new()
	s_noise.seed = randi()
	s_noise.frequency = 0.01
	var s_tex = NoiseTexture2D.new(); s_tex.noise = s_noise; s_tex.seamless = true; s_tex.width = 256; s_tex.height = 256;
	mat_surface.set_shader_parameter("noise_texture", s_tex)
	materials["water_surface"] = mat_surface

func decorate_voxel(parent_voxel: MeshInstance3D, tile_type: int, x: int, z: int):
	# Better hash function to avoid diagonal patterns
	var h = (x * 374761393) ^ (z * 668265263) # Prime number mixing
	h = (h ^ (h >> 13)) * 1274126177
	var rand_val = (h & 0x7FFFFFFF) % 100
	
	# GRASS BIOME
	if tile_type == TileType.GRASS:
		# 1. Flowers (5% chance)
		if rand_val < 5:
			create_flower(parent_voxel)
		# 2. Grass Patches (15% chance) - different hash
		elif ((h >> 7) & 0x7FFFFFFF) % 100 < 15:
			create_grass_patch(parent_voxel)
		# 3. Trees (8% chance) - different hash
		elif ((h >> 4) & 0x7FFFFFFF) % 100 < 8:
			create_tree(parent_voxel, h)
			
	# DESERT BIOME
	elif tile_type == TileType.DESERT:
		# 1. Cacti (3% chance)
		if rand_val < 3:
			create_cactus(parent_voxel, (h % 2 == 0)) # 50/50 big/small
		# 2. Pebbles (10% chance) - different hash
		elif ((h >> 7) & 0x7FFFFFFF) % 100 < 10:
			create_pebbles(parent_voxel)
			
	# WALL BIOME (Castle)
	elif tile_type == TileType.WALL:
		# Check all 4 sides for exposed faces and decorate
		decorate_wall_face(parent_voxel, x, z, h)

func create_flower(parent: Node3D):
	# Create a simple 3-voxel flower
	var stem_color = materials[TileType.GRASS_TUFT] if TileType.GRASS_TUFT in materials else materials[TileType.GRASS]
	var petal_color = materials[TileType.FLOWER]
	
	# Much smaller voxel size for "pixel" look (approx 1/12 of block)
	var s = block_size * 0.08 
	
	# Stem
	_add_small_voxel(parent, Vector3(0, 0.5 + s/2, 0), s, stem_color)
	_add_small_voxel(parent, Vector3(0, 0.5 + s*1.5, 0), s, stem_color) # Taller stem
	
	# Petals (Top)
	var h = 0.5 + s * 2.5
	_add_small_voxel(parent, Vector3(0, h, 0), s, petal_color)
	# Petals (Sides)
	_add_small_voxel(parent, Vector3(s, h, 0), s, petal_color)
	_add_small_voxel(parent, Vector3(-s, h, 0), s, petal_color)
	_add_small_voxel(parent, Vector3(0, h, s), s, petal_color)
	_add_small_voxel(parent, Vector3(0, h, -s), s, petal_color)

func create_grass_patch(parent: Node3D):
	# Create 2-3 random grass blades
	var grass_color = materials[TileType.GRASS_TUFT] if TileType.GRASS_TUFT in materials else materials[TileType.GRASS]
	var s = block_size * 0.08
	
	for i in range(4): # Slightly more blades since they are smaller
		var offset = Vector3(randf_range(-0.35, 0.35), 0.5 + s/2, randf_range(-0.35, 0.35))
		_add_small_voxel(parent, offset, s, grass_color)

func create_cactus(parent: Node3D, is_big: bool):
	var cactus_color = materials.get(TileType.CACTUS, materials[TileType.GRASS])
	var s = block_size * 0.12 # Slightly thicker than flowers
	
	# Base
	var h_blocks = 2 if is_big else 1
	var center_x = 0.0
	var center_z = 0.0
	
	# Main trunk
	for i in range(h_blocks * 3): # 3 mini-voxels per "block" height
		_add_small_voxel(parent, Vector3(0, 0.5 + i*s + s/2, 0), s, cactus_color)
	
	# Arms (only for big ones)
	if is_big:
		var arm_h = 0.5 + s * 3.5
		# Right arm
		_add_small_voxel(parent, Vector3(s, arm_h, 0), s, cactus_color)
		_add_small_voxel(parent, Vector3(s*2, arm_h, 0), s, cactus_color)
		_add_small_voxel(parent, Vector3(s*2, arm_h+s, 0), s, cactus_color)

func create_pebbles(parent: Node3D):
	var pebble_color = materials.get(TileType.SAND_PEBBLE, materials[TileType.DESERT])
	var s = block_size * 0.06 # Very tiny
	
	for i in range(randi_range(2, 5)):
		var offset = Vector3(randf_range(-0.4, 0.4), 0.5 + s/2, randf_range(-0.4, 0.4))
		_add_small_voxel(parent, offset, s, pebble_color)

func create_tree(parent: Node3D, hash_val: int):
	# Decide tree type based on hash
	var is_pine = (hash_val % 3 == 0) # 33% chance for pine
	
	# Select leaf color based on hash
	var leaf_types = [TileType.LEAVES, TileType.LEAVES_LIGHT, TileType.LEAVES_DARK]
	var leaf_type = leaf_types[(hash_val >> 8) % leaf_types.size()]
	
	# Create a root node for the tree to manage its falling
	var tree_root = Node3D.new()
	tree_root.name = "TreeRoot"
	tree_root.set_script(load("res://Scripts/Environment/TreeController.gd"))
	parent.add_child(tree_root)
	
	if is_pine:
		create_pine_tree(tree_root, leaf_type)
	else:
		create_regular_tree(tree_root, leaf_type, hash_val)

func create_pine_tree(parent: Node3D, leaf_type: int):
	var wood_color = materials.get(TileType.WOOD, materials[TileType.DIRT])
	var leaf_color = materials.get(leaf_type, materials[TileType.LEAVES])
	var s = block_size * 0.15
	
	var trunk_height = randi_range(7, 10)
	for i in range(trunk_height):
		_add_small_voxel(parent, Vector3(0, 0.5 + i*s + s/2, 0), s, wood_color, true, 20, parent, true)
	
	# Pine canopy (Tiered cones)
	var start_y_mini = 4 # Start canopy a bit up the trunk
	for tier in range(3):
		var tier_y = 0.5 + (start_y_mini + tier * 2) * s
		var radius = 3 - tier # Tapar upwards
		
		for cx in range(-radius, radius + 1):
			for cz in range(-radius, radius + 1):
				# Rounded corners for tiers
				if abs(cx) == radius and abs(cz) == radius: continue
				
				# Don't overlap trunk in lower tiers if not needed, but for simplicity we fill
				_add_small_voxel(parent, Vector3(cx*s, tier_y, cz*s), s, leaf_color, true, 5)
				# Add a secondary layer to each tier for thickness
				_add_small_voxel(parent, Vector3(cx*0.7*s, tier_y + s, cz*0.7*s), s, leaf_color, true, 5)

	# Tip
	_add_small_voxel(parent, Vector3(0, 0.5 + (trunk_height + 1) * s, 0), s, leaf_color, true, 5)

func create_regular_tree(parent: Node3D, leaf_type: int, hash_val: int):
	var wood_color = materials.get(TileType.WOOD, materials[TileType.DIRT])
	var leaf_color = materials.get(leaf_type, materials[TileType.LEAVES])
	var s = block_size * 0.15
	
	var trunk_height = randi_range(6, 9)
	for i in range(trunk_height):
		_add_small_voxel(parent, Vector3(0, 0.5 + i*s + s/2, 0), s, wood_color, true, 20, parent, true)
		
	# Full foliage (Round/Bushy)
	var canopy_center_y = 0.5 + trunk_height * s
	var layers = 4
	for ly in range(layers):
		var y_pos = canopy_center_y + (ly - 1) * s
		var radius = 2
		if ly == 0 or ly == layers - 1: radius = 1 # Taper top and bottom
		
		for cx in range(-radius, radius + 1):
			for cz in range(-radius, radius + 1):
				if radius > 1 and abs(cx) == radius and abs(cz) == radius: continue
				
				# Randomly skip some outer voxels for "noisy" foliage look
				var spawn_hash = (hash_val ^ (cx * 13) ^ (cz * 17) ^ (ly * 19))
				if radius > 1 and (spawn_hash % 10) < 2: continue 
				
				_add_small_voxel(parent, Vector3(cx*s, y_pos, cz*s), s, leaf_color, true, 5)


func decorate_wall_face(parent: MeshInstance3D, x: int, z: int, hash_val: int):
	# Get type from metadata
	var type = parent.get_meta("type", TileType.GRASS)
	
	# Check 4 neighbors to see if faces are exposed
	# Heuristic: Exposed if neighbor Y is lower than current Y
	var current_y = int((parent.position.y) / block_size + 0.5)
	
	var neighbors = [
		{"dir": Vector3(1, 0, 0), "x": x + 1, "z": z, "face_center": Vector3(0.5, 0, 0), "face_rot": Vector3(0, 0, 90)},   # Right
		{"dir": Vector3(-1, 0, 0), "x": x - 1, "z": z, "face_center": Vector3(-0.5, 0, 0), "face_rot": Vector3(0, 0, 90)}, # Left
		{"dir": Vector3(0, 0, 1), "x": x, "z": z + 1, "face_center": Vector3(0, 0, 0.5), "face_rot": Vector3(90, 0, 0)},   # Front
		{"dir": Vector3(0, 0, -1), "x": x, "z": z - 1, "face_center": Vector3(0, 0, -0.5), "face_rot": Vector3(90, 0, 0)}  # Back
	]
	


func _create_border_tree(x: int, y: int, z: int):
	# Optimized for performance: Uses simple shapes instead of voxels
	var wood_color = materials.get(TileType.WOOD, materials[TileType.DIRT])
	var leaf_color = materials.get(TileType.LEAVES_DARK, materials[TileType.LEAVES])
	
	var origin = Vector3(x, y, z) * block_size
	var tree_scale = 1.5 # Make them big
	
	# 1. Trunk (Single Mesh)
	var trunk_h = 6.0 * tree_scale
	var trunk_w = 0.6 * tree_scale
	
	var trunk = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(trunk_w, trunk_h, trunk_w)
	trunk.mesh = box
	trunk.material_override = wood_color
	trunk.position = origin + Vector3(0, trunk_h / 2.0, 0)
	voxel_container.add_child(trunk)
	
	_add_static_collision(trunk, box.size)
	
	# 2. Canopy (3 Pyramids/Cones)
	var leaves_start_y = trunk_h * 0.4
	var canopy_base_w = 2.5 * tree_scale
	
	for i in range(3):
		var tier_w = canopy_base_w * (1.0 - (i * 0.2))
		var tier_h = 3.0 * tree_scale
		var tier_y = origin.y + leaves_start_y + (i * 1.5 * tree_scale)
		
		var leaves = MeshInstance3D.new()
		var prism = PrismMesh.new() # Pyramid-like
		prism.size = Vector3(tier_w, tier_h, tier_w)
		leaves.mesh = prism
		leaves.material_override = leaf_color
		leaves.position = Vector3(origin.x, tier_y + tier_h/2.0, origin.z)
		voxel_container.add_child(leaves)
		
		# Collision for leaves? Maybe just the trunk is enough for blocking.
		# But arrows should hit leaves.
		_add_static_collision(leaves, prism.size)

func _add_static_collision(parent: MeshInstance3D, size: Vector3):
	var sb = StaticBody3D.new()
	parent.add_child(sb)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new() # Approximation is fine
	shape.size = size
	col.shape = shape
	sb.add_child(col)
	
	sb.set_meta("health", 999999)
	sb.set_meta("indestructible", true)

# Deprecated/Unused for borders now
func _spawn_indestructible_voxel(pos: Vector3, size: float, mat: Material):
	# ... (Keep existing if needed, or remove)
	var mesh = MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	mesh.mesh.size = Vector3(size, size, size)
	mesh.material_override = mat
	mesh.position = pos
	voxel_container.add_child(mesh)
	
	var sb = StaticBody3D.new()
	mesh.add_child(sb)
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(size, size, size)
	col.shape = box
	sb.add_child(col)
	
	sb.set_meta("health", 999999)
	sb.set_meta("indestructible", true)

	

func add_wall_detail(parent: Node3D, pos: Vector3, rot_deg: Vector3, color: Color, type: String, seed_val: int):
	# If torch, instantiate scene
	if type == "torch":
		# Load safely (should be preloaded in _init)
		var torch_scene = load("res://Scenes/Environment/Torch.tscn")
		var torch = torch_scene.instantiate()
		
		# Position logic
		# 'pos' is the face center relative to block center (e.g., Vector3(0.5, 0, 0))
		# 'offset' needs to be in meters
		var offset = pos * block_size
		
		# Move slightly OUT from wall to prevent clipping
		# Increase spacing to avoid "disjointed" look if it was sinking in
		offset.x *= 1.2 
		offset.z *= 1.2
		
		# Vertical adjustments
		offset.y += 0.2
		
		torch.position = offset
		
		# Rotation Logic
		# 'pos' is the normal vector of the face basically.
		# If pos.x = 0.5 (Right face), we want torch to attach to Right face.
		# Torch scene assumes UP is Y. Stick usually points down or diagonal.
		# If we assume torch local Z is "away from wall", we look_at.
		
		# Better approach: Explicit rotation based on normal.
		if pos.x > 0.1: # Right Face (+X) -> Face Right
			torch.rotation_degrees.y = -90 
		elif pos.x < -0.1: # Left Face (-X) -> Face Left
			torch.rotation_degrees.y = 90
		elif pos.z > 0.1: # Front Face (+Z) -> Face Forward
			torch.rotation_degrees.y = 180 # Or 0 depending on model
		elif pos.z < -0.1: # Back Face (-Z) -> Face Back
			torch.rotation_degrees.y = 0
			
		parent.add_child(torch)
		return

	var mesh = MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	
	# Create pseudo-random variance from seed
	var r1 = ((seed_val * 1103515245 + 12345) & 0x7FFFFFFF) % 100 / 100.0
	var r2 = ((seed_val * 1103515245 + 54321) & 0x7FFFFFFF) % 100 / 100.0
	var r3 = ((seed_val * 1103515245 + 67890) & 0x7FFFFFFF) % 100 / 100.0
	
	var offset = pos * block_size
	
	if type == "brick":
		# Protruding brick
		var w = block_size * 0.4 + (r3 * 0.1) # vary width
		var h = block_size * 0.2 + (r1 * 0.05) # vary height
		mesh.mesh.size = Vector3(w, h, block_size * 0.1)
		
		# Protrude slightly out
		offset += pos.normalized() * (block_size * 0.05)
		
		# Vary position on face
		# Vertical Shift (+/- 0.25)
		offset.y += (r2 - 0.5) * 0.5 * block_size
		
		# Horizontal Shift (+/- 0.15)
		# Needs to be perpendicular to normal
		if abs(pos.x) > 0.01: # Side face -> Shift Z
			offset.z += (r3 - 0.5) * 0.3 * block_size
		else: # Front/Back -> Shift X
			offset.x += (r3 - 0.5) * 0.3 * block_size
		
	elif type == "crack":
		# Thin dark line
		mesh.mesh.size = Vector3(block_size * 0.3, block_size * 0.05, block_size * 0.02)
		offset += pos.normalized() * (block_size * 0.01) # Just barely on surface
		
		# Random rotation for cracks
		mesh.rotation_degrees.z = (r1 - 0.5) * 45.0
		
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mesh.material_override = mat
	
	mesh.position = offset
	
	# Rotate based on face
	if abs(pos.x) > 0.01: # Side faces (Left/Right)
		mesh.rotation_degrees += Vector3(0, 90, 0)
	else: # Front/Back
		mesh.rotation_degrees += Vector3(0, 0, 0)
		
	parent.add_child(mesh)

func _add_small_voxel(parent: Node3D, pos: Vector3, size: float, material: Material, has_collision: bool = false, health: int = 0, tree_controller = null, is_trunk: bool = false):
	var mesh = MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	mesh.mesh.size = Vector3(size, size, size)
	mesh.material_override = material
	mesh.position = pos
	parent.add_child(mesh)
	
	if has_collision:
		var body
		if health > 0:
			# Destructible
			body = load("res://Scripts/Environment/SmallDestructible.gd").new()
			body.health = health
			body.tree_controller = tree_controller
			body.is_trunk = is_trunk
		else:
			# Indestructible static body
			body = StaticBody3D.new()
			
		mesh.add_child(body)
		
		# Add Collision Shape
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(size, size, size)
		col.shape = box
		body.add_child(col)
