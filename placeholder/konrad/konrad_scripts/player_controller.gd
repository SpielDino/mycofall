extends CharacterBody3D

@export_category("Components")
@export var player_shape: CollisionShape3D

var speed
var acceleration 
var friction 
#@onready var sensitivity: float = settings.sensitivity
var rotation_type: String 
var lock_active: bool
var dash_strength: int 
var dash_max_cooldown: float 
var max_stamina: int 
var stamina_per_second: int
var stamina_cost_per_dash: int
var dash_type: String
var no_stamina_after_dash_time: float

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var temprotation = 0
var dash_cooldown: float = 0
var mouse_mode: bool = false
var mouse_timer: float = 0
var player: Node3D
var lock = false
var sneak_toggle = false

var dash_timer: float = 0.5
var max_dash_timer: float = 0.5
var is_dashing = false
var different_dash_strength: int
var dash_strength_multiplier_shield: float = 0.6
var dash_strength_multiplier_bow: float = 0.9
var dash_strength_multiplier_staff: float = 0.8

@onready var spring_arm = $CameraArm

func _ready():
	player = GlobalPlayer.get_player()
	speed = player.speed
	acceleration = player.acceleration
	friction = player.friction
	#@onready var sensitivity: float = settings.sensitivity
	rotation_type = player.rotation_type
	lock_active = player.lock_active
	dash_strength = player.dash_strength
	dash_max_cooldown = player.dash_max_cooldown
	max_stamina = player.max_stamina
	stamina_per_second = player.stamina_per_second
	stamina_cost_per_dash = player.stamina_cost_per_dash
	dash_type = player.dash_type
	no_stamina_after_dash_time = player.no_stamina_after_dash_time

func _physics_process(delta):	
	apply_gravity(delta)
	get_move_input(delta)
	move_and_slide()
	rotate_player()
	dash(delta)
	block()
	dash_timer_calc(delta)

func _input(event):
	if event is InputEventMouseMotion:
		if event.velocity.x > 0 or event.velocity.y > 0:
			mouse_mode = true

func dash(delta):
	match dash_type:
		"dash with cooldown":
			dash_with_cooldown(delta)
		"dash with stamina":
			dash_with_stamina(delta)

func dash_with_cooldown(delta):
	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0:
		dash_ability(delta)
		dash_cooldown = dash_max_cooldown
	if dash_cooldown >= 0:
		dash_cooldown = dash_cooldown - delta

func dash_with_stamina(delta):
	if Input.is_action_just_pressed("dash") and player.stamina >= stamina_cost_per_dash and !is_dashing:
		dash_ability(delta)
		player.reduce_stamina(stamina_cost_per_dash)
		#$PlayerAudio/DashSFX.play()
		is_dashing = true
		dash_timer = max_dash_timer
		GameManager.set_is_dashing(is_dashing)
	elif Input.is_action_just_pressed("dash") and player.stamina <= stamina_cost_per_dash:
		#$PlayerAudio/NoStaminaSFX.play()
		pass

func dash_timer_calc(delta):
	if dash_timer > 0 and is_dashing:
		dash_timer = dash_timer - delta
	elif dash_timer <= 0 and is_dashing:
		is_dashing = false
		GameManager.set_is_dashing(is_dashing)

func dash_ability(delta):
	var vy = velocity.y
	velocity.y = 0
	var input = Input.get_vector("left", "right", "forward", "backward").normalized()
	var direction = Vector3(input.x, 0, input.y).rotated(Vector3.UP, spring_arm.rotation.y)
	different_dash_strength = dash_strength
	match GameManager.get_first_weapon():
		"Sword":
			if GameManager.get_second_weapon() == "Shield":
				different_dash_strength = dash_strength * dash_strength_multiplier_shield
		"Bow":
			different_dash_strength = dash_strength * dash_strength_multiplier_bow
		"Staff":
			different_dash_strength = dash_strength * dash_strength_multiplier_staff
		"Shield":
			different_dash_strength = dash_strength * dash_strength_multiplier_shield
	#velocity = lerp(velocity, direction * dash_strength, acceleration * delta)
	velocity = lerp(velocity, direction * different_dash_strength, acceleration * delta)
	velocity.y = vy
	player.set_stamina_regen_cooldown(no_stamina_after_dash_time)
	if player.is_detected:
		PlayerActionTracker.times_dodged_in_combat += 1

func block():
	if Input.is_action_pressed("block"):
		#if check_for_equipped_shield():
		print("blocking")
		player.is_blocking = true
		GameManager.set_is_blocking(true)
	if Input.is_action_just_released("block"):
		print("not blocking")
		player.is_blocking = false
		GameManager.set_is_blocking(false)
		

func check_for_equipped_shield():
	return true

func rotate_player():
	match rotation_type:
		"rotate based on last movement":
			rotate_based_on_last_movement()
		"rotate based on second input":
			rotate_based_on_second_input()

func rotate_based_on_last_movement():
	var input = Input.get_vector("left", "right", "forward", "backward")
	if lock_active:
		lock = Input.is_action_pressed("lock_movement")
	if (input.x != 0 or input.y != 0) and !lock:
		temprotation = atan2(-input.x, -input.y)
	player_shape.rotation.y = temprotation

func rotate_based_on_second_input():
	var look_input = Input.get_vector("look_left", "look_right", "look_forward", "look_backward")
	if (look_input.x != 0 or look_input.y != 0):
		mouse_mode = false
	if lock_active:
		lock = Input.is_action_pressed("lock_movement")
	if !mouse_mode:
		var input = Input.get_vector("left", "right", "forward", "backward")
		if (input.x != 0 or input.y != 0):
			temprotation = atan2(-input.x, -input.y)
		if (look_input.x != 0 or look_input.y != 0):
			temprotation = atan2(-look_input.x, -look_input.y)
	else:
		var mouse_position = get_viewport().get_mouse_position()
		var mouse_world_position = GameManager.get_mouse_ground_position_fixed(self)
		#var screenSize = get_viewport().get_visible_rect().size
		#var screenCenter = Vector2(screenSize.x/2,screenSize.y/2 - 20)
		#var normalizedRelativeMousePosition = Vector2(mouse_position.x - screenCenter.x, mouse_position.y - screenCenter.y).normalized()
		#temprotation = atan2(normalizedRelativeMousePosition.x, normalizedRelativeMousePosition.y) + PI
		var direction = (mouse_world_position - global_position)
		direction.y = 0  # Y-Komponente ignorieren
		direction = -direction.normalized()
	
		if direction.length() > 0:
			# Direkte Rotation um Y-Achse
			var angle = atan2(direction.x, direction.z)
			temprotation = angle
	if !lock:
		# Locking rotation when using melee attack
		if GameManager.get_is_attacking() and GameManager.get_first_weapon() == "Sword":
			pass
		else:
			player_shape.rotation.y = temprotation

func get_move_input(delta):
	sneak_toggler()
	var vy = velocity.y
	velocity.y = 0
	var input = Input.get_vector("left", "right", "forward", "backward").normalized()
	var direction = Vector3(input.x, 0, input.y).rotated(Vector3.UP, spring_arm.rotation.y)
	var player_speed = player.speed
	player.set_sneaking(false)
	if sneak_toggle:
		player.set_sneaking(true)
		player_speed = player_speed / player.sneak_speed_modifier
	velocity = lerp(velocity, direction * player_speed, acceleration * delta)
	velocity.y = vy
	if abs(input.x) < 0.01:
		velocity.x -= velocity.x * friction
	if abs(input.y) < 0.01:
		velocity.z -= velocity.z * friction

func sneak_toggler():
	if Input.is_action_just_pressed("sneak"):
		if sneak_toggle:
			sneak_toggle = false
		else:
			sneak_toggle = true

func apply_gravity(delta):
	velocity.y += -gravity * delta
