class_name HitTriggers
extends RefCounted

## Factories for HitboxController.hit_trigger Callables.
## Signature: func(target: Node, is_overlapping: bool, delta: float, elapsed_since_open: float) -> bool
## Called once per candidate target, every physics frame the hitbox is active
## (plus once synchronously at open() with delta = 0.0, elapsed_since_open = 0.0).
## Return true the moment that target should count as hit.


## Only counts a target that is already overlapping at the instant open() is called.
static func instant() -> Callable:
	return func(_target: Node, is_overlapping: bool, _delta: float, elapsed_since_open: float) -> bool:
		return is_overlapping and elapsed_since_open <= 0.0


## Counts a target the first moment it overlaps, any time before close().
static func continuous() -> Callable:
	return func(_target: Node, is_overlapping: bool, _delta: float, _elapsed_since_open: float) -> bool:
		return is_overlapping


## Counts a target once it has overlapped continuously for `duration` seconds.
## Leaving the hitbox resets that target's accumulated time.
static func sustained(duration: float) -> Callable:
	var elapsed_by_target: Dictionary = {}
	return func(target: Node, is_overlapping: bool, delta: float, _elapsed_since_open: float) -> bool:
		if not is_overlapping:
			elapsed_by_target.erase(target)
			return false
		var t: float = elapsed_by_target.get(target, 0.0) + delta
		elapsed_by_target[target] = t
		return t >= duration
