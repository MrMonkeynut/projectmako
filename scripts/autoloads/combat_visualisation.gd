extends Node
## Autoload. The in-game hitbox-viewer menu flips this; every
## HitboxVisualizer in the scene reacts via the signal.

signal visibility_changed

var hitboxes_visible: bool = false:
	set(value):
		hitboxes_visible = value
		visibility_changed.emit()
