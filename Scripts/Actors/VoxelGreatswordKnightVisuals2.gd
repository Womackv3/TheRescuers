extends Node3D

# Procedural Greatsword Knight - Custom voxel design with known body part positions

@export var speed: float = 10.0
@export var limb_max_angle: float = 45.0
@export var voxel_size: float = 0.05

var materials = {}

# Node references
var pivot_limb_l_arm: Node3D
var pivot_limb_r_arm: Node3D
var pivot_limb_l_leg: Node3D
var pivot_limb_r_leg: Node3D

func _ready():
	_init_materials()
	_build_character()

func _process(delta):
	_animate(delta)

func _init_materials():
	# Silver armor
	var mat_armor = StandardMaterial3D.new()
	mat_armor.albedo_color = Color(0.85, 0.85, 0.85)
	mat_armor.metallic = 0.6
	mat_armor.roughness = 0.5
	materials["armor"] = mat_armor
	
	# Dark metal (joints/visor)
	var mat_dark = StandardMaterial3D.new()
	mat_dark.albedo_color = Color(0.2, 0.2, 0.2)
	mat_dark.metallic = 0.7
	mat_dark.roughness = 0.4
	materials["dark"] = mat_dark
	
	# Red cape
	var mat_cape = StandardMaterial3D.new()
	mat_cape.albedo_color = Color(0.7, 0.1, 0.1)
	mat_cape.roughness = 0.7
	materials["cape"] = mat_cape

func _build_character():
	# --- TORSO (10x14x8 voxels) ---
	var torso = _create_part(Vector3i(10, 14, 8), _color_torso)
	var torso_pivot = Node3D.new()
	torso_pivot.position.y = 0.7
	add_child(torso_pivot)
	torso.position = -Vector3(10, 14, 8) * voxel_size * 0.5
	torso_pivot.add_child(torso)
	
	# CAPE (Attached to back of torso)
	var cape = _create_part(Vector3i(8, 12, 2), _color_cape)
	cape.position = Vector3(-4 * voxel_size, -6 * voxel_size, -5 * voxel_size)
	torso_pivot.add_child(cape)
	
	# --- HEAD (8x8x8 voxels) ---
	var head = _create_part(Vector3i(8, 8, 8), _color_head)
	var head_pivot = Node3D.new()
	head_pivot.position.y = 1.4
	add_child(head_pivot)
	head.position = -Vector3(8, 8, 8) * voxel_size * 0.5
	head_pivot.add_child(head)
	
	# --- ARMS (4x12x4 voxels) ---
	# Left Arm
	pivot_limb_l_arm = Node3D.new()
	pivot_limb_l_arm.position = Vector3(-0.3, 1.2, 0)
	add_child(pivot_limb_l_arm)
	
	var l_arm = _create_part(Vector3i(4, 12, 4), _color_limb)
	l_arm.position = Vector3(-2, -10, -2) * voxel_size
	pivot_limb_l_arm.add_child(l_arm)
	
	# Right Arm + GREATSWORD
	pivot_limb_r_arm = Node3D.new()
	pivot_limb_r_arm.position = Vector3(0.3, 1.2, 0)
	add_child(pivot_limb_r_arm)
	
	var r_arm = _create_part(Vector3i(4, 12, 4), _color_limb)
	r_arm.position = Vector3(-2, -10, -2) * voxel_size
	pivot_limb_r_arm.add_child(r_arm)
	
	# GREATSWORD (Attached to right arm)
	var sword = _create_part(Vector3i(2, 20, 2), _color_sword)
	sword.position = Vector3(0, -16 * voxel_size, 0)
	pivot_limb_r_arm.add_child(sword)
	
	# --- LEGS (4x12x4 voxels) ---
	# Left Leg
	pivot_limb_l_leg = Node3D.new()
	pivot_limb_l_leg.position = Vector3(-0.12, 0.5, 0)
	add_child(pivot_limb_l_leg)
	
	var l_leg = _create_part(Vector3i(4, 12, 4), _color_limb)
	l_leg.position = Vector3(-2, -10, -2) * voxel_size
	pivot_limb_l_leg.add_child(l_leg)
	
	# Right Leg
	pivot_limb_r_leg = Node3D.new()
	pivot_limb_r_leg.position = Vector3(0.12, 0.5, 0)
	add_child(pivot_limb_r_leg)
	
	var r_leg = _create_part(Vector3i(4, 12, 4), _color_limb)
	r_leg.position = Vector3(-2, -10, -2) * voxel_size
	pivot_limb_r_leg.add_child(r_leg)

# --- Pattern Functions ---

func _color_cape(x, y, z, w, h, d) -> Material:
	return materials["cape"]

func _color_head(x, y, z, w, h, d) -> Material:
	# Visor slit on front
	if z == d-1 and y >= h/2-1 and y <= h/2+1:
		return materials["dark"]
	return materials["armor"]

func _color_torso(x, y, z, w, h, d) -> Material:
	# Create waist taper - narrow in the lower third
	var lower_third = h / 3
	if y < lower_third:
		# Skip outer edges to create waist
		if x <= 1 or x >= w-2 or z <= 1 or z >= d-2:
			return null  # Skip these voxels to create waist
	
	# Chest plate
	return materials["armor"]

func _color_limb(x, y, z, w, h, d) -> Material:
	# Joint in middle
	if y >= h/2 - 1 and y <= h/2 + 1:
		return materials["dark"]
	return materials["armor"]

func _color_sword(x, y, z, w, h, d) -> Material:
	# Blade
	if y > 3:
		return materials["armor"]
	# Handle
	return materials["dark"]

# --- Generation Logic ---

func _create_part(size: Vector3i, color_func: Callable) -> MeshInstance3D:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for x in range(size.x):
		for y in range(size.y):
			for z in range(size.z):
				var mat = color_func.call(x, y, z, size.x, size.y, size.z)
				if mat == null:
					continue  # Skip this voxel for waist taper
				var color = mat.albedo_color
				_add_voxel_face(st, Vector3(x, y, z), color)
	
	st.generate_normals()
	var mesh = st.commit()
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	
	var master_mat = StandardMaterial3D.new()
	master_mat.vertex_color_use_as_albedo = true
	master_mat.metallic = 0.7
	master_mat.roughness = 0.4
	mesh_instance.material_override = master_mat
	
	return mesh_instance

func _add_voxel_face(st: SurfaceTool, pos: Vector3, color: Color):
	var s = voxel_size
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
