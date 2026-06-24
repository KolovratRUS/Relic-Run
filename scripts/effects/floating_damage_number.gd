extends Node3D

@export var lifetime: float = 0.75
@export var rise_speed: float = 1.5


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)


func setup(amount: float) -> void:
	var label := $Label3D as Label3D
	if label == null:
		return

	if is_equal_approx(amount, round(amount)):
		label.text = str(int(round(amount)))
	else:
		label.text = str(snapped(amount, 0.1))


func _process(delta: float) -> void:
	global_position.y += rise_speed * delta
	var label := $Label3D as Label3D
	if label != null:
		var alpha := label.modulate.a - (delta / lifetime)
		if alpha <= 0.0:
			queue_free()
			return
		label.modulate.a = alpha
