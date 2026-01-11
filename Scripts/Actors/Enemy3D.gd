extends CharacterBody3D
class_name Enemy3D

@export var max_health: int = 20
@export var damage: int = 10
@export var speed: float = 3.0

var current_health: int
var target: Node3D = null
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var enemy_type: String = ""  # Store enemy type for sound selection
var knockback_velocity: Vector3 = Vector3.ZERO
var knockback_decay: float = 12.0

func _ready():
	current_health = max_health
	add_to_group("Enemy")
	
	# Find player
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		target = players[0]
		
	# Setup Visuals
	_setup_visuals_recursive(self)

func _setup_visuals_recursive(node: Node):
	if node is MeshInstance3D:
		var mat = node.material_override if node.material_override else node.mesh.surface_get_material(0)
		if mat is StandardMaterial3D:
			mat = mat.duplicate()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			# Slight tint to distinguish from terrain?
			# mat.albedo_color *= 0.8 
			node.material_override = mat
		elif mat == null:
			var new_mat = StandardMaterial3D.new()
			new_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			new_mat.albedo_color = Color(1, 0, 0) # Error red if no material
			node.material_override = new_mat
			
	for child in node.get_children():
		_setup_visuals_recursive(child)

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	# 2. MOVEMENT LOGIC
	# Priority: Knockback > Normal Movement
	
	if knockback_velocity.length() > 0.5:
		velocity.x = knockback_velocity.x
		velocity.z = knockback_velocity.z
		# Decay knockback
		knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, knockback_decay * delta)
		
	elif target:
		var dir = (target.global_position - global_position)
		dir.y = 0 # Don't fly
		
		if dir.length() > 0.5:
			dir = dir.normalized()
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
			
			var target_angle = atan2(dir.x, dir.z)
			rotation.y = lerp_angle(rotation.y, target_angle, 10 * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
		
	move_and_slide()
	
	# Collision Damage & Bounce
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider.is_in_group("Player"):
			# Damage Player
			if collider.has_method("take_damage"):
				collider.take_damage(damage)
			
			# Bounce off player (prevent sticking)
			var bounce_dir = (global_position - collider.global_position).normalized()
			bounce_dir.y = 0
			knockback_velocity = bounce_dir * 5.0 # Small bounce

func apply_knockback(force: Vector3):
	knockback_velocity += force

func take_damage(amount: int, knockback_source: Vector3 = Vector3.ZERO):
	current_health -= amount
	
	# Show damage number
	if GameManager and GameManager.has_method("spawn_damage_number"):
		GameManager.spawn_damage_number(global_position, amount, Color(1.0, 0.5, 0.5)) # Red for enemies
	
	# Knockback
	var source = knockback_source
	if source == Vector3.ZERO and target: source = target.global_position
	
	if source != Vector3.ZERO:
		var dir = (global_position - source).normalized()
		# Vertical Pop (Applied directly to velocity.y once)
		velocity.y = 4.0 
		# Horizontal Knockback (Stored for override)
		dir.y = 0 
		knockback_velocity = dir * 8.0 # Strong initial horizontal push
	
	_spawn_hit_particles()
	
	if current_health <= 0:
		die()

func die():
	# Play death sound based on enemy type
	var death_sound: AudioStream = null
	# Check enemy type (set when spawned)
	if enemy_type == "snake":
		death_sound = load("res://Assets/Audio/SFX/hiss-snake.mp3")
	else:  # All other critters (Squirrel, Badger, Knight)
		death_sound = load("res://Assets/Audio/SFX/squeak_critters.mp3")
	
	if death_sound:
		var audio_player = AudioStreamPlayer.new()
		audio_player.stream = death_sound
		audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
		audio_player.bus = "SFX"
		get_parent().add_child(audio_player)
		audio_player.play()
		audio_player.finished.connect(audio_player.queue_free)
	
	# Spawn XP orbs based on enemy type
	var xp_amount = 30  # Base XP (was 10)
	if max_health >= 100:
		xp_amount = 75  # Tanky enemies give more (was 25)
	
	var orb = load("res://Scripts/Actors/XPOrb.gd").new()
	orb.set_script(load("res://Scripts/Actors/XPOrb.gd"))
	get_parent().add_child(orb)
	orb.setup(global_position + Vector3(0, 0.5, 0), xp_amount)
	
	# Death particles
	for i in range(3):
		_spawn_hit_particles()
	queue_free()

func _spawn_hit_particles():
	var world = get_tree().get_first_node_in_group("VoxelWorld")
	if world and world.has_method("spawn_debris"):
		world.spawn_debris(global_position + Vector3(0, 0.5, 0), Color.RED)
