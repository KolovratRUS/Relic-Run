extends Node3D

@export var kill_zone_y: float = -5.0

var _reloading: bool = false
var _player: CharacterBody3D


func _ready() -> void:
	for child in get_children():
		if child is CharacterBody3D:
			_player = child


func _physics_process(_delta: float) -> void:
	if _reloading:
		return
	if _player != null and _player.global_position.y < kill_zone_y:
		_reloading = true
		get_tree().reload_current_scene()
