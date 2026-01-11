extends CharacterBody3D
class_name PlayerController3D

# Preload SFX
var sfx_footstep = preload("res://Assets/Audio/SFX/grass-step.wav")
var sfx_sword_hit = preload("res://Assets/Audio/SFX/sword.mp3")
var sfx_arrow = preload("res://Assets/Audio/SFX/arrow.wav")

@export var player_index: int = 1 # 1 or 2
@export var base_speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.005

var speed: float = 5.0 # Actual speed (modified by stats)

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var visuals = $VoxelGreatswordKnightVisuals2
@onready var camera = $Camera3D

var camera_pivot: Node3D
var is_rotating_camera: bool = false

# Attack cooldowns
var melee_cooldown: float = 0.0
var ranged_cooldown: float = 0.0
var base_melee_rate: float = 1.5  # Attacks per second (was 0.5)
var base_ranged_rate: float = 0.9  # Attacks per second (was 0.3)
var is_melee_held: bool = false
var is_ranged_held: bool = false

func _ready():
	# Add to Player group for detection
	add_to_group("Player")
	
	# Create a pivot for the camera to orbit around
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	add_child(camera_pivot)
	# Default pivot position is player center (0,0,0)
	
	# Hide old VoxelKnightVisuals if it exists
	if has_node("VoxelKnightVisuals"):
		var old_visuals = get_node("VoxelKnightVisuals")
		old_visuals.visible = false
	
	# Create procedural greatsword knight visuals if not already in scene
	if not has_node("VoxelGreatswordKnightVisuals2"):
		var GreatswordKnightScript = load("res://Scripts/Actors/VoxelGreatswordKnightVisuals2.gd")
		var knight_visuals = Node3D.new()
		knight_visuals.name = "VoxelGreatswordKnightVisuals2"
		knight_visuals.set_script(GreatswordKnightScript)
		knight_visuals.position.y = -0.5 # Align feet with bottom of capsule (height 1.0)
		add_child(knight_visuals)
		visuals = knight_visuals
	
	# 2. Reparent Camera to Pivot
	var camera = get_node_or_null("Camera3D")
	if camera:
		remove_child(camera)
		camera_pivot.add_child(camera)
		camera.position = Vector3(0, 12.0, 12.0) # Offset from pivot (isometric view)
		camera.look_at(camera_pivot.global_position, Vector3.UP)
	
	# 3. Add player light for dusk visibility
	var player_light = OmniLight3D.new()
	player_light.name = "PlayerLight"
	player_light.light_energy = 1.5
	player_light.light_color = Color(1.0, 0.9, 0.7) # Warm torch-like color
	player_light.omni_range = 8.0 # Illuminates nearby area
	player_light.omni_attenuation = 2.0 # Natural falloff
	player_light.shadow_enabled = false # No shadows from player light for performance
	add_child(player_light)
	player_light.position = Vector3(0, 1.0, 0) # At player height
	
	# Initial position setup
	camera.reparent(camera_pivot)
	# (Light removal matches previous state)

	# ... (Sound setup)
	
	
	# Add SFX audio players
	var footstep_player = AudioStreamPlayer.new()
	footstep_player.name = "FootstepPlayer"
	footstep_player.bus = "SFX"
	footstep_player.volume_db = -10  # Quieter footsteps
	add_child(footstep_player)
	
	var combat_player = AudioStreamPlayer.new()
	combat_player.name = "CombatPlayer"
	combat_player.bus = "SFX"
	combat_player.volume_db = -6  # 50% quieter
	add_child(combat_player)
	
	# Initialize Health
	current_health = get_max_health()
	print("Player initialized with ", current_health, " HP")

# Health System
signal health_changed(current, max_hp)
signal on_death

var current_health: int = 100
var is_dead: bool = false
var is_god_mode: bool = false # Dev Console

# Invulnerability
const IFRAME_DURATION: float = 1.0
var invulnerability_timer: float = 0.0

func get_max_health() -> int:
	var base = 100
	var stats = CharacterDB.get_character("ray") # Hardcoded for now
	if stats:
		base = stats.base_health
	return base + PlayerStats.max_health_bonus

func take_damage(amount: int):
	if is_dead: return
	if is_god_mode: return # God Mode Protection
	if invulnerability_timer > 0: return # iFrame check
	
	current_health -= amount
	print("Player took ", amount, " damage! HP: ", current_health)
	health_changed.emit(current_health, get_max_health())
	
	# Start iFrames
	invulnerability_timer = IFRAME_DURATION
	_start_iframe_visuals()
	
	if current_health <= 0:
		die()

func heal(amount: int):
	if is_dead: return
	current_health += amount
	if current_health > get_max_health():
		current_health = get_max_health()
	print("Player healed ", amount, ". HP: ", current_health)
	health_changed.emit(current_health, get_max_health())
	
	# Visual feedback
	var tw = create_tween()
	tw.tween_property(visuals, "scale", Vector3(1.2, 1.2, 1.2), 0.1)
	tw.tween_property(visuals, "scale", Vector3(1.0, 1.0, 1.0), 0.1)

func die():
	is_dead = true
	on_death.emit()
	print("PLAYER DIED")
	# Temporary: Reload scene after delay
	set_physics_process(false)
	var t = get_tree().create_timer(2.0)
	t.timeout.connect(func(): get_tree().reload_current_scene())

func _start_iframe_visuals():
	# Flash opacity/tint for IFRAME_DURATION
	var tween = create_tween()
	tween.set_loops(5) # Flash 5 times
	# Flash Red/Transparent
	tween.tween_property(visuals, "scale", Vector3(1.1, 1.1, 1.1), 0.1)
	tween.parallel().tween_property(visuals, "visible", false, 0.1) # Flicker opacity
	tween.tween_property(visuals, "scale", Vector3(1.0, 1.0, 1.0), 0.1)
	tween.parallel().tween_property(visuals, "visible", true, 0.1)
	
	# Ensure visibility is reset at end
	tween.finished.connect(func(): visuals.visible = true)

func _unhandled_input(event):
	# Camera Orbit Logic
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE: # Moved to Middle Mouse to free Right Click
			is_rotating_camera = event.pressed
			
		# Combat Inputs (Mouse) - Track held state
		if player_index == 1: # Only P1 uses keyboard/mouse usually
			if event.button_index == MOUSE_BUTTON_LEFT:
				is_melee_held = event.pressed
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				is_ranged_held = event.pressed
			
	if event is InputEventMouseMotion and is_rotating_camera:
		# Rotate pivot around Y axis (Yaw)
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)

func _physics_process(delta):
	# Update iFrames
	if invulnerability_timer > 0:
		invulnerability_timer -= delta
	# Update attack cooldowns
	if melee_cooldown > 0:
		melee_cooldown -= delta
	if ranged_cooldown > 0:
		ranged_cooldown -= delta
	
	# Handle held attacks
	if is_melee_held and melee_cooldown <= 0:
		_melee_attack()
		var fire_rate = base_melee_rate * PlayerStats.fire_rate_mult
		melee_cooldown = 1.0 / fire_rate
	
	if is_ranged_held and ranged_cooldown <= 0:
		_ranged_attack()
		var fire_rate = base_ranged_rate * PlayerStats.fire_rate_mult
		ranged_cooldown = 1.0 / fire_rate
	
	# Update speed from PlayerStats
	speed = base_speed * PlayerStats.move_speed_mult
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump: Check Physical Key directly to avoid Action Map conflicts
	if Input.is_physical_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = jump_velocity

	# Handle Input
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed(_action("move_right")): input_dir.x += 1
	if Input.is_action_pressed(_action("move_left")): input_dir.x -= 1
	if Input.is_action_pressed(_action("move_down")): input_dir.y += 1
	if Input.is_action_pressed(_action("move_up")): input_dir.y -= 1
	
	# Determine direction RELATIVE to Camera Pivot
	var direction = Vector3.ZERO
	if input_dir.length() > 0:
		# Forward (Up) is -Z in Godot
		var cam_basis = camera_pivot.global_transform.basis
		var forward = -cam_basis.z
		var right = cam_basis.x
		
		# Flatten to horizontal plane (we don't want to walk into the ground)
		forward.y = 0
		right.y = 0
		forward = forward.normalized()
		right = right.normalized()
		
		direction = (forward * -input_dir.y) + (right * input_dir.x)
		direction = direction.normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	# Rotate character to face mouse cursor
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.unproject_position(global_position)
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	
	# Raycast to find where mouse points in 3D space
	var plane = Plane(Vector3.UP, global_position.y)
	var intersection = plane.intersects_ray(ray_origin, ray_dir)
	
	if intersection:
		var look_dir = intersection - global_position
		look_dir.y = 0
		if look_dir.length() > 0.1:
			var target_angle = atan2(look_dir.x, look_dir.z)
			visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, 15 * delta)
		
	move_and_slide()
	
	# Push Enemies we walk into
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider.is_in_group("Enemy") and collider.has_method("apply_knockback"):
			var push_dir = -col.get_normal()
			push_dir.y = 0
			# Apply push force
			collider.apply_knockback(push_dir * 2.0)
	
	# Dynamic Voxel Lighting
	var voxel_world = get_tree().get_first_node_in_group("VoxelWorld")
	if voxel_world:
		var grid_pos = Vector3i(floor(global_position.x), floor(global_position.y), floor(global_position.z))
		
		# 1. Emit Light
		if voxel_world.has_method("set_light"):
			voxel_world.set_light(grid_pos.x, grid_pos.y, grid_pos.z, 13)
			voxel_world.set_light(grid_pos.x, grid_pos.y + 1, grid_pos.z, 13)
		
		# 2. Receive Light (Color Player)
		var light_level = 1.0
		if voxel_world.get("light_map") and voxel_world.light_map.has(grid_pos):
			var lvl = voxel_world.light_map[grid_pos]
			light_level = max(0.05, float(lvl) / 15.0)
		
		# Modulate visuals
		if visuals:
			_modulate_hierarchy(visuals, Color(light_level, light_level, light_level))

	# Lantern Sway Logic (Legacy - Lamp removed but script logic kept for now or safe removal)
	# var lamp = visuals.get_node_or_null("HipLamp") 
	# ... (Sway logic handled by visual hierarchy if lamp existed, but it's gone)
	
func _modulate_hierarchy(node: Node, color: Color):
	if node is MeshInstance3D:
		if node.material_override is StandardMaterial3D:
			node.material_override.albedo_color = color
	
	for child in node.get_children():
		_modulate_hierarchy(child, color)
		



func _action(name: String) -> String:
	var prefix = "p1_" if player_index == 1 else "p2_"
	if name == "jump": return "" 
	return prefix + name

func _ranged_attack() -> void:
	# Get stats
	var stats = CharacterDB.get_character("ray") # Hardcoded for prototype, should hold 'current_character_id'
	if not stats or stats.ranged_type == CharacterStats.WeaponType.NONE:
		return
		
	# Spawn Projectile
	var proj_script = load("res://Scripts/Actors/Projectile.gd")
	var proj = proj_script.new()
	get_parent().add_child(proj) # Add to world
	
	# Position: In front of player
	var fwd = visuals.global_transform.basis.z # Positive Z is forward for this model
	var start_pos = global_position + Vector3(0, 0.5, 0) + fwd * 0.8 # approx 0.8
	
	proj.setup(start_pos, fwd, stats.ranged_type, stats.base_attack)
	
	# Play arrow sound
	var combat_player = get_node_or_null("CombatPlayer")
	if combat_player:
		combat_player.stream = sfx_arrow
		combat_player.play()

func _melee_attack() -> void:
	var stats = CharacterDB.get_character("ray")
	if not stats or stats.melee_type == CharacterStats.WeaponType.NONE:
		return
	
	# Play sword swing sound
	var combat_player = get_node_or_null("CombatPlayer")
	if combat_player:
		combat_player.stream = sfx_sword_hit
		combat_player.play()
		
	# Visual: Swipe
	_spawn_sword_swipe()
	
	# Logic: Wide Arc Hit Detection
	var fwd = visuals.global_transform.basis.z 
	var right = visuals.global_transform.basis.x
	var dmg = int(stats.base_attack * PlayerStats.damage_mult)
	
	# 1. Physics Check (Wide Box for Enemies)
	var space_state = get_world_3d().direct_space_state
	# Center the box in front of player
	var sweep_pos = global_position + Vector3(0, 0.5, 0) + fwd * 1.0
	
	var query = PhysicsShapeQueryParameters3D.new()
	var box = BoxShape3D.new()
	# Wide X (2.0), Thin Z (1.5), Height (1.0)
	# Apply Melee Size Multiplier
	var multi = PlayerStats.melee_size_mult
	# Arc/Shape affects width? For box check, size covers it.
	# Let's say Arc widens the box X.
	var arc_mod = PlayerStats.melee_arc_mult
	box.size = Vector3(2.5 * multi * arc_mod, 1.0, 1.5 * multi)
	
	query.shape = box
	query.transform = Transform3D(visuals.global_transform.basis, sweep_pos) # Align rotation with player
	query.collision_mask = 1 | 2 # Adjust based on your layers
	
	var results = space_state.intersect_shape(query)
	var hit_something = false
	
	for result in results:
		var collider = result.collider
		if collider and collider != self: # Don't hit self
			if collider.has_method("take_damage"):
				# Pass player position as source of knockback
				collider.take_damage(dmg, global_position)
				hit_something = true
				print("Melee Cleave Hit: ", collider.name)
	
	# 2. Voxel Grid Check (Arc Cleave)
	# Check 3 points: Left, Center, Right
	var world = get_tree().get_first_node_in_group("VoxelWorld")
	if world:
		var arc_points = [
			global_position + Vector3(0, 0.5, 0) + fwd * 1.0, # Center
			global_position + Vector3(0, 0.5, 0) + fwd * 0.8 + right * 0.8, # Right
			global_position + Vector3(0, 0.5, 0) + fwd * 0.8 - right * 0.8  # Left
		]
		
		for p in arc_points:
			var gx = int(round(p.x / world.block_size))
			var gy = int(round(p.y / world.block_size))
			var gz = int(round(p.z / world.block_size))
			
			if world.damage_block(Vector3i(gx, gy, gz), dmg):
				print("Cleaved Block at ", Vector3i(gx, gy, gz))
				hit_something = true
			elif world.damage_block(Vector3i(gx, gy-1, gz), dmg): # Check below too
				print("Cleaved Block Below")
				hit_something = true

func _spawn_sword_swipe():
	var sword_pivot = VoxelWeaponFactory.create_sword()
	add_child(sword_pivot)
	
	# Attach near player center (shoulder height)
	sword_pivot.position = Vector3(0, 0.8, 0) # Shoulder height
	sword_pivot.rotation = visuals.rotation # Align with player facing
	
	# Starting Pose: Held back to the RIGHT
	# Rotate Pivot: -45 Y (Right)
	# Scale start angle by arc mult
	var arc_scale = PlayerStats.melee_arc_mult
	sword_pivot.rotation.y -= deg_to_rad(60 * arc_scale)
	
	# Sword Offset from pivot: Extended out
	var sword_mesh = sword_pivot.get_child(0)
	if sword_mesh:
		sword_mesh.position = Vector3(0, 0, 1.0) # Radius of swing
		sword_mesh.rotation.y = deg_to_rad(-90) # Point blade out
		sword_mesh.rotation.x = deg_to_rad(90)  # Flat swing
		# Apply Size Multiplier
		sword_mesh.scale = Vector3.ONE * PlayerStats.melee_size_mult
	
	var tween = create_tween()
	# Swing Arc: Rotate pivot from Right to Left
	# Total arc: ~120 degrees * arc_scale
	# Tween duration: Scaled by fire rate (Lower = Faster)
	# Base duration: 0.25 (fast swing)
	var swing_duration = 0.25 * PlayerStats.fire_rate_mult
	tween.tween_property(sword_pivot, "rotation:y", sword_pivot.rotation.y + deg_to_rad(140 * arc_scale), swing_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# Cleanup
	tween.tween_callback(sword_pivot.queue_free)
