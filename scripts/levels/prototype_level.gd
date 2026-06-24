extends Node3D

@export var kill_zone_y: float = -5.0

var _reloading: bool = false
var _player: CharacterBody3D
var _game_over: bool = false
var _game_over_label: Control = null
var _pending_restart := false


func _ready() -> void:
	for child in get_children():
		if child.is_in_group("player"):
			_player = child as CharacterBody3D
			break
	if _player != null and _player.has_signal("defeated_player"):
		_player.defeated_player.connect(_on_player_defeated)

	var canvas := $GameOverUI
	if canvas != null:
		var control := canvas.get_node_or_null("Control")
		if control != null:
			var label := control.get_node_or_null("GameOverLabel")
			if label != null:
				_game_over_label = label
				label.visible = false


func _physics_process(_delta: float) -> void:
	if _reloading:
		return
	if _player != null and _player.global_position.y < kill_zone_y and not _player.defeated:
		_player.take_damage(max(0.0, abs(_player.global_position.y - kill_zone_y) * 10.0))
		_reloading = true
		get_tree().reload_current_scene()

	if _pending_restart:
		get_tree().reload_current_scene()


func _input(event: InputEvent) -> void:
	if not _game_over:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_pending_restart = true
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_pending_restart = true
		return
	if event is InputEventScreenTouch and event.pressed:
		_pending_restart = true
		return


func _on_player_defeated() -> void:
	_game_over = true
	if _game_over_label != null:
		_game_over_label.visible = true
