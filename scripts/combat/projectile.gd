extends Area3D

@export var speed: float = 20.0
@export var damage: float = 1.0
@export var lifetime: float = 3.0

var _alive := true
var _age := 0.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if not _alive:
		return

	_age += delta
	if _age >= lifetime:
		queue_free()
		return

	var from := global_transform.origin
	var to := from + (-global_transform.basis.z.normalized() * speed * delta)

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 4
	query.exclude = [self]

	var result := space_state.intersect_ray(query)
	if not result.is_empty():
		var collider: Object = result["collider"] as Object
		if collider != null and collider.has_method("apply_damage"):
			collider.apply_damage(damage)
			queue_free()
			_alive = false
			return

	global_transform.origin = to


func _on_body_entered(body: Node) -> void:
	_damage_and_destroy(body)


func _on_area_entered(area: Area3D) -> void:
	_damage_and_destroy(area)


func _damage_and_destroy(other: Node) -> void:
	if not _alive:
		return
	var obj := other as Object
	if obj != null and obj.has_method("apply_damage"):
		obj.apply_damage(damage)
	_alive = false
	queue_free()


func set_damage(value: float) -> void:
	damage = max(0.0, value)
