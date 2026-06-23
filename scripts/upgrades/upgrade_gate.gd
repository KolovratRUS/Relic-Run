extends Area3D

signal gate_selected(gate: Area3D, body: Node)

@export var upgrade_type: int = 0
@export var upgrade_amount: float = 0.0
@export var display_text: String = ""
@export var gate_color: Color = Color(1, 1, 1, 1)
@export var consumed: bool = false

var _label: Label3D = null
var _mesh: MeshInstance3D = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_label = $Label3D
	_mesh = $MeshInstance3D
	_update_visuals()


func _on_body_entered(body: Node) -> void:
	if consumed:
		return
	if body == null:
		return
	if not body.is_in_group("player"):
		return
	consumed = true
	gate_selected.emit(self, body)


func _update_visuals() -> void:
	if _label != null:
		_label.text = display_text
	if _mesh != null:
		var material := StandardMaterial3D.new()
		material.albedo_color = gate_color
		_mesh.set_surface_override_material(0, material)
