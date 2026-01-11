extends Area3D

var xp_value: int = 10
var move_speed: float = 8.0
var attraction_radius: float = 5.0
var player: Node3D = null

func _ready():
	# Connect to both body_entered and area_entered for flexibility
	body_entered.connect(_on_body_entered)
	
	# Create visual
	var mesh = MeshInstance3D.new()
	mesh.mesh = SphereMesh.new()
	mesh.mesh.radius = 0.15
	mesh.mesh.height = 0.3
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 1.0) # Cyan
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.8, 1.0)
	mat.emission_energy_multiplier = 2.0
	mesh.material_override = mat
	add_child(mesh)
	
	# Collision - make it bigger for easier collection
	var col = CollisionShape3D.new()
	col.shape = SphereShape3D.new()
	col.shape.radius = 0.4
	add_child(col)
	
	# Find player
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
		print("XPOrb found player: ", player.name)
	else:
		print("XPOrb: No player found in 'Player' group!")

func _physics_process(delta):
	if player:
		var dist = global_position.distance_to(player.global_position)
		
		# Move toward player if close enough
		if dist < attraction_radius:
			var dir = (player.global_position - global_position).normalized()
			global_position += dir * move_speed * delta

func _on_body_entered(body):
	# Check if it's the player by group or class
	if body.is_in_group("Player") or body is PlayerController3D:
		# Award XP
		PlayerStats.add_xp(xp_value)
		queue_free()

func setup(pos: Vector3, value: int):
	global_position = pos
	xp_value = value
