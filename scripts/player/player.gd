extends CharacterBody3D

## Forward movement
@export var forward_speed: float = 10.0
## Maximum horizontal speed from keyboard input
@export var max_horizontal_speed: float = 8.0
## Keyboard acceleration
@export var acceleration: float = 15.0
## Keyboard deceleration
@export var deceleration: float = 20.0
## Half the corridor width; position = clamp(x, -this, +this)
@export var corridor_half_width: float = 4.0
@export var gravity: float = 20.0

## Drag controls
## Multiplier applied to raw drag delta before converting to velocity
@export var drag_sensitivity: float = 0.04
## Cap the horizontal influence from drag
@export var max_drag_velocity: float = 8.0
## Ignore drag deltas smaller than this (world units per event)
@export var drag_deadzone: float = 2.0

## Internal keyboard horizontal target
var _target_horizontal_velocity: float = 0.0
## Whether a drag gesture is currently active
var _drag_active: bool = false
## Accumulated drag horizontal influence
var _drag_accumulator: float = 0.0


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.get_index() != 0:
		return

	if event.pressed:
		_start_drag()
	else:
		_end_drag()


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if not _drag_active:
		return
	_apply_drag_delta(event.relative.x)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		_start_drag()
	else:
		_end_drag()


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not _drag_active:
		return
	_apply_drag_delta(event.relative.x)


func _start_drag() -> void:
	_drag_active = true
	_drag_accumulator = 0.0


func _end_drag() -> void:
	_drag_active = false
	_drag_accumulator = 0.0


func _apply_drag_delta(delta: float) -> void:
	if abs(delta) < drag_deadzone:
		_drag_accumulator += delta
		return

	# Apply sensitive scaling and clamp
	var scaled: float = delta * drag_sensitivity
	_drag_accumulator += scaled
	_drag_accumulator = clamp(_drag_accumulator, -max_drag_velocity, max_drag_velocity)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Keyboard input has priority while active.
	var keyboard_axis := Input.get_axis("move_left", "move_right")
	var target_velocity: float

	if keyboard_axis != 0.0:
		target_velocity = keyboard_axis * max_horizontal_speed
		_drag_active = false
		_drag_accumulator = 0.0
	elif _drag_active:
		target_velocity = _drag_accumulator
	else:
		target_velocity = 0.0

	var rate: float = acceleration if (keyboard_axis != 0.0 or _drag_active) else deceleration
	velocity.x = move_toward(velocity.x, target_velocity, rate * delta)

	# Decay drag accumulator when not actively dragging so release feels smooth
	if not _drag_active and _drag_accumulator != 0.0:
		_drag_accumulator = move_toward(_drag_accumulator, 0.0, deceleration * delta * 0.5)

	velocity.z = -forward_speed

	move_and_slide()

	global_position.x = clamp(global_position.x, -corridor_half_width, corridor_half_width)
