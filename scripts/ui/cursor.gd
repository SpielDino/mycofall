extends Sprite2D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
func _physics_process(delta: float) -> void:
	global_position = lerp(global_position, get_global_mouse_position(), 33*delta)

	var desired_rotation: float = -12.5 if Input.is_action_pressed("click") else 0.0;
	rotation_degrees = lerp(rotation_degrees, desired_rotation, 33*delta);
	
	var desired_scale: Vector2 = Vector2(0.2, 0.2) if Input.is_action_pressed("click") else Vector2(0.25, 0.25);
	scale = lerp(scale, desired_scale, 33*delta)
