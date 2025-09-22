extends Sprite2D

var burst_scene := preload("res://scenes/ui/nav/click_burst.tscn")
var pool: Array[CPUParticles2D] = [];

@onready var hover_particles = $cursor_hover
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
func _physics_process(delta: float) -> void:
	if !UIManager.is_menu:
		hover_particles.visible = false
	else:
		hover_particles.visible = true
		
	global_position = lerp(global_position, get_global_mouse_position(), 33*delta)

	var desired_rotation: float = -12.5 if Input.is_action_pressed("click") else 0.0;
	rotation_degrees = lerp(rotation_degrees, desired_rotation, 33*delta);
	
	var desired_scale: Vector2 = Vector2(0.2, 0.2) if Input.is_action_pressed("click") else Vector2(0.25, 0.25);
	scale = lerp(scale, desired_scale, 33*delta)

	if Input.is_action_just_pressed("click"):
		spawn_burst(get_global_mouse_position())

func get_burst() -> CPUParticles2D:
	if pool.is_empty():
		var p := burst_scene.instantiate() as CPUParticles2D
		assert(p != null, "Burst scene root must be CPUParticles2D")
		p.one_shot = true
		p.emitting = false
		# Connect once per instance.
		p.finished.connect(_on_burst_finished.bind(p))
		return p
	return pool.pop_back()
	
func spawn_burst(pos: Vector2) -> void:
	if !UIManager.is_menu:
		return
	var p := get_burst()
	get_tree().current_scene.add_child(p)
	p.global_position = pos
	p.restart()
	p.emitting = true
		
func _on_burst_finished(p: CPUParticles2D) -> void:
	if not is_instance_valid(p): return
	p.emitting = false
	p.get_parent().remove_child(p)
	pool.append(p)
