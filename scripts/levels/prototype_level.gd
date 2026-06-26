extends Node3D

@export var kill_zone_y: float = -5.0

var _reloading: bool = false
var _player: CharacterBody3D
var _game_over: bool = false
var _game_over_label: Label = null
var _restart_label: Label = null
var _pending_restart := false
var _squad_counter: Label = null
var _squad_manager: Node3D = null


func _ready() -> void:
	_player = get_node_or_null("Player") as CharacterBody3D
	if _player == null:
		push_error("Player was not found")
	elif not _player.has_signal("defeated_player"):
		push_error("Player does not have defeated_player signal")
	elif not _player.defeated_player.is_connected(_on_player_defeated):
		_player.defeated_player.connect(_on_player_defeated)

	_squad_counter = $HUD/SquadCounter

	_squad_manager = _player.get_node_or_null("SquadManager") as Node3D if _player else null
	if _squad_manager != null:
		if _squad_manager.has_signal("squad_size_changed"):
			_squad_manager.squad_size_changed.connect(_on_squad_size_changed)
		_update_squad_counter(_squad_manager.get_member_count())
	else:
		_update_squad_counter(0)

	_create_game_over_labels()


func _create_game_over_labels() -> void:
	if _game_over_label != null or _restart_label != null:
		return

	var hud := get_node_or_null("HUD") as CanvasLayer
	if hud == null:
		push_error("HUD was not found")
		return

	var viewport_size := get_viewport().get_visible_rect().size

	_game_over_label = Label.new()
	_game_over_label.name = "GameOverLabel"
	_game_over_label.text = "GAME OVER"
	_game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_game_over_label.add_theme_font_size_override("font_size", 48)
	_game_over_label.position = Vector2(0.0, viewport_size.y * 0.40)
	_game_over_label.size = Vector2(viewport_size.x, 70.0)
	_game_over_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_game_over_label.hide()
	hud.add_child(_game_over_label)

	_restart_label = Label.new()
	_restart_label.name = "RestartLabel"
	_restart_label.text = "TAP OR PRESS R TO RESTART"
	_restart_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_restart_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_restart_label.add_theme_font_size_override("font_size", 28)
	_restart_label.position = Vector2(0.0, viewport_size.y * 0.40 + 70.0)
	_restart_label.size = Vector2(viewport_size.x, 55.0)
	_restart_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_restart_label.hide()
	hud.add_child(_restart_label)


func _get_squad_size() -> int:
	if _squad_manager == null:
		return 0
	return _squad_manager.get_member_count()


func _on_squad_size_changed(new_size: int) -> void:
	_update_squad_counter(new_size)


func _update_squad_counter(size: int) -> void:
	if _squad_counter == null:
		return

	var max_size: int = 8
	if _squad_manager != null:
		max_size = int(_squad_manager.max_members)

	_squad_counter.text = "SQUAD: %d / %d" % [size, max_size]

	if size >= max_size:
		_squad_counter.text += " — FULL"


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
	if _game_over:
		return

	_game_over = true

	if _game_over_label != null:
		_game_over_label.show()

	if _restart_label != null:
		_restart_label.show()
