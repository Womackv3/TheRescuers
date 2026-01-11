extends Control

@onready var progress = $TextureProgressBar
@onready var icon = $Icon

var total_time: float = 1.0
var time_left: float = 1.0

func setup(stat_name: String, duration: float):
	total_time = duration
	time_left = duration
	
	# Icon color/texture based on stat
	var color = Color.WHITE
	match stat_name:
		"damage": color = Color(0.8, 0.2, 1.0) # Purple
		"move_speed": color = Color(1.0, 1.0, 0.2) # Yellow
		"fire_rate": color = Color(1.0, 0.5, 0.0) # Orange
		
	icon.modulate = color
	progress.max_value = duration
	progress.value = duration
	progress.tint_progress = color

func _process(delta):
	time_left -= delta
	progress.value = time_left
	
	if time_left <= 0:
		queue_free()
