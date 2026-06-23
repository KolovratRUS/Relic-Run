extends Node3D

@export var left_position: Vector3 = Vector3(-2.2, 1.5, 0)
@export var right_position: Vector3 = Vector3(2.2, 1.5, 0)

var _left_gate: Area3D = null
var _right_gate: Area3D = null
var _applied: bool = false


func _ready() -> void:
	_left_gate = $LeftGate
	_right_gate = $RightGate
	if _left_gate != null:
		_left_gate.position = left_position
		_left_gate.gate_selected.connect(_on_gate_selected)
	if _right_gate != null:
		_right_gate.position = right_position
		_right_gate.gate_selected.connect(_on_gate_selected)


func _on_gate_selected(gate: Area3D, body: Node) -> void:
	if _applied:
		return
	_applied = true

	if body.has_method("apply_upgrade"):
		body.apply_upgrade(gate.upgrade_type, gate.upgrade_amount)

	if _left_gate != null:
		_left_gate.consumed = true
		_left_gate.visible = false
		_left_gate.monitoring = false

	if _right_gate != null:
		_right_gate.consumed = true
		_right_gate.visible = false
		_right_gate.monitoring = false
