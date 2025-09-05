extends AnimationTree

const DEADZONE := 0.2

@export var player_controller: CharacterBody3D
@export var front_pointer: MeshInstance3D
@export var player_shape: CollisionShape3D

var rotation_front_pointer
var rel_vel
var rel_vel_xz
var controller_input_device

var current_blend := Vector2.ZERO
var stop_rotation_during_dodge = false
var controller_dodge = false

@onready var settings: Node3D = GlobalPlayer.get_player()
@onready var state_machine_playback: AnimationNodeStateMachinePlayback = self.get("parameters/StateMachine/playback")
@onready var stamina_cost_per_dodge = settings.stamina_cost_per_dodge
@onready var max_stamina = settings.max_stamina

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		_switch_to_controller()
	elif event is InputEventJoypadMotion:
		if abs(event.axis_value) > DEADZONE:
			_switch_to_controller()
	elif event is InputEventKey or event is InputEventMouse:
		_switch_to_kbm()

func _switch_to_controller():
	if controller_input_device != true:
		controller_input_device = true
		print("Switched to controller")

func _switch_to_kbm():
	if controller_input_device != false:
		controller_input_device = false
		print("Switched to keyboard/mouse")

func _physics_process(delta: float) -> void:
	update_animation(delta)

func update_animation(delta):
	get_rel_vel()
	movement_animation()

func movement_animation():
	toogle_sneak_animation()
	dodge_animation_while_sneak()
	sneak_animation()
	dodge_animation()
	walking_animation()

func toogle_sneak_animation():
	if !GameManager.get_is_sneaking() and !GameManager.get_is_dodging() and !GameManager.get_is_attacking():
		state_machine_playback.travel("Sneaking")
	elif GameManager.get_is_sneaking() and !GameManager.get_is_dodging() and !GameManager.get_is_attacking():
		state_machine_playback.travel("Walking")

func sneak_animation():
	if GameManager.get_is_sneaking() and !GameManager.get_is_dodging():
		state_machine_playback.travel("Sneaking")
		self.set("parameters/StateMachine/Sneaking/blend_position", rel_vel_xz)
		stop_rotation_during_dodge_false()

func dodge_animation_while_sneak():
	if GameManager.get_is_sneaking() and GameManager.get_is_dodging():
		rotate_based_on_last_movement()
		state_machine_playback.travel("DodgeSneak")
		stop_rotation_during_dodge_true()

func dodge_animation():
	if !GameManager.get_is_sneaking() and GameManager.get_is_dodging():
		rotate_based_on_last_movement()
		if !controller_dodge_true:
			state_machine_playback.travel("Dodge")
		elif controller_dodge_false:
			state_machine_playback.travel("DodgeController")
		stop_rotation_during_dodge_true()

func rotate_based_on_last_movement():
	if !stop_rotation_during_dodge:
		var temprotation = 0
		var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		if (input.x != 0 or input.y != 0):
			temprotation = atan2(-input.x, -input.y)
			player_shape.rotation.y = temprotation

func walking_animation_keyboard_and_mouse():
	if !GameManager.get_is_sneaking() and !GameManager.get_is_dodging() and !controller_input_device:
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
	if !GameManager.get_is_sneaking() and !GameManager.get_is_dodging() and !controller_input_device:
		rotate_animation_based_on_look_direction()
		stop_rotation_during_dodge_false()

func walking_animation_controller():
	if !GameManager.get_is_sneaking() and !GameManager.get_is_dodging() and controller_input_device:
		var look_input = Input.get_vector("look_left", "look_right", "look_forward", "look_backward")
		# Using the Right Stick and Left Stick
		if (look_input.x != 0 or look_input.y != 0):
			rotate_animation_based_on_look_direction()
		# Using the Left Stick only
		else:
			var move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
			if (move_input.x != 0 or move_input.y != 0):
				state_machine_playback.travel("WalkingController")
			else: 
				state_machine_playback.travel("IdleController")
			controller_dodge_true()
		stop_rotation_during_dodge_false()

func rotate_animation_based_on_look_direction():
	controller_dodge_false()
	rotation_front_pointer = rotation_of_front_pointer()
	state_machine_playback.travel("Walking")
	# Numbers are degrees, left side positive, right side negative
	#Looking North
	if rotation_front_pointer <= 70 and rotation_front_pointer >= -70:
		self.set("parameters/StateMachine/Walking/blend_position", rel_vel_xz)
	#Looking South
	elif rotation_front_pointer > 130 and rotation_front_pointer <= 180 or rotation_front_pointer < -130 and rotation_front_pointer >= -180:
		rel_vel_xz = Vector2(-rel_vel.x, -rel_vel.z)
		self.set("parameters/StateMachine/Walking/blend_position", rel_vel_xz)
	#Looking West
	elif rotation_front_pointer > 70 and rotation_front_pointer <= 130:
		rel_vel_xz = Vector2(-rel_vel.z, rel_vel.x)
		self.set("parameters/StateMachine/Walking/blend_position", rel_vel_xz)
	#Looking East
	elif rotation_front_pointer < -70 and rotation_front_pointer >= -130:
		rel_vel_xz = Vector2(rel_vel.z, -rel_vel.x)
		self.set("parameters/StateMachine/Walking/blend_position", rel_vel_xz)

func walking_animation():
	walking_animation_controller()
	walking_animation_keyboard_and_mouse_2()

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
