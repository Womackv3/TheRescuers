extends Area3D

# Detects when player enters/exits a building and hides/shows the roof

var roof_voxels = []
var building_id: String = ""

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func setup(building_name: String, roof_blocks: Array):
	building_id = building_name
	roof_voxels = roof_blocks

func _on_body_entered(body):
	if body.is_in_group("Player"):
		# Hide roof
		for voxel in roof_voxels:
			if is_instance_valid(voxel):
				voxel.visible = false

func _on_body_exited(body):
	if body.is_in_group("Player"):
		# Show roof
		for voxel in roof_voxels:
			if is_instance_valid(voxel):
				voxel.visible = true
