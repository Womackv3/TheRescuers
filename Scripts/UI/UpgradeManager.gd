extends Node

# Autoload: UpgradeManager

signal upgrade_selected(upgrade_name)
signal upgrade_choices_ready(choices)

var upgrade_pool = [
	{
		"id": "damage",
		"name": "Damage Up",
		"description": "+20% Damage",
		"stat": "damage",
		"amount": 0.2
	},
	{
		"id": "fire_rate",
		"name": "Fire Rate Up",
		"description": "+15% Fire Rate",
		"stat": "fire_rate",
		"amount": 0.15
	},
	{
		"id": "shot_speed",
		"name": "Shot Speed Up",
		"description": "+25% Projectile Speed",
		"stat": "shot_speed",
		"amount": 0.25
	},
	{
		"id": "shot_size",
		"name": "Shot Size Up",
		"description": "+30% Projectile Size",
		"stat": "shot_size",
		"amount": 0.3
	},
	{
		"id": "melee_size",
		"name": "Sword Size Up",
		"description": "+30% Melee Area",
		"stat": "melee_size",
		"amount": 0.3
	},
	{
		"id": "move_speed",
		"name": "Speed Up",
		"description": "+10% Movement Speed",
		"stat": "move_speed",
		"amount": 0.1
	},
	{
		"id": "max_health",
		"name": "Health Up",
		"description": "+20 Max HP",
		"stat": "max_health",
		"amount": 20
	}
]

var current_choices = []

func _ready():
	PlayerStats.on_level_up.connect(_on_level_up)

func _on_level_up(new_level):
	print("UpgradeManager: Level up to ", new_level)
	show_upgrade_choices()

func show_upgrade_choices():
	# Play Upgrade Music
	var bgm = get_tree().get_first_node_in_group("BackgroundMusic")
	if bgm:
		bgm.play_music("res://Assets/Audio/Music/FunkPauseUpgrade.mp3")

	# Slow down time for dramatic effect
	Engine.time_scale = 0.3
	
	# Pause game
	get_tree().paused = true
	
	# Pick 3 random upgrades
	current_choices = []
	var pool_copy = upgrade_pool.duplicate()
	pool_copy.shuffle()
	
	for i in range(min(3, pool_copy.size())):
		current_choices.append(pool_copy[i])
	
	# Emit signal for UI
	upgrade_choices_ready.emit(current_choices)

func select_upgrade(index: int):
	if index < 0 or index >= current_choices.size():
		return
		
	var upgrade = current_choices[index]
	PlayerStats.apply_stat_upgrade(upgrade.stat, upgrade.amount)
	
	upgrade_selected.emit(upgrade.name)
	
	# Restore Music
	var bgm = get_tree().get_first_node_in_group("BackgroundMusic")
	if bgm:
		bgm.resume_main_theme()
	
	# Restore time scale
	Engine.time_scale = 1.0
	
	# Resume game
	get_tree().paused = false
	current_choices = []

