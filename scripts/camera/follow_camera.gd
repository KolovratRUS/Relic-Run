extends Camera3D

@export var follow_offset: Vector3 = Vector3(0, 5.0, 8.0)
@export var look_ahead_offset: Vector3 = Vector3(0, 1.5, -3.0)
@export var smoothing: float = 8.0

var _player: Node3D = null


func _ready() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0] as Node3D


func _process(delta: float) -> void:
	if _player == null:
		return

	var desired_position: Vector3 = _player.global_position + follow_offset
	global_position = global_position.lerp(desired_position, 1.0 - exp(-smoothing * delta))

	var desired_look_at: Vector3 = _player.global_position + look_ahead_offset
	look_at(desired_look_at, Vector3.UP)
