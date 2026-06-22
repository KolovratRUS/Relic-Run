extends StaticBody3D

## Health value for this target
@export var max_health: float = 3.0
## Base/albedo colour
@export var base_color: Color = Color(1.0, 1.0, 1.0)

var _health: float = 0.0
var _mesh: MeshInstance3D = null
var _material: StandardMaterial3D = null


func _ready() -> void:
	_mesh = $MeshInstance3D if has_node("MeshInstance3D") else null
	_material = StandardMaterial3D.new()
	_material.albedo_color = base_color
	if _mesh != null:
		_mesh.material_override = _material
	_health = max_health


func apply_damage(amount: float) -> void:
	_health -= amount
	if _health <= 0.0:
		queue_free()
	else:
		_flash_hit()


func _flash_hit() -> void:
	if _material == null:
		return
	var original_color := _material.albedo_color
	_material.albedo_color = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	_material.albedo_color = original_color
