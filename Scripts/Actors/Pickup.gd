extends Area3D
class_name Pickup

# Pickup Types
enum PickupType {
	HEALTH,
	DAMAGE,
	SPEED
}

@export var type: PickupType = PickupType.HEALTH
@export var value: float = 10.0 # HP amount or Mult amount
@export var duration: float = 0.0 # 0 for instant, >0 for temp buff

var move_speed: float = 8.0
var attraction_radius: float = 4.0
var player: Node3D = null

func _ready():
	# Collision setup
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.5
	col.shape = shape
	add_child(col)
	
	body_entered.connect(_on_body_entered)
	
	# Visuals handled by factory or subclass, but we can do a simple bobbing animation here
	# Setup periodic float/bob
	var tween = create_tween().set_loops()
	tween.tween_property(self, "position:y", position.y + 0.2, 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", position.y, 1.0).set_trans(Tween.TRANS_SINE)
	
	# Auto-despawn after 30s
	await get_tree().create_timer(30.0).timeout
	queue_free()

func _physics_process(delta):
	if not player:
		# Search for player
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			# Just target P1 for now or closest
			var closest = players[0]
			var min_dist = global_position.distance_to(closest.global_position)
			
			for p in players:
				var d = global_position.distance_to(p.global_position)
				if d < min_dist:
					closest = p
					min_dist = d
			
			if min_dist < attraction_radius:
				player = closest
	
	if player:
		var dist = global_position.distance_to(player.global_position)
		if dist < attraction_radius:
			var dir = (player.global_position - global_position).normalized()
			global_position += dir * move_speed * delta

func _on_body_entered(body):
	if body.is_in_group("Player"):
		apply_effect(body)
		queue_free()

func apply_effect(_player_body):
	match type:
		PickupType.HEALTH:
			PlayerStats.heal_player(int(value))
			_play_sound("res://Assets/Audio/SFX/pickup_heart.wav") # Placeholder path
			print("Picked up Health")
		PickupType.DAMAGE:
			PlayerStats.apply_temporary_buff("damage", value, duration)
			print("Picked up Damage Boost")
		PickupType.SPEED:
			PlayerStats.apply_temporary_buff("move_speed", value, duration)
			print("Picked up Speed Boost")

func _play_sound(stream_path: String):
	# Sfx logic (global or transient player)
	# Since we queue_free immediately, we need to spawn a sound node parented to scene root
	if ResourceLoader.exists(stream_path):
		var sfx = AudioStreamPlayer.new()
		sfx.stream = load(stream_path)
		sfx.bus = "SFX"
		sfx.finished.connect(sfx.queue_free)
		get_tree().root.add_child(sfx)
		sfx.play()
