extends Node3D

@export var speed: float = 10.0
@export var limb_max_angle: float = 45.0
@export var voxel_size: float = 0.025 # High resolution (was 0.1) -> 4x detail

var materials = {}

# Node references
var pivot_limb_l_arm : Node3D
var pivot_limb_r_arm : Node3D
var pivot_limb_l_leg : Node3D
var pivot_limb_r_leg : Node3D

func _ready():
	_init_materials()
	_build_character()

func _process(delta):
	_animate(delta)

func _init_materials():
	# 1. Silver Armor (Metallic)
	var mat_armor = StandardMaterial3D.new()
	mat_armor.albedo_color = Color(0.9, 0.9, 0.95) # Bright Silver
	mat_armor.metallic = 0.9
	mat_armor.roughness = 0.2
	materials["armor"] = mat_armor
	
	# 2. Dark Grey (Joints/Visor)
	var mat_dark = StandardMaterial3D.new()
	mat_dark.albedo_color = Color(0.15, 0.15, 0.15)
	mat_dark.metallic = 0.5
	materials["dark"] = mat_dark
	
	# 3. Gold/Detail (Trim)
	var mat_gold = StandardMaterial3D.new()
	mat_gold.albedo_color = Color(1.0, 0.8, 0.2)
	mat_gold.metallic = 0.9
	mat_gold.roughness = 0.2
	materials["gold"] = mat_gold
	
	# 4. Skin (for face)
	var mat_skin = StandardMaterial3D.new()
	mat_skin.albedo_color = Color(0.9, 0.7, 0.6)
	materials["skin"] = mat_skin
	
	# 5. Red (Cape)
	var mat_red = StandardMaterial3D.new()
	mat_red.albedo_color = Color(0.8, 0.1, 0.1)
	mat_red.roughness = 0.6 # Fabric look
	materials["red"] = mat_red
	
	# 6. Blue (Shield)
	var mat_blue = StandardMaterial3D.new()
	mat_blue.albedo_color = Color(0.1, 0.3, 0.8)
	mat_blue.metallic = 0.6
	mat_blue.roughness = 0.4
	materials["blue"] = mat_blue

func _build_character():
	# --- TORSO (16x20x10 voxels) ---
	var torso = _create_part(Vector3i(16, 20, 10), _color_torso)
	var torso_pivot = Node3D.new()
	torso_pivot.position.y = 0.7
	add_child(torso_pivot)
	torso.position = -Vector3(16, 20, 10) * voxel_size * 0.5 
	torso_pivot.add_child(torso)
	
	# CAPE (Attached to Torso)
	var cape = _create_part(Vector3i(14, 22, 2), _color_cape)
	# Position at back of torso
	# Torso Z range -5..5 (centered). Front is +5. Back is -5.
	# Cape should be at -5 - (CapeDepth/2) = -6
	# voxel_size = 0.025. 
	cape.position = Vector3(-7 * voxel_size, -10 * voxel_size, -6 * voxel_size - 0.01) 
	torso_pivot.add_child(cape)
	
	# --- HEAD (14x14x14 voxels) ---
	var head = _create_part(Vector3i(14, 14, 14), _color_head)
	var head_pivot = Node3D.new()
	head_pivot.position.y = 1.22 # Lowered slightly to sit firmly on shoulders
	add_child(head_pivot)
	head.position = -Vector3(14, 14, 14) * voxel_size * 0.5
	head_pivot.add_child(head)
	
	# --- ARMS (6x18x6 voxels) ---
	# Pivot positions moved INWARDS to connect with body (0.35 -> 0.24)
	
	# Left Arm + SHIELD
	pivot_limb_l_arm = Node3D.new()
	pivot_limb_l_arm.position = Vector3(-0.24, 1.1, 0) 
	add_child(pivot_limb_l_arm)
	
	var l_arm = _create_part(Vector3i(6, 18, 6), _color_limb)
	l_arm.position = Vector3(-3, -16, -3) * voxel_size # Pivot at top
	pivot_limb_l_arm.add_child(l_arm)
	
	# SHIELD (Attached to Left Arm)
	var shield = _create_part(Vector3i(10, 14, 2), _color_shield)
	# Outer side of arm. Left Arm is usually -X. Outer is -X side.
	shield.position = Vector3(-5 * voxel_size - 0.1, -12 * voxel_size, 0) 
	pivot_limb_l_arm.add_child(shield)
	
	# Right Arm
	pivot_limb_r_arm = Node3D.new()
	pivot_limb_r_arm.position = Vector3(0.24, 1.1, 0)
	add_child(pivot_limb_r_arm)
	
	var r_arm = _create_part(Vector3i(6, 18, 6), _color_limb)
	r_arm.position = Vector3(-3, -16, -3) * voxel_size
	pivot_limb_r_arm.add_child(r_arm)
	
	# --- LEGS (6x18x6 voxels) ---
	# Move legs in slightly too (0.15 -> 0.12)
	# Left Leg
	pivot_limb_l_leg = Node3D.new()
	pivot_limb_l_leg.position = Vector3(-0.12, 0.5, 0)
	add_child(pivot_limb_l_leg)
	
	var l_leg = _create_part(Vector3i(6, 18, 6), _color_limb)
	l_leg.position = Vector3(-3, -16, -3) * voxel_size
	pivot_limb_l_leg.add_child(l_leg)
	
	# Right Leg
	pivot_limb_r_leg = Node3D.new()
	pivot_limb_r_leg.position = Vector3(0.12, 0.5, 0)
	add_child(pivot_limb_r_leg)
	
	var r_leg = _create_part(Vector3i(6, 18, 6), _color_limb)
	r_leg.position = Vector3(-3, -16, -3) * voxel_size
	pivot_limb_r_leg.add_child(r_leg)

# --- Pattern Functions ---

func _color_shield(x, y, z, w, h, d) -> Material:
	# Blue Shield with Gold Border
	if x == 0 or x == w-1 or y == 0 or y == h-1:
		return materials["gold"]
	# Gold Cross?
	if x == w/2 or x == w/2 - 1 or y == h/2 or y == h/2 - 1:
		return materials["gold"]
	return materials["blue"]

func _color_cape(x, y, z, w, h, d) -> Material:
	return materials["red"]

func _color_head(x, y, z, w, h, d) -> Material:
	# Helmet Face (Front = Low Z? Wait, _create_part uses Z=d-1 as front? Need to check orientation)
	# Standard is -Z forward. Mesh generation x,y,z usually 0..size.
	# If we center it, it aligns with axes.
	# Assuming Z=0 is Back and Z=size is Front (based on previous Body code using z==d-1 for Chest)
	
	# Front Face
	if z == d-1: 
		# Visor Slit
		if y >= 4 and y <= 6 and x >= 3 and x <= w-4:
			return materials["dark"]
		# Center Vertical Bar (Knight Helmet)
		if x == w/2 or x == w/2 - 1:
			if y <= 7 and y >= 3:
				return materials["armor"] # Break the visor
			
	# Helmet Wings (Sides)
	if x <= 1 or x >= w-2:
		# Wing shape in Gold/White
		if y >= 6 and y <= 12 and z < d-3:
			return materials["gold"]
			
	# Crest (Top)
	if y >= h-2:
		if x >= w/2-1 and x <= w/2:
			return materials["blue"] # Blue Plume? Or Red?
			
	return materials["armor"]

func _color_torso(x, y, z, w, h, d) -> Material:
	# Front chestplate design
	if z == d-1:
		# Gold trim on edges
		if x == 0 or x == w-1 or y == 0 or y == h-1:
			return materials["gold"]
		# Center emblem
		if x >= w/2 - 2 and x <= w/2 + 1 and y >= h/2 - 2 and y <= h/2 + 2:
			return materials["gold"]
			
	return materials["armor"]

func _color_limb(x, y, z, w, h, d) -> Material:
	# Joint (elbow/knee)
	if y >= h/2 - 1 and y <= h/2 + 1:
		return materials["dark"]
	# Hand/Foot
	if y < 3:
		return materials["dark"] # Glove/Boot
		
	return materials["armor"]

# --- Generation Logic ---

func _create_part(size: Vector3i, color_func: Callable) -> MeshInstance3D:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for x in range(size.x):
		for y in range(size.y):
			for z in range(size.z):
				# Rounding Check
				# Remove corners of the 2D footprint (X/Z plane)
				# "Pixel Art Circle" approximation
				# Skip corners (2x2 area roughly, depending on size)
				
				# Normalized coordinates centered at 0
				var nx = x - (size.x - 1) / 2.0
				var nz = z - (size.z - 1) / 2.0
				
				# Hardcoded corner cutting for rounding
				# If width > 4, cut 1 pixel corners. If width > 10, cut 2?
				var cut_depth = 1
				if size.x > 8: cut_depth = 2
				
				# Check constraints for corners
				# Top Left corner: x < cut, z < cut
				# etc
				
				# Logic: if sum of distance from edge is too small?
				# Let's simple check 4 corners
				var is_corner = false
				
				# Low X side
				if x < cut_depth:
					# Low Z
					if z < cut_depth:
						# Diagonally cut: x + z < cut_depth? Or straight box?
						# Straight box empty corner is cleaner for voxels
						if (cut_depth - x) + (cut_depth - z) > cut_depth: is_corner = true
					# High Z
					elif z >= size.z - cut_depth:
						if (cut_depth - x) + (z - (size.z - 1 - cut_depth)) > 1: is_corner = true # Rough approximation
				
				# High X side
				elif x >= size.x - cut_depth:
					# Low Z
					if z < cut_depth:
						if (x - (size.x - 1 - cut_depth)) + (cut_depth - z) > 1: is_corner = true
					# High Z
					elif z >= size.z - cut_depth:
						pass # Simplify: Just manhattan distance from center? 
						# Actually simpler:
						# If x is extreme AND z is extreme -> skip
						
				# Simplified logic:
				# Cut 1 voxel from very corners if size >= 4
				# Cut 2x1 and 1x2 pattern if size >= 8?
				if size.x >= 8:
					if (x < 2 and z < 1) or (x < 1 and z < 2) or \
					   (x >= size.x-2 and z < 1) or (x >= size.x-1 and z < 2) or \
					   (x < 2 and z >= size.z-1) or (x < 1 and z >= size.z-2) or \
					   (x >= size.x-2 and z >= size.z-1) or (x >= size.x-1 and z >= size.z-2):
						continue # Skip corner voxels
				
				elif size.x >= 4:
					if (x == 0 and z == 0) or (x == size.x-1 and z == 0) or \
					   (x == 0 and z == size.z-1) or (x == size.x-1 and z == size.z-1):
						continue
				

				var mat = color_func.call(x, y, z, size.x, size.y, size.z)
				var color = mat.albedo_color
				_add_voxel_face(st, Vector3(x, y, z), color)
	
	st.generate_normals()
	var mesh = st.commit()
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	
	var master_mat = StandardMaterial3D.new()
	master_mat.vertex_color_use_as_albedo = true
	master_mat.metallic = 0.8
	master_mat.roughness = 0.3
	mesh_instance.material_override = master_mat
	
	return mesh_instance

func _add_voxel_face(st: SurfaceTool, pos: Vector3, color: Color):
	var s = voxel_size
	pos *= s
	
	# To optimize, we should check neighbors and cull faces.
	# For simplicity now, just adding all 6 faces per voxel is FAST to write but high poly.
	# Given parts are small (16x20x10 = 3200 voxels), naive generation is ~38k tris. Fine for PC.
	
	var v = [
		Vector3(0,0,0), Vector3(s,0,0), Vector3(s,0,s), Vector3(0,0,s), # Bottom 0-3
		Vector3(0,s,0), Vector3(s,s,0), Vector3(s,s,s), Vector3(0,s,s)  # Top 4-7
	]
	# Offset
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

func _animate(delta):
	var parent = get_parent()
	if not parent is CharacterBody3D:
		return
		
	var velocity = parent.velocity
	var horizontal_vel = Vector3(velocity.x, 0, velocity.z).length()
	
	if horizontal_vel > 0.1:
		var t = Time.get_ticks_msec() / 1000.0 * speed
		var angle = sin(t) * deg_to_rad(limb_max_angle)
		
		pivot_limb_l_arm.rotation.x = angle
		pivot_limb_r_arm.rotation.x = -angle
		pivot_limb_l_leg.rotation.x = -angle
		pivot_limb_r_leg.rotation.x = angle
	else:
		var lerp_speed = delta * 10
		pivot_limb_l_arm.rotation.x = lerp(pivot_limb_l_arm.rotation.x, 0.0, lerp_speed)
		pivot_limb_r_arm.rotation.x = lerp(pivot_limb_r_arm.rotation.x, 0.0, lerp_speed)
		pivot_limb_l_leg.rotation.x = lerp(pivot_limb_l_leg.rotation.x, 0.0, lerp_speed)
		pivot_limb_r_leg.rotation.x = lerp(pivot_limb_r_leg.rotation.x, 0.0, lerp_speed)
