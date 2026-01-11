extends Node

# Autoload: PlayerStats
# Tracks player XP, level, and stat multipliers

signal on_level_up(new_level)
signal xp_gained(amount)

var xp: int = 0
var level: int = 1
var xp_to_next_level: int = 100

# Stat Multipliers (Binding of Isaac style)
var damage_mult: float = 1.0
var fire_rate_mult: float = 1.0  # Lower = faster (cooldown reduction)
var shot_speed_mult: float = 1.0
var shot_size_mult: float = 1.0
var melee_size_mult: float = 1.0
var melee_arc_mult: float = 1.0 # Multiplier for swing arc angle
var move_speed_mult: float = 1.0
var max_health_bonus: int = 0

# Fire rate cooldown tracking
var melee_cooldown: float = 0.5
var ranged_cooldown: float = 0.8

func _ready():
	print("PlayerStats initialized")

func add_xp(amount: int):
	xp += amount
	xp_gained.emit(amount)
	print("XP +", amount, " (", xp, "/", xp_to_next_level, ")")
	
	if xp >= xp_to_next_level:
		level_up()

func level_up():
	level += 1
	xp -= xp_to_next_level
	xp_to_next_level = int(xp_to_next_level * 1.5) # Exponential scaling
	
	# Play level up sound
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = load("res://Assets/Audio/SFX/levelup.wav")
	audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
	audio_player.bus = "SFX"
	add_child(audio_player)
	audio_player.play()
	audio_player.finished.connect(audio_player.queue_free)
	
	print("LEVEL UP! Now level ", level)
	on_level_up.emit(level)

func apply_stat_upgrade(stat_name: String, amount: float):
	match stat_name:
		"damage":
			damage_mult += amount
			print("Damage: ", damage_mult, "x")
		"fire_rate":
			fire_rate_mult -= amount # Lower = faster
			if fire_rate_mult < 0.3: fire_rate_mult = 0.3 # Cap
			print("Fire Rate: ", fire_rate_mult, "x cooldown")
		"shot_speed":
			shot_speed_mult += amount
			print("Shot Speed: ", shot_speed_mult, "x")
		"shot_size":
			shot_size_mult += amount
			print("Shot Size: ", shot_size_mult, "x")
		"melee_size":
			melee_size_mult += amount
			print("Melee Size: ", melee_size_mult, "x")
		"melee_arc":
			melee_arc_mult += amount
			print("Melee Arc: ", melee_arc_mult, "x")
		"move_speed":
			move_speed_mult += amount
			print("Move Speed: ", move_speed_mult, "x")
		"max_health":
			max_health_bonus += int(amount)
			print("Max Health: +", max_health_bonus)

func get_melee_cooldown() -> float:
	return melee_cooldown * fire_rate_mult

func get_ranged_cooldown() -> float:
	return ranged_cooldown * fire_rate_mult

func get_base_damage() -> int:
	return int(10 * damage_mult)

# Power-up Logic
func heal_player(amount: int):
	# We don't track current HP here (PlayerController handles it probably?)
	# Checking PlayerController... specific player instances handle their own HP.
	# But UpgradeManager modifies 'max_health_bonus' here.
	# Let's emit a signal that PlayerController can listen to, OR manage current HP here if we migrate.
	# For now, let's emit a signal that players can connect to.
	# Actually, usually 'healed' signal is useful.
	pass # Wait, PlayerStats is Global. 
	# We need to find the players and heal them.
	var players = get_tree().get_nodes_in_group("Player")
	for p in players:
		if p.has_method("heal"):
			p.heal(amount)

signal buff_started(stat_name, duration)
signal buff_ended(stat_name)

func apply_temporary_buff(stat_name: String, amount: float, duration: float):
	print("Applying buff: ", stat_name, " +", amount, " for ", duration, "s")
	# Apply immediately
	match stat_name:
		"damage": damage_mult += amount
		"move_speed": move_speed_mult += amount
		"fire_rate": fire_rate_mult -= amount # Lower is faster
		
	buff_started.emit(stat_name, duration)
		
	# Create timer to revert
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	add_child(timer)
	timer.start()
	
	timer.timeout.connect(func():
		_remove_buff(stat_name, amount)
		timer.queue_free()
	)

func _remove_buff(stat_name: String, amount: float):
	print("Removing buff: ", stat_name)
	match stat_name:
		"damage": damage_mult -= amount
		"move_speed": move_speed_mult -= amount
		"fire_rate": fire_rate_mult += amount
	
	buff_ended.emit(stat_name)
