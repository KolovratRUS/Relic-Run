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
@export var show_health_bar: bool = true
@export var hit_flash_duration: float = 0.1
@export var floating_damage_scene: PackedScene

var health: float = 0.0
var defeated: bool = false
var _contact_area: Area3D = null
var _fixed_y: float = 0.0
var _player: Node3D = null
var _runtime_material: StandardMaterial3D = null
var _flash_version: int = 0
var _health_bar_root: Node3D = null
var _health_fill: MeshInstance3D = null


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

	_health_bar_root = $HealthBarRoot
	if _health_bar_root != null:
		_health_bar_root.visible = show_health_bar

	_health_fill = _health_bar_root.get_node_or_null("Fill") if _health_bar_root != null else null

	var mesh_node := $MeshInstance3D as MeshInstance3D
	if mesh_node != null and mesh_node.mesh != null:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = base_color
		mesh_node.set_surface_override_material(0, mat)
		_runtime_material = mat

	_update_health_bar()


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0] as Node3D


func _update_health_bar() -> void:
	if _health_fill == null:
		return
	var ratio: float = 0.0
	if max_health > 0.0:
		ratio = clamp(health / max_health, 0.0, 1.0)
	_health_fill.scale.x = ratio
	_health_fill.position.x = (1.0 - ratio) * 0.3


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


func _spawn_floating_damage(amount: float) -> void:
	if floating_damage_scene == null:
		return
	var level := get_tree().get_first_node_in_group("level")
	if level == null:
		return
	var instance := floating_damage_scene.instantiate()
	if instance == null:
		return
	level.add_child(instance)
	instance.global_position = global_position + Vector3(0, 1.5, 0)
	if instance.has_method("setup"):
		instance.setup(amount)


func _trigger_hit_flash() -> void:
	if _runtime_material == null:
		return
	_flash_version += 1
	var this_version := _flash_version
	_runtime_material.albedo_color = Color(1, 1, 1, 1)
	var timer := get_tree().create_timer(hit_flash_duration)
	timer.timeout.connect(func():
		if _flash_version == this_version and _runtime_material != null:
			_runtime_material.albedo_color = base_color
	)


func _start_death_feedback() -> void:
	defeated = true
	if _health_bar_root != null:
		_health_bar_root.visible = false
	if _contact_area != null:
		_contact_area.set_deferred("monitoring", false)
	var col := get_node_or_null("CollisionShape3D")
	if col != null:
		col.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.2)
	tween.finished.connect(queue_free)


func apply_damage(amount: float) -> void:
	if defeated:
		return
	if amount <= 0.0:
		return
	health -= amount
	_spawn_floating_damage(amount)
	_trigger_hit_flash()
	_update_health_bar()
	if health <= 0.0:
		_start_death_feedback()
		enemy_defeated.emit(self)


func _on_contact_area_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		body.take_damage(contact_damage)
	if not defeated:
		apply_damage(max_health)
