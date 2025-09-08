extends CharacterBody3D

const DEADZONE := 0.2

@export_category("Components")
@export var player_shape: CollisionShape3D
@export var dodge_indicator: MeshInstance3D

var speed
var acceleration 
var friction 
#@onready var sensitivity: float = settings.sensitivity
var rotation_type: String 
var lock_active: bool
var max_stamina: int 
var stamina_per_second: int
var stamina_cost_per_dodge: int
var no_stamina_after_dodge_time: float
var dodge_duration: float
var dodge_distance: float
var dodge_speed: float
var dodge_strength_multiplier_shield: float
var dodge_strength_multiplier_bow: float
var dodge_strength_multiplier_staff: float

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var temprotation = 0
#var mouse_mode: bool = false
var mouse_timer: float = 0
var player: Node3D
var lock = false
var sneak_toggle = false

var i_frame_timer: float
var max_i_frame_timer: float
var having_i_frames = false
var dodge_direction: Vector3 = Vector3.ZERO
var dodge_timer: float = 0.0
var is_dodging: bool = false

var sword_name = "Sword"
var shield_name = "Shield"
var staff_name = "Staff"
var bow_name = "Bow"

@onready var spring_arm = $CameraArm

func _ready():
	player = GlobalPlayer.get_player()
	speed = player.speed
	acceleration = player.acceleration
	friction = player.friction
	#@onready var sensitivity: float = settings.sensitivity
	rotation_type = player.rotation_type
	lock_active = player.lock_active
	max_stamina = player.max_stamina
	stamina_per_second = player.stamina_per_second
	stamina_cost_per_dodge = player.stamina_cost_per_dodge
	no_stamina_after_dodge_time = player.no_stamina_after_dodge_time
	dodge_duration = player.dodge_duration
	dodge_distance = player.dodge_distance
	max_i_frame_timer = player.max_i_frame_timer
	i_frame_timer = player.i_frame_timer
	dodge_strength_multiplier_shield = player.dodge_strength_multiplier_shield
	dodge_strength_multiplier_bow = player.dodge_strength_multiplier_bow
	dodge_strength_multiplier_staff = player.dodge_strength_multiplier_staff


func _physics_process(delta):
	apply_gravity(delta)
	
	if is_dodging:
		process_dodge(delta)
		i_frame_timer_calc(delta)
	else:
		get_move_input(delta)
		move_and_slide()
		rotate_player()
		block()
		dodge_with_stamina()

func dodge_with_stamina():
	if Input.is_action_just_pressed("dodge") and player.stamina >= stamina_cost_per_dodge:
		dodge_ability()
		player.reduce_stamina(stamina_cost_per_dodge)
		#$PlayerAudio/DashSFX.play()
		having_i_frames = true
		i_frame_timer = max_i_frame_timer
		GameManager.set_having_i_frames(having_i_frames)
	elif Input.is_action_just_pressed("dodge") and player.stamina <= stamina_cost_per_dodge:
		#$PlayerAudio/NoStaminaSFX.play()
		pass

func i_frame_timer_calc(delta):
	if i_frame_timer > 0 and having_i_frames:
		i_frame_timer = i_frame_timer - delta
	elif i_frame_timer <= 0 and having_i_frames:
		having_i_frames = false
		GameManager.set_having_i_frames(having_i_frames)

func dodge_ability():
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward").normalized()
	
	# if no movement input, player will dodge at the direction they are looking at
	if input == Vector2.ZERO:
		dodge_direction = -player_shape.global_transform.basis.z.normalized()
	else:
		dodge_direction = Vector3(input.x, 0, input.y).rotated(Vector3.UP, spring_arm.rotation.y).normalized()
	
	is_dodging = true
	GameManager.set_is_dodging(is_dodging)
	dodge_timer = dodge_duration
	
	player.set_stamina_regen_cooldown(no_stamina_after_dodge_time)
	if player.is_detected:
		PlayerActionTracker.times_dodged_in_combat += 1
	dodge_indicator.visible = true

#var how_long_dash_timer = 0

func process_dodge(delta):
	if dodge_timer > 0:
		dodge_timer -= delta
		# fixed speed to travel the distance in the set duration
		dodge_speed = dodge_distance / dodge_duration
		match GameManager.get_first_weapon():
			sword_name:
				if GameManager.get_second_weapon() == shield_name:
					dodge_speed = dodge_speed * dodge_strength_multiplier_shield
			staff_name:
				dodge_speed = dodge_speed * dodge_strength_multiplier_staff
			bow_name:
				dodge_speed = dodge_speed * dodge_strength_multiplier_bow
			shield_name:
				dodge_speed = dodge_speed * dodge_strength_multiplier_shield
		var vy = velocity.y
		velocity.y = 0
		velocity = dodge_direction * dodge_speed
		velocity.y = vy
		move_and_slide()
	else:
		#print(how_long_dash_timer)
		is_dodging = false
		GameManager.set_is_dodging(is_dodging)
		#velocity = Vector3.ZERO
		velocity = Vector3(0, velocity.y, 0)
		dodge_indicator.visible = false
		#how_long_dash_timer = 0

func block():
	if Input.is_action_pressed("block"):
		player.is_blocking = true
		GameManager.set_is_blocking(true)
	if Input.is_action_just_released("block"):
		player.is_blocking = false
		GameManager.set_is_blocking(false)
		

func rotate_player():
	match rotation_type:
		"rotate based on last movement":
			rotate_based_on_last_movement()
		"rotate based on second input":
			rotate_based_on_second_input()

func rotate_based_on_last_movement():
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if lock_active:
		lock = Input.is_action_pressed("lock_movement")
	if (input.x != 0 or input.y != 0) and !lock:
		temprotation = atan2(-input.x, -input.y)
	player_shape.rotation.y = temprotation

func rotate_based_on_second_input():
	var look_input = Input.get_vector("look_left", "look_right", "look_forward", "look_backward")
	if lock_active:
		lock = Input.is_action_pressed("lock_movement")
	if GameManager.get_controller_input_device():
		var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		if (input.x != 0 or input.y != 0):
			temprotation = atan2(-input.x, -input.y)
		if (look_input.x != 0 or look_input.y != 0):
			temprotation = atan2(-look_input.x, -look_input.y)
	else:
		var mouse_world_position = GameManager.get_mouse_ground_position_fixed(self)
		var direction = (mouse_world_position - global_position)
		direction.y = 0  # Y-Komponente ignorieren
		direction = -direction.normalized()
	
		if direction.length() > 0:
			# Direkte Rotation um Y-Achse
			var angle = atan2(direction.x, direction.z)
			temprotation = angle
	if !lock:
		# Locking rotation when using melee attack
		if GameManager.get_is_attacking() and GameManager.get_first_weapon_name() == "Sword":
			pass
		else:
			player_shape.rotation.y = temprotation

func get_move_input(delta):
	sneak_toggler()
	var vy = velocity.y
	velocity.y = 0
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward").normalized()
	var direction = Vector3(input.x, 0, input.y).rotated(Vector3.UP, spring_arm.rotation.y)
	var player_speed = player.speed
	if sneak_toggle:
		player_speed = player_speed / player.sneak_speed_modifier
	if GameManager.get_first_weapon_name() == bow_name and GameManager.get_is_attacking():
		player_speed = player_speed / player.sneak_speed_modifier
	velocity = lerp(velocity, direction * player_speed, acceleration * delta)
	velocity.y = vy
	if abs(input.x) < 0.01:
		velocity.x -= velocity.x * friction
	if abs(input.y) < 0.01:
		velocity.z -= velocity.z * friction

func sneak_toggler():
	if Input.is_action_just_pressed("sneak") and !GameManager.get_is_attacking():
		if sneak_toggle:
			sneak_toggle = false
			GameManager.set_is_sneaking(sneak_toggle)
			player.set_sneaking(false)
		else:
			sneak_toggle = true
			GameManager.set_is_sneaking(sneak_toggle)
			player.set_sneaking(true)

func apply_gravity(delta):
	velocity.y += -gravity * delta

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		_switch_to_controller()
	elif event is InputEventJoypadMotion:
		if abs(event.axis_value) > DEADZONE:
			_switch_to_controller()
	elif event is InputEventKey or event is InputEventMouse:
		_switch_to_kbm()

func _switch_to_controller():
	if GameManager.get_controller_input_device() != true:
		GameManager.set_controller_input_device(true)
		print("Switched to controller")
		
func _switch_to_kbm():
	if GameManager.get_controller_input_device() != false:
		GameManager.set_controller_input_device(false)
		print("Switched to keyboard/mouse")
