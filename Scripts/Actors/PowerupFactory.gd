extends Node
class_name PowerupFactory

static func create_powerup(type: Pickup.PickupType) -> Pickup:
	var pickup = Pickup.new()
	pickup.type = type
	pickup.set_script(load("res://Scripts/Actors/Pickup.gd")) # Ensure script is attached
	
	# Create visual mesh
	var mesh_inst = MeshInstance3D.new()
	var mesh = BoxMesh.new() # Default
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED # Bright/Glowy
	
	match type:
		Pickup.PickupType.HEALTH:
			# Red Heart-ish (Box for now or sphere)
			mesh = SphereMesh.new()
			mesh.radius = 0.25; mesh.height = 0.5
			mat.albedo_color = Color(1.0, 0.2, 0.2) # Red
			pickup.value = 25 # Heal 25 HP
			pickup.duration = 0
			
		Pickup.PickupType.DAMAGE:
			# Purple Sword/Power icon
			mesh = BoxMesh.new()
			mesh.size = Vector3(0.4, 0.4, 0.4)
			mat.albedo_color = Color(0.8, 0.2, 1.0) # Purple
			pickup.value = 0.5 # +50% Damage mult
			pickup.duration = 10.0 # 10s
			
		Pickup.PickupType.SPEED:
			# Yellow Bolt/Shoe
			mesh = PrismMesh.new() # Arrow-ish
			mesh.size = Vector3(0.4, 0.4, 0.1)
			mat.albedo_color = Color(1.0, 1.0, 0.2) # Yellow
			pickup.value = 0.3 # +30% Speed
			pickup.duration = 10.0
	
	mesh_inst.mesh = mesh
	mesh_inst.material_override = mat
	pickup.add_child(mesh_inst)
	
	# Add light
	var light = OmniLight3D.new()
	light.light_color = mat.albedo_color
	light.light_energy = 1.0
	light.omni_range = 3.0
	pickup.add_child(light)
	
	return pickup
