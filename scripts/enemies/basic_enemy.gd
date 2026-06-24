extends CharacterBody3D

signal enemy_defeated(enemy: Node)

@export var max_health: float = 3.0
@export var move_speed: float = 2.0
@export var contact_damage: float = 1.0
@export var move_toward_player: bool = true
@export var base_color: Color = Color(0.8, 0.9, 0.2, 1)
@export var track_player_x: bool = false
@export var horizontal_speed: float = 2.5
@export var horizontal_dead_zone: float = 0.1

var health: float = 0.0
var defeated: bool = false
var _contact_area: Area3D = null
var _fixed_y: float = 0.0
var _player: Node3D = null


func _ready() -> void:
	health = max_health
	_fixed_y = global_position.y

	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)

	call_deferred("_find_player")

	_contact_area = $ContactArea
	if _contact_area != null:
		_contact_area.monitoring = true
		var area_col := _contact_area.get_node_or_null("CollisionShape3D")
		if area_col != null and area_col.shape != null:
			area_col.shape = area_col.shape.duplicate()

	# Ensure this enemy has its own material instance so base_color applies per-instance
	var mesh_node := $MeshInstance3D as MeshInstance3D
	if mesh_node != null and mesh_node.mesh != null:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = base_color
		mesh_node.set_surface_override_material(0, mat)


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0] as Node3D


func _process(delta: float) -> void:
	if defeated:
		return

	if not move_toward_player:
		return

	global_position.z += move_speed * delta
	global_position.y = _fixed_y

	if track_player_x:
		if not is_instance_valid(_player):
			_find_player()
		if is_instance_valid(_player):
			var x_delta: float = _player.global_position.x - global_position.x
			if abs(x_delta) > horizontal_dead_zone:
				global_position.x = move_toward(
					global_position.x,
					_player.global_position.x,
					horizontal_speed * delta
				)


func apply_damage(amount: float) -> void:
	if defeated:
		return
	if amount <= 0.0:
		return
	health -= amount
	if health <= 0.0:
		defeated = true
		enemy_defeated.emit(self)
		if _contact_area != null:
			_contact_area.set_deferred("monitoring", false)
		queue_free()


func _on_contact_area_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		body.take_damage(contact_damage)
	# Remove this enemy after a contact hit to prevent repeat damage
	apply_damage(max_health)
