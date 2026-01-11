extends Node3D

var is_falling: bool = false
var falling_rigid_body: RigidBody3D

func trigger_fall(hit_pos: Vector3, damage_source_pos: Vector3):
	if is_falling: return
	is_falling = true
	
	# Create a RigidBody to handle the physics
	falling_rigid_body = RigidBody3D.new()
	falling_rigid_body.mass = 5.0
	falling_rigid_body.collision_layer = 0 # Don't collide with player while falling to avoid craziness
	falling_rigid_body.collision_mask = 1 # Collide with floor
	
	# Add to scene
	get_parent().add_child(falling_rigid_body)
	falling_rigid_body.global_position = global_position
	
	# Reparent all children (voxels) to the RigidBody
	var children = get_children()
	for child in children:
		var old_global_pos = child.global_position
		remove_child(child)
		falling_rigid_body.add_child(child)
		child.global_position = old_global_pos
		
		# Disable further destruction/collision logic on the individual voxels
		for sub_child in child.get_children():
			if sub_child.has_method("die"): # SmallDestructible
				sub_child.set_process(false)
				sub_child.set_physics_process(false)
				# Optional: remove script or disable collision
				if sub_child is StaticBody3D:
					sub_child.collision_layer = 0
					sub_child.collision_mask = 0
	
	# Small initial push
	var push_dir = (global_position - damage_source_pos).normalized()
	push_dir.y = 0.2 # Slight upward tilt
	falling_rigid_body.apply_impulse(push_dir * 5.0, hit_pos - global_position)
	
	# Cleanup timer
	var timer = get_tree().create_timer(5.0)
	timer.timeout.connect(_on_cleanup)

func _on_cleanup():
	if falling_rigid_body:
		falling_rigid_body.queue_free()
	queue_free()
