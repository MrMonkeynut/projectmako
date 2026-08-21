class_name EnemySpawner
extends Node3D

## Drop into any level. Configure entirely on THIS instance:
## - spawn_radius: how far from this spawner enemies can appear
## - entries: which enemy types spawn here, and how often each one

@export var enabled: bool = false
@export var spawn_radius: float = 9
@export var entries: Array[SpawnEntry] = []

var _timers: Dictionary = {}  # SpawnEntry -> Timer


func _ready() -> void:
	for entry in entries:
		if not entry.enemy_scene:
			push_error("EnemySpawner on %s has an entry with no enemy_scene" % name)
			continue

		var timer := Timer.new()
		timer.wait_time = entry.spawn_interval
		timer.one_shot = false
		timer.timeout.connect(_spawn.bind(entry))
		add_child(timer)
		_timers[entry] = timer
		timer.start()


func _spawn(entry: SpawnEntry) -> void:
	if enabled:
		var instance := entry.enemy_scene.instantiate()
		
		get_tree().current_scene.add_child(instance)

		var body := instance as Node3D
		if body:
			body.global_position = global_position + _random_offset()


func _random_offset() -> Vector3:
	if spawn_radius <= 0.0:
		return Vector3.ZERO
	var angle := randf() * TAU
	var dist := randf() * spawn_radius
	return Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
