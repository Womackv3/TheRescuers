extends CanvasLayer

@export var health_bar: TextureProgressBar
@export var xp_orb: TextureProgressBar
@export var buff_container: Container
@export var toast_label: Label

var buff_icon_scene = preload("res://Scenes/UI/BuffIcon.tscn")
var active_buffs = {}

func _ready() -> void:
	# Connect to Player Signals
	# Wait for player to exist
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		var p = players[0]
		if p.has_signal("health_changed"):
			p.health_changed.connect(_on_health_changed)
			# Init health
			if p.has_method("get_max_health"):
				health_bar.max_value = p.get_max_health()
				health_bar.value = p.current_health
	
	# Connect to PlayerStats (Global)
	PlayerStats.xp_gained.connect(_on_xp_changed)
	PlayerStats.on_level_up.connect(_on_level_up)
	PlayerStats.buff_started.connect(_on_buff_started)
	PlayerStats.buff_ended.connect(_on_buff_ended)
	
	# Init XP
	_update_xp()

func _on_health_changed(current, max_hp):
	health_bar.max_value = max_hp
	var tween = create_tween()
	tween.tween_property(health_bar, "value", current, 0.2).set_trans(Tween.TRANS_CUBIC)

func _on_xp_changed(_amount):
	_update_xp()

func _on_level_up(level):
	# Don't show level up notification if upgrade screen is visible
	var upgrade_ui = get_tree().get_first_node_in_group("UpgradeUI")
	if upgrade_ui and upgrade_ui.visible:
		return  # Skip notification during upgrade selection
	
	_update_xp()
	show_toast("Level Up! " + str(level))

func _update_xp():
	xp_orb.max_value = PlayerStats.xp_to_next_level
	var tween = create_tween()
	tween.tween_property(xp_orb, "value", PlayerStats.xp, 0.5).set_trans(Tween.TRANS_ELASTIC)

func _on_buff_started(stat_name, duration):
	if active_buffs.has(stat_name):
		# Renew
		active_buffs[stat_name].setup(stat_name, duration)
	else:
		var icon = buff_icon_scene.instantiate()
		buff_container.add_child(icon)
		icon.setup(stat_name, duration)
		active_buffs[stat_name] = icon
		
	# Show toast
	var pretty_name = stat_name.capitalize()
	show_toast(pretty_name + " Boost!")

func _on_buff_ended(stat_name):
	if active_buffs.has(stat_name):
		# Icon handles its own queue_free via timer usually, but good to clean ref
		active_buffs.erase(stat_name)

func show_toast(msg: String):
	toast_label.text = msg
	toast_label.modulate.a = 1.0
	toast_label.visible = true
	
	# Animate pop
	toast_label.scale = Vector2(0.5, 0.5)
	var tw = create_tween()
	tw.tween_property(toast_label, "scale", Vector2(1.2, 1.2), 0.1)
	tw.tween_property(toast_label, "scale", Vector2(1.0, 1.0), 0.1)
	tw.tween_interval(1.5)
	tw.tween_property(toast_label, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func(): toast_label.visible = false)
