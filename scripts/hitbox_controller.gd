extends Node3D
class_name HitboxController

signal attack_landed(target: Node)

enum DebugState { IDLE, WINDUP, ACTIVE, COOLDOWN }

@export var shape_def: HitboxShapeDefinition
@export_flags_3d_physics var enemy_mask: int = 0
@export var show_debug: bool = true:
	set(value):
		show_debug = value
		if _debug_mesh:
			_debug_mesh.visible = value
@export var idle_debug_color_alpha = 0.0
@export var warmup_debug_color_alpha = 0.0
@export var active_debug_color_alpha = 0.35
var active: bool = false
var damage_override: DamageInstance = null
var hit_trigger: Callable = HitTriggers.instant()

var _elapsed_since_open: float = 0.0
var _tracked_targets: Dictionary = {}

var debug_state: DebugState = DebugState.IDLE:
	set(value):
		debug_state = value
		_update_debug_color()

var _query := PhysicsShapeQueryParameters3D.new()
var _already_hit: Array = []
var _debug_mesh: MeshInstance3D
var _debug_mat: StandardMaterial3D

var hitbox_color_idle = Color(Color(0.176, 0.66, 0.0, 0.35), idle_debug_color_alpha)
var hitbox_color_warmup = Color(Color(1.0, 0.6, 0.0, 0.35), warmup_debug_color_alpha)
var hitbox_color_active = Color(Color(1.0, 0.152, 0.137, 0.35), active_debug_color_alpha)




func _ready() -> void:
	if not shape_def:
		push_error("HitboxController on %s has no shape_def assigned" % name)
		return

	shape_def.changed.connect(_on_shape_def_changed)

	_query.collision_mask = enemy_mask
	_query.collide_with_bodies = false
	_query.collide_with_areas = true
	_rebuild_collision_shape()

	_create_debug_mesh(hitbox_color_idle)
	_rebuild_debug_mesh()
	_debug_mesh.visible = show_debug


func set_exclusions(list: Array) -> void:
	_query.exclude = list


## Sets the debug visualization state. Caller (player attack logic, an
## AttackSequence, etc.) drives this — HitboxController just displays it.
func set_debug_state(state: DebugState) -> void:
	debug_state = state


func open(damage_instance: DamageInstance = null) -> void:
	damage_override = damage_instance
	reset_hits()
	active = true
	debug_state = DebugState.ACTIVE
	_elapsed_since_open = 0.0
	_tracked_targets.clear()
	_poll_hits(0.0)


func close() -> void:
	active = false
	debug_state = DebugState.IDLE


func reset_hits() -> void:
	_already_hit.clear()


func _physics_process(delta: float) -> void:
	if not active:
		return
	_elapsed_since_open += delta
	_poll_hits(delta)


## Queries current overlaps and runs every still-unhit candidate through
## hit_trigger, which decides whether THIS is the frame it counts as a hit.
## Candidates include targets that overlapped last frame but not this one,
## so triggers like HitTriggers.sustained() see the "left the hitbox" tick
## and can reset their own state.
func _poll_hits(delta: float) -> void:
	_query.transform = global_transform
	var results := get_world_3d().direct_space_state.intersect_shape(_query, 16)

	var overlapping_now: Dictionary = {}
	for hit in results:
		overlapping_now[hit.collider] = true

	var candidates: Dictionary = overlapping_now.duplicate()
	for target in _tracked_targets:
		candidates[target] = true

	for target in candidates:
		if target in _already_hit:
			continue
		var is_overlapping: bool = overlapping_now.has(target)
		if hit_trigger.call(target, is_overlapping, delta, _elapsed_since_open):
			_already_hit.append(target)
			_on_hit(target)

	_tracked_targets = overlapping_now


func _on_hit(target: Node) -> void:
	attack_landed.emit(target)


func configure_from_weapon(weapon: Weapon) -> void:
	shape_def = weapon.shape_def
	_rebuild_collision_shape()
	_rebuild_debug_mesh()


func _on_shape_def_changed() -> void:
	_rebuild_collision_shape()
	_rebuild_debug_mesh()


func _rebuild_collision_shape() -> void:
	_query.shape = shape_def.build_collision_shape()


func _create_debug_mesh(color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	_debug_mesh = MeshInstance3D.new()
	_debug_mesh.material_override = mat
	add_child(_debug_mesh)
	_debug_mat = mat


func _rebuild_debug_mesh() -> void:
	var im := ImmediateMesh.new()
	var tris := shape_def.build_debug_triangles()

	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in tris:
		im.surface_add_vertex(v)
	im.surface_end()

	_debug_mesh.mesh = im


func _update_debug_color() -> void:
	if not _debug_mat:
		return
	match debug_state:
		DebugState.ACTIVE:
			_debug_mat.albedo_color = hitbox_color_active
		DebugState.WINDUP, DebugState.COOLDOWN:
			_debug_mat.albedo_color = hitbox_color_warmup
		_:
			_debug_mat.albedo_color = hitbox_color_idle
