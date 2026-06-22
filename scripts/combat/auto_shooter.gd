extends Node3D

@export var fire_interval: float = 0.4
@export var projectile_scene: PackedScene
@export_node_path("Marker3D") var muzzle_path: NodePath

var _cooldown: float = 0.0
var _muzzle: Marker3D


func _ready() -> void:
	_muzzle = get_node_or_null(muzzle_path) as Marker3D


func _process(delta: float) -> void:
	if _muzzle == null or projectile_scene == null:
		return
	if fire_interval <= 0.0:
		return
	_cooldown -= delta
	if _cooldown <= 0.0:
		_fire()
		_cooldown = fire_interval


func _fire() -> void:
	if projectile_scene == null or _muzzle == null:
		return
	var projectile := projectile_scene.instantiate()
	if projectile == null:
		return
	if projectile is Node:
		get_tree().current_scene.add_child(projectile)
		projectile.global_transform.origin = _muzzle.global_transform.origin
		projectile.global_transform.basis = _muzzle.global_transform.basis
