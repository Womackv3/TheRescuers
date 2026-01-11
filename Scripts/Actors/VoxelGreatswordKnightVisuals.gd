extends Node3D

# Greatsword Knight - Optimized voxel character with animation
# Converted from knightgreatsword_45x100x50.py (8807 voxels)

@export var speed: float = 10.0
@export var limb_max_angle: float = 45.0
@export var voxel_size: float = 0.05  # Increased to match enemy scale

var materials = {}

# Animation pivots
var pivot_limb_l_arm: Node3D
var pivot_limb_r_arm: Node3D
var pivot_limb_l_leg: Node3D
var pivot_limb_r_leg: Node3D
var pivot_torso: Node3D
var pivot_head: Node3D

# Voxel data (will be loaded from Python file)
var voxel_data = []

func _ready():
	_init_materials()
	_load_voxel_data()
	_build_character()

func _process(delta):
	_animate(delta)

func _init_materials():
	# Silver/Gray armor material - brighter for visibility
	var mat_armor = StandardMaterial3D.new()
	mat_armor.albedo_color = Color(0.85, 0.85, 0.85)  # Brighter gray
	mat_armor.metallic = 0.6
	mat_armor.roughness = 0.5
	materials["armor"] = mat_armor

func _load_voxel_data():
	# Load and parse the Python voxel file
	var file_path = "res://Assets/Sprites/knightgreatsword_15x32x16.py"  # New smaller model
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		push_error("Could not load voxel data from: " + file_path)
		return
	
	var content = file.get_as_text()
	file.close()
	
	# Parse the lookup array (simple regex-free parsing)
	var in_lookup = false
	for line in content.split("\n"):
		if "lookup = [" in line:
			in_lookup = true
			continue
		if in_lookup:
			if "]" in line and "}" not in line:
				break
			# Parse lines like: { 'x': 19, 'y': 58, 'z':  0, 'color': 0 },
			if "'x':" in line:
				var x_start = line.find("'x':") + 5
				var x_end = line.find(",", x_start)
				var x = line.substr(x_start, x_end - x_start).strip_edges().to_int()
				
				var y_start = line.find("'y':") + 5
				var y_end = line.find(",", y_start)
				var y = line.substr(y_start, y_end - y_start).strip_edges().to_int()
				
				var z_start = line.find("'z':") + 5
				var z_end = line.find(",", z_start)
				var z = line.substr(z_start, z_end - z_start).strip_edges().to_int()
				
				voxel_data.append(Vector3i(x, y, z))
	
	print("Loaded ", voxel_data.size(), " voxels for Greatsword Knight")

func _build_character():
	if voxel_data.is_empty():
		push_error("No voxel data loaded!")
		return
	
	# Model is 15x32x16 (width x height x depth)
	# Y ranges: 0-31 (32 voxels tall)
	# Approximate breakdown: legs 0-10, torso 10-22, arms 12-20, head 22-31
	# Cape: likely at back (high Z values) attached to torso
	
	# Separate voxels by body part based on Y height and X position
	var head_voxels = []
	var torso_voxels = []
	var l_arm_voxels = []
	var r_arm_voxels = []
	var l_leg_voxels = []
	var r_leg_voxels = []
	
	for voxel in voxel_data:
		var x = voxel.x
		var y = voxel.y
		var z = voxel.z
		
		# Head: y >= 22
		if y >= 22:
			head_voxels.append(voxel)
		# Arms: y 12-22, x at extremes (left < 4 or right > 10)
		elif y >= 12 and y < 22:
			if x < 4:  # Left arm
				l_arm_voxels.append(voxel)
			elif x > 10:  # Right arm
				r_arm_voxels.append(voxel)
			else:  # Center = torso (includes cape at back)
				torso_voxels.append(voxel)
		# Torso: y 10-22, center (includes cape)
		elif y >= 10 and y < 22:
			torso_voxels.append(voxel)
		# Legs: y < 10
		else:
			if x < 7:  # Left leg
				l_leg_voxels.append(voxel)
			else:  # Right leg
				r_leg_voxels.append(voxel)
	
	# Create animation pivots
	pivot_torso = Node3D.new()
	pivot_torso.position.y = 0.5  # Mid torso
	add_child(pivot_torso)
	
	pivot_head = Node3D.new()
	pivot_head.position.y = 1.1  # Top of torso
	add_child(pivot_head)
	
	pivot_limb_l_arm = Node3D.new()
	pivot_limb_l_arm.position = Vector3(-0.15, 0.8, 0)  # Left shoulder
	add_child(pivot_limb_l_arm)
	
	pivot_limb_r_arm = Node3D.new()
	pivot_limb_r_arm.position = Vector3(0.15, 0.8, 0)  # Right shoulder
	add_child(pivot_limb_r_arm)
	
	pivot_limb_l_leg = Node3D.new()
	pivot_limb_l_leg.position = Vector3(-0.08, 0.5, 0)  # Left hip
	add_child(pivot_limb_l_leg)
	
	pivot_limb_r_leg = Node3D.new()
	pivot_limb_r_leg.position = Vector3(0.08, 0.5, 0)  # Right hip
	add_child(pivot_limb_r_leg)
	
	# Build meshes for each part
	if not head_voxels.is_empty():
		var head_mesh = _create_mesh_from_voxels(head_voxels, Vector3(7, 27, 8))
		head_mesh.position = Vector3(-0.07, -0.27, -0.08) * voxel_size
		pivot_head.add_child(head_mesh)
	
	if not torso_voxels.is_empty():
		# Torso includes cape voxels
		var torso_mesh = _create_mesh_from_voxels(torso_voxels, Vector3(7, 16, 8))
		torso_mesh.position = Vector3(-0.07, -0.16, -0.08) * voxel_size
		pivot_torso.add_child(torso_mesh)
	
	if not l_arm_voxels.is_empty():
		var l_arm_mesh = _create_mesh_from_voxels(l_arm_voxels, Vector3(2, 17, 8))
		l_arm_mesh.position = Vector3(-0.02, -0.17, -0.08) * voxel_size
		pivot_limb_l_arm.add_child(l_arm_mesh)
	
	if not r_arm_voxels.is_empty():
		var r_arm_mesh = _create_mesh_from_voxels(r_arm_voxels, Vector3(12, 17, 8))
		r_arm_mesh.position = Vector3(-0.12, -0.17, -0.08) * voxel_size
		pivot_limb_r_arm.add_child(r_arm_mesh)
	
	if not l_leg_voxels.is_empty():
		var l_leg_mesh = _create_mesh_from_voxels(l_leg_voxels, Vector3(3.5, 5, 8))
		l_leg_mesh.position = Vector3(-0.035, -0.05, -0.08) * voxel_size
		pivot_limb_l_leg.add_child(l_leg_mesh)
	
	if not r_leg_voxels.is_empty():
		var r_leg_mesh = _create_mesh_from_voxels(r_leg_voxels, Vector3(10.5, 5, 8))
		r_leg_mesh.position = Vector3(-0.105, -0.05, -0.08) * voxel_size
		pivot_limb_r_leg.add_child(r_leg_mesh)
	
	print("Greatsword Knight built with ", voxel_data.size(), " voxels (animated with cape)")

func _create_mesh_from_voxels(voxels: Array, center_offset: Vector3) -> MeshInstance3D:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Use solid color instead of vertex colors to avoid noise
	var color = materials["armor"].albedo_color
	
	for voxel in voxels:
		var pos = Vector3(voxel.x, voxel.y, voxel.z) - center_offset
		_add_voxel_cube(st, pos, color)
	
	st.generate_normals()
	var mesh = st.commit()
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	
	# Don't use vertex_color_use_as_albedo - causes salt/pepper effect
	mesh_instance.material_override = materials["armor"]
	
	return mesh_instance

func _add_voxel_cube(st: SurfaceTool, pos: Vector3, color: Color):
	var s = voxel_size
	pos *= s
	
	# DON'T set vertex colors - causes salt/pepper noise
	# The material will handle the color
	
	var v = [
		Vector3(0,0,0), Vector3(s,0,0), Vector3(s,0,s), Vector3(0,0,s),
		Vector3(0,s,0), Vector3(s,s,0), Vector3(s,s,s), Vector3(0,s,s)
	]
	for i in range(8): v[i] += pos
	
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
