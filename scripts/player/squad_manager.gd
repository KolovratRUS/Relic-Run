extends Node3D

signal squad_size_changed(new_size: int)

@export var member_scene: PackedScene
@export var starting_members: int = 2
@export var max_members: int = 8

var members: Array[Node3D] = []

const FORMATION_SLOTS: Array[Vector3] = [
    Vector3(-0.75, 0.0, 0.9),
    Vector3(0.75, 0.0, 0.9),
    Vector3(-1.5, 0.0, 1.7),
    Vector3(0.0, 0.0, 1.7),
    Vector3(1.5, 0.0, 1.7),
    Vector3(-1.5, 0.0, 2.5),
    Vector3(0.0, 0.0, 2.5),
    Vector3(1.5, 0.0, 2.5),
]


func _ready() -> void:
    var count: int = starting_members
    if count > max_members:
        count = max_members
    for i in range(count):
        _spawn_member(i)


func _spawn_member(slot_index: int) -> void:
    if member_scene == null:
        return
    if slot_index >= FORMATION_SLOTS.size():
        return
    var instance := member_scene.instantiate()
    if instance == null:
        return
    add_child(instance)
    instance.transform = Transform3D(Basis(), FORMATION_SLOTS[slot_index])
    members.append(instance)


func add_members(amount: int) -> void:
    if amount <= 0:
        return
    var current := members.size()
    var desired := current + amount
    if desired > max_members:
        desired = max_members
    if desired <= current:
        return
    for i in range(current, desired):
        _spawn_member(i)
    emit_signal("squad_size_changed", members.size())


func get_member_count() -> int:
    return members.size()


func get_active_muzzles() -> Array[Marker3D]:
    var result: Array[Marker3D] = []
    for member in members:
        if member == null:
            continue
        var muzzle := member.get_node_or_null("Muzzle") as Marker3D
        if muzzle != null:
            result.append(muzzle)
    return result
