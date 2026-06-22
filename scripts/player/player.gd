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

## Jump
## Initial upward velocity applied when jump is triggered
@export var jump_force: float = 12.0

## Slide
## How long the slide state lasts (seconds)
@export var slide_duration: float = 0.6
## Capsule height while sliding
@export var slide_capsule_height: float = 0.8
## Vertical offset applied to keep capsule base on floor while sliding
@export var slide_y_offset: float = -0.5

## Drag controls
## Multiplier applied to raw drag delta before converting to velocity
@export var drag_sensitivity: float = 0.04
## Cap the horizontal influence from drag
@export var max_drag_velocity: float = 8.0
## Ignore drag deltas smaller than this (world units per event)
@export var drag_deadzone: float = 2.0
## Minimum vertical swipe delta to trigger jump/slide (world units)
@export var swipe_vertical_threshold: float = 40.0
## Maximum allowed horizontal delta as fraction of vertical (lower = stricter)
@export var swipe_horizontal_tolerance: float = 0.5

## Internal keyboard horizontal target
var _target_horizontal_velocity: float = 0.0
## Whether a drag gesture is currently active
var _drag_active: bool = false
## Accumulated drag horizontal influence
var _drag_accumulator: float = 0.0
## Start position of current drag for swipe detection
var _drag_start_pos: Vector2 = Vector2.ZERO
## Last known absolute position during drag
var _drag_current_pos: Vector2 = Vector2.ZERO
## Whether the current drag already triggered a vertical action
var _drag_vertical_triggered: bool = false
## Whether the player is currently sliding
var _is_sliding: bool = false
## Countdown until slide ends
var _slide_timer: float = 0.0


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
		_start_drag(event.position)
	else:
		_end_drag(event.position)


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if not _drag_active:
		return
	_drag_current_pos = event.position
	_apply_drag_delta(event.relative.x)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		_start_drag(event.position)
	else:
		_end_drag(event.position)


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not _drag_active:
		return
	_drag_current_pos = event.position
	_apply_drag_delta(event.relative.x)


func _start_drag(start_pos: Vector2) -> void:
	_drag_active = true
	_drag_accumulator = 0.0
	_drag_start_pos = start_pos
	_drag_current_pos = start_pos
	_drag_vertical_triggered = false


func _end_drag(end_pos: Vector2) -> void:
	if _drag_active and not _drag_vertical_triggered:
		var delta: Vector2 = end_pos - _drag_start_pos
		_try_swipe_action(delta)

	_drag_active = false
	_drag_accumulator = 0.0


func _try_swipe_action(delta: Vector2) -> void:
	var abs_x: float = abs(delta.x)
	var abs_y: float = abs(delta.y)

	if abs_y < swipe_vertical_threshold:
		return
	if abs_x > abs_y * swipe_horizontal_tolerance:
		return

	if delta.y < 0:
		## upward swipe -> jump
		if is_on_floor():
			velocity.y = jump_force
	else:
		## downward swipe -> slide
		if is_on_floor() and not _is_sliding:
			_start_slide()

	_drag_vertical_triggered = true


func _apply_drag_delta(delta: float) -> void:
	if abs(delta) < drag_deadzone:
		_drag_accumulator += delta
		return

	# Apply sensitive scaling and clamp
	var scaled: float = delta * drag_sensitivity
	_drag_accumulator += scaled
	_drag_accumulator = clamp(_drag_accumulator, -max_drag_velocity, max_drag_velocity)


func _start_slide() -> void:
	_is_sliding = true
	_slide_timer = slide_duration

	var collision := $CollisionShape3D
	if collision != null and collision.shape is CapsuleShape3D:
		(collision.shape as CapsuleShape3D).height = slide_capsule_height

	var mesh := $MeshInstance3D
	if mesh != null and mesh.mesh is CapsuleMesh:
		(mesh.mesh as CapsuleMesh).height = slide_capsule_height

	# Lower the player so the base stays on the floor while sliding
	global_position.y += slide_y_offset


func _end_slide() -> void:
	_is_sliding = false

	var collision := $CollisionShape3D
	if collision != null and collision.shape is CapsuleShape3D:
		(collision.shape as CapsuleShape3D).height = 1.8

	var mesh := $MeshInstance3D
	if mesh != null and mesh.mesh is CapsuleMesh:
		(mesh.mesh as CapsuleMesh).height = 1.8

	global_position.y -= slide_y_offset


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	## Slide timer
	if _is_sliding:
		_slide_timer -= delta
		if _slide_timer <= 0.0:
			_end_slide()

	## Keyboard input has priority while active.
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
