extends Node2D


var _player_pos: Vector2


func _ready() -> void:
	_player_pos = GameManager.state["player_position"]


func _process(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_action_pressed("ui_left"):  direction.x -= 1.0
	if Input.is_action_pressed("ui_right"): direction.x += 1.0
	if Input.is_action_pressed("ui_up"):    direction.y -= 1.0
	if Input.is_action_pressed("ui_down"):  direction.y += 1.0

	if direction != Vector2.ZERO:
		direction = direction.normalized()

	var speed: float = GameManager.state["player_speed"]
	_player_pos += direction * speed * delta
	_player_pos.x = clamp(_player_pos.x, 20.0, 780.0)
	_player_pos.y = clamp(_player_pos.y, 20.0, 580.0)
	GameManager.state["player_position"] = _player_pos

	queue_redraw()


func _draw() -> void:
	# Background
	draw_rect(Rect2(0.0, 0.0, 800.0, 600.0), Color(0.08, 0.08, 0.12))
	# Room boundary
	draw_rect(Rect2(10.0, 10.0, 780.0, 580.0), Color(0.2, 0.2, 0.35), false, 2.0)
	# Player entity
	draw_rect(
		Rect2(_player_pos.x - 14.0, _player_pos.y - 14.0, 28.0, 28.0),
		Color(0.0, 1.0, 0.53)
	)
	# HUD
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(16.0, 32.0),
		"HP: %d" % GameManager.state["player_hp"],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
