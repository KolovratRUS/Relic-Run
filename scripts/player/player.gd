extends CharacterBody3D

@export var forward_speed: float = 10.0
@export var max_horizontal_speed: float = 8.0
@export var acceleration: float = 15.0
@export var deceleration: float = 20.0
@export var corridor_half_width: float = 4.0
@export var gravity: float = 20.0

var _target_horizontal_velocity: float = 0.0


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_axis := Input.get_axis("move_left", "move_right")

	if input_axis != 0.0:
		_target_horizontal_velocity = input_axis * max_horizontal_speed
	else:
		_target_horizontal_velocity = 0.0

	var rate: float = acceleration if input_axis != 0.0 else deceleration
	velocity.x = move_toward(velocity.x, _target_horizontal_velocity, rate * delta)

	velocity.z = -forward_speed

	move_and_slide()

	global_position.x = clamp(global_position.x, -corridor_half_width, corridor_half_width)
