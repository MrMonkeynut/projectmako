extends Resource
class_name SpawnEntry

## One row in a spawner's list: which enemy, how often. Configured inline,
## per spawner instance — not meant to be saved as a shared .tres.

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 5.0
