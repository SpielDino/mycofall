extends AnimationTree

const DEADZONE := 0.2

@export var player_controller: CharacterBody3D
@export var front_pointer: MeshInstance3D
@export var player_shape: CollisionShape3D

var rotation_front_pointer
var rel_vel
var rel_vel_xz
var bow_name = "Bow"

var current_blend := Vector2.ZERO
var stop_rotation_during_dodge = false
var controller_dodge = false
var sneak_dodge = false
var controller_move = false
var kbm_move = false
var normal_dodge = false

var timer_bs: float = 0

@onready var settings: Node3D = GlobalPlayer.get_player()
@onready var state_machine_playback: AnimationNodeStateMachinePlayback = self.get("parameters/StateMachine/playback")

@onready var stamina_cost_per_dodge = settings.stamina_cost_per_dodge
@onready var max_stamina = settings.max_stamina

func _ready():
	# Connect to the global signal
	GameManager.weapons_changed.connect(_on_weapons_changed)

func _physics_process(delta: float) -> void:
	update_animation(delta)

func update_animation(delta):
	get_rel_vel()
	movement_animation(delta)

func movement_animation(delta):
	toogle_sneak_animation()
	dodge_animation_while_sneak(delta)
	sneak_animation()
	dodge_animation()
	walking_animation()

func toogle_sneak_animation():
	if (
		Input.is_action_just_pressed("sneak")
		and !GameManager.get_is_dodging() 
		and !GameManager.get_is_attacking() 
		and !GameManager.get_is_blocking()
		):
		if GameManager.get_is_sneaking():
			state_machine_playback.travel("Sneaking")
		elif !GameManager.get_is_sneaking():
			state_machine_playback.travel("Walking")

func sneak_animation():
	if GameManager.get_is_sneaking() and !GameManager.get_is_dodging():
		calc_right_direction_based_on_rotation()
		if sneak_dodge:
			sneak_dodge = false
		self.set("parameters/StateMachine/Sneaking/blend_position", rel_vel_xz)
		stop_rotation_during_dodge_false()

func dodge_animation_while_sneak(delta):
	if GameManager.get_is_sneaking() and GameManager.get_is_dodging():
		rotate_based_on_last_movement()
		if !sneak_dodge:
			state_machine_playback.travel("DodgeSneak")
			sneak_dodge = true
		stop_rotation_during_dodge_true()

func dodge_animation():
	if !GameManager.get_is_sneaking() and GameManager.get_is_dodging():
		rotate_based_on_last_movement()
		if !controller_dodge:
			if !normal_dodge:
				state_machine_playback.travel("Dodge")
				normal_dodge = true
		elif controller_dodge:
			if !normal_dodge:
				state_machine_playback.travel("DodgeController")
				normal_dodge = true
		stop_rotation_during_dodge_true()

func rotate_based_on_last_movement():
	if !stop_rotation_during_dodge:
		var temprotation = 0
		var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		if (input.x != 0 or input.y != 0):
			temprotation = atan2(-input.x, -input.y)
			player_shape.rotation.y = temprotation

func walking_animation_keyboard_and_mouse():
	if !GameManager.get_is_sneaking() and !GameManager.get_is_dodging() and !GameManager.get_controller_input_device():
		rotation_front_pointer = rotation_of_front_pointer()
		state_machine_playback.travel("Walking")
		var target_blend: Vector2
		#Looking North
		if rotation_front_pointer <= 70 and rotation_front_pointer >= -70:
			target_blend = rel_vel_xz
		#Looking South
		elif rotation_front_pointer >= 130 or rotation_front_pointer <= -130:
			target_blend = Vector2(-rel_vel.x, -rel_vel.z)
		#Looking West
		elif rotation_front_pointer > 70:
			target_blend = Vector2(-rel_vel.z, rel_vel.x)
		#Looking East
		else:
			target_blend = Vector2(rel_vel.z, -rel_vel.x)
		stop_rotation_during_dodge_false()

		current_blend = current_blend.lerp(target_blend, 0.1) 
		self.set("parameters/StateMachine/Walking/blend_position", current_blend)

func walking_animation_keyboard_and_mouse_2():
	if !GameManager.get_controller_input_device():
		rotate_animation_based_on_look_direction()
		stop_rotation_during_dodge_false()

func walking_animation_controller():
	if GameManager.get_controller_input_device():
		var look_input = Input.get_vector("look_left", "look_right", "look_forward", "look_backward")
		# Using the Right Stick and Left Stick
		if (look_input.x != 0 or look_input.y != 0):
			rotate_animation_based_on_look_direction()
		# Using the Left Stick only
		else:
			calc_right_direction_based_on_rotation()
			var move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
			if !controller_move and (move_input.x != 0 or move_input.y != 0):
				state_machine_playback.travel("WalkingController")
				controller_move = true
			self.set("parameters/StateMachine/WalkingController/blend_position", rel_vel_xz)
			self.set("parameters/StateMachine/Walking/blend_position", rel_vel_xz)
			controller_dodge_true()
			if kbm_move:
				kbm_move = false
		stop_rotation_during_dodge_false()

func rotate_animation_based_on_look_direction():
	controller_dodge_false()
	calc_right_direction_based_on_rotation()
	if GameManager.get_first_weapon_name() == bow_name and GameManager.get_is_attacking():
		pass
	else:
		var move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		if !kbm_move and (move_input.x != 0 or move_input.y != 0):
			state_machine_playback.travel("Walking")
			kbm_move = true
		self.set("parameters/StateMachine/Walking/blend_position", rel_vel_xz)
		if controller_move:
			controller_move = false

func walking_animation():
	if !GameManager.get_is_heavy_attacking() and !GameManager.get_is_dodging() and !GameManager.get_is_sneaking():
		walking_animation_controller()
		walking_animation_keyboard_and_mouse_2()
		if normal_dodge:
			normal_dodge = false

func stop_rotation_during_dodge_true():
	if !stop_rotation_during_dodge:
		stop_rotation_during_dodge = true

func stop_rotation_during_dodge_false():
	if stop_rotation_during_dodge:
		stop_rotation_during_dodge = false

func controller_dodge_true():
	if !controller_dodge:
		controller_dodge = true

func controller_dodge_false():
	if controller_dodge:
		controller_dodge = false

func get_rel_vel():
	rel_vel = player_controller.global_basis.inverse() * ((player_controller.velocity * Vector3(1,0,1)))
	rel_vel_xz = Vector2(rel_vel.x, rel_vel.z)

func rotation_of_front_pointer():
	var radians_y = front_pointer.global_transform.basis.get_euler().y
	var degrees_y = rad_to_deg(radians_y)
	rotation_front_pointer = round(degrees_y)
	return rotation_front_pointer

func play_wood_crystal_staff_animation():
	if GameManager.get_first_weapon_name() == "Staff" and GameManager.get_first_weapon_upgrade_level() == 1:
		self.set("parameters/CrystalStaffAnimation/blend_amount", 1)
		self.set("parameters/MainOrBackCrystalStaffAnimation/blend_amount", 0)
	elif GameManager.get_second_weapon_name() == "Staff" and GameManager.get_second_weapon_upgrade_level() == 1:
		self.set("parameters/CrystalStaffAnimation/blend_amount", 1)
		self.set("parameters/MainOrBackCrystalStaffAnimation/blend_amount", 1)
	else:
		self.set("parameters/CrystalStaffAnimation/blend_amount", 0)

func _on_weapons_changed():
	play_wood_crystal_staff_animation()

func calc_right_direction_based_on_rotation():
	rotation_front_pointer = rotation_of_front_pointer()
	# Numbers are degrees, left side positive, right side negative
	#Looking North
	if rotation_front_pointer <= 50 and rotation_front_pointer >= -50:
		pass
	#Looking South
	elif rotation_front_pointer > 130 and rotation_front_pointer <= 180 or rotation_front_pointer < -130 and rotation_front_pointer >= -180:
		rel_vel_xz = Vector2(-rel_vel.x, -rel_vel.z)
	#Looking West
	elif rotation_front_pointer > 50 and rotation_front_pointer <= 130:
		rel_vel_xz = Vector2(-rel_vel.z, rel_vel.x)
	#Looking East
	elif rotation_front_pointer < -50 and rotation_front_pointer >= -130:
		rel_vel_xz = Vector2(rel_vel.z, -rel_vel.x)
