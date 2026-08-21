extends Node3D
class_name StatBarController

## A single icon+bar stat display (HP, slash resistance, blunt resistance,
## etc). Fully image-driven: assign whichever of background/fill/border/icon
## textures this bar needs — any left unassigned simply aren't drawn. Attach
## one instance per stat as a child of the entity and position it with the
## node's own transform; call set_value() to update it.
##
## Layers are billboarded Sprite3D quads that all share this node's origin.
## Visual offsets (fill anchoring, icon placement) are applied via each
## sprite's own `offset`/`region_rect`, never via node position — position
## is resolved through the entity's actual (non-billboarded) rotation, so
## an offset there would swing around as the entity turns to face things.
## `offset` is resolved after the billboard shader re-faces the quad to the
## camera, so it stays screen-aligned regardless of the entity's rotation.

@export var background_texture: Texture2D
@export var fill_texture: Texture2D
@export var border_texture: Texture2D
@export var icon_texture: Texture2D

@export var bar_size: Vector2 = Vector2(3, 0.5)
@export var icon_size: Vector2 = Vector2(0.12, 0.12)
@export var icon_gap: float = 0.04

var _fill_sprite: Sprite3D
var _fraction: float = 1.0


func _ready() -> void:
	_build_layer(background_texture, 0, bar_size)
	_fill_sprite = _build_layer(fill_texture, 1, bar_size)
	_build_layer(border_texture, 2, bar_size)
	if icon_texture:
		var icon := _build_layer(icon_texture, 2, icon_size)
		var icon_center_x := -(bar_size.x + icon_size.x) / 2.0 - icon_gap
		icon.offset.x = icon_center_x * icon_texture.get_width() / icon_size.x
	_apply_fraction()


func set_value(current: float, max_value: float) -> void:
	_fraction = clampf(current / max_value, 0.0, 1.0) if max_value > 0.0 else 0.0
	_apply_fraction()


## Crops fill_texture's region down from the left so the bar drains
## right-to-left, then shifts it back via offset (see class doc) to keep
## its left edge anchored to the bar's left edge as it shrinks.
func _apply_fraction() -> void:
	if not _fill_sprite:
		return
	var full_width := fill_texture.get_width()
	var visible_width := full_width * _fraction
	_fill_sprite.region_rect = Rect2(0, 0, visible_width, fill_texture.get_height())
	_fill_sprite.offset.x = (visible_width - full_width) / 2.0


## Builds one billboarded, depth-test-disabled Sprite3D layer sized to
## `size` world units, stacked above sibling layers via render_priority so
## fill/border never z-fight with the background they share a plane with.
## Returns null (and adds nothing) if no texture was assigned.
func _build_layer(texture: Texture2D, priority: int, size: Vector2) -> Sprite3D:
	if not texture:
		return null

	var sprite := Sprite3D.new()
	sprite.texture = texture
	sprite.shaded = false
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.no_depth_test = true
	sprite.render_priority = priority
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, texture.get_size())
	sprite.pixel_size = size.x / texture.get_width()
	sprite.scale.y = size.y / (texture.get_height() * sprite.pixel_size)
	add_child(sprite)
	return sprite
