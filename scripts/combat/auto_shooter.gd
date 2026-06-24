extends Node3D

@export var fire_interval: float = 0.4
@export var projectile_scene: PackedScene
@export_node_path("Marker3D") var muzzle_path: NodePath
@export var min_fire_interval: float = 0.1
@export var double_shot_spacing: float = 0.35
var projectile_damage: float = 1.0
var double_shot_enabled: bool = false
var shooting_enabled: bool = true

var _cooldown: float = 0.0
var _muzzle: Marker3D


func _ready() -> void:
	_muzzle = get_node_or_null(muzzle_path) as Marker3D


func _process(delta: float) -> void:
	if _muzzle == null or projectile_scene == null:
		return
	if fire_interval <= 0.0:
		return
	if not shooting_enabled:
		return
	_cooldown -= delta
	if _cooldown <= 0.0:
		_fire()
		_cooldown = fire_interval


func _fire() -> void:
	if double_shot_enabled:
		_spawn_projectile(-double_shot_spacing)
		_spawn_projectile(double_shot_spacing)
	else:
		_spawn_projectile(0.0)


func _spawn_projectile(x_offset: float) -> void:
	if projectile_scene == null or _muzzle == null:
		return
	var projectile := projectile_scene.instantiate()
	if projectile == null:
		return
	if projectile is Node:
		get_tree().current_scene.add_child(projectile)
		projectile.global_transform.origin = _muzzle.global_transform.origin + _muzzle.global_transform.basis.x * x_offset
		projectile.global_transform.basis = _muzzle.global_transform.basis
		if projectile.has_method("set_damage"):
			projectile.set_damage(projectile_damage)


func apply_fire_rate_upgrade(multiplier: float) -> void:
	fire_interval = max(min_fire_interval, fire_interval * multiplier)


func apply_damage_upgrade(amount: float) -> void:
	projectile_damage += amount


func enable_double_shot() -> void:
	double_shot_enabled = true


func set_shooting_enabled(enabled: bool) -> void:
	shooting_enabled = enabled
