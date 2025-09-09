extends Node3D

# Attack and Block Animations, Attack Logic but Block Logic inside player_controller
# and player_stats scripts
# Weapons also have their own logics and can be found in their scenes/scripts

@export var animation_tree: AnimationTree
@export var player_controller: CharacterBody3D
@export var sword_hit_box: Area3D
@export var staff_bullet_spawn: Node3D
@export var bow_bullet_spawn: Node3D
@export var aim_helper: MeshInstance3D

@export var bow_charged_indicator: MeshInstance3D

var min_reset_animation_number: float = 0
var reset_animation_timer: float = 0

var max_sword_animation_timer_sword_attack_1_and_2: float = 0.8
var max_sword_animation_timer_sword_attack_3: float = 0.8
var combo_number: int = 0
var combo_timer: float = 0
var max_combo_timer_sword_attack_1: float = 0.5
var max_combo_timer_sword_attack_2: float = 0.3
var sword_rotation_timer: float = 0
var max_sword_rotation_timer: float = 0.02

var max_staff_animation_timer: float = 1.25
var mana_cost_per_attack: int = 60

var is_walking_bow: bool = false
var rel_vel_xz
var bow_aim_timer: float = 0
var max_bow_aim_timer: float = 0.33333
var bow_shot_timer: float = 0
var max_bow_shot_timer: float = 0.7
var bow_finished: bool = true
var bow_hold_timer_for_dmg: float = 0
var bow_dmg: float = 0

var use_block: bool = false

var sword_name = "Sword"
var shield_name = "Shield"
var staff_name = "Staff"
var bow_name = "Bow"

@onready var player: Node3D = GlobalPlayer.get_player()
@onready var movement_state_machine_playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")
@onready var sword_state_machine_playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine 2/playback")
@onready var staff_state_machine_playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine 3/playback")
@onready var walking_bow_state_machine_playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine 4/playback")
@onready var bow_state_machine_playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine 5/playback")
@onready var walking_block_state_machine_playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine 6/playback")
@onready var block_state_machine_playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine 7/playback")
@onready var sword_attack_blend = animation_tree.tree_root.get_node("SwordAnimation")
@onready var staff_attack_blend = animation_tree.tree_root.get_node("StaffAnimation")
@onready var bow_attack_blend = animation_tree.tree_root.get_node("BowAnimation")
@onready var block_blend = animation_tree.tree_root.get_node("BlockAnimation")

func _physics_process(delta: float) -> void:
	attacks(delta)
	block(delta)

func attacks(delta):
	if GameManager.get_first_weapon():
		var weapon_name = GameManager.get_first_weapon_name()
		match weapon_name:
			sword_name:
				sword_attack(delta)
			staff_name:
				staff_attack(delta)
			bow_name:
				bow_attack(delta)

#--------------------SWORD--------------------
func sword_attack(delta):
	if player_controller.velocity.length() > 0.2:
		sword_attack_blend.filter_enabled = true
	else:
		sword_attack_blend.filter_enabled = false
	if (
		Input.is_action_just_pressed("attack") 
		and !GameManager.get_is_dodging()
		and !GameManager.get_is_sneaking()
		and !GameManager.get_is_blocking()
		):
		set_sword_rotation_timer()
		sword_attack_1()
		sword_attack_2()
		sword_attack_3()
		GameManager.set_is_attacking(true)
	# Cancel Attack with Dodge or Block
	if (GameManager.get_is_dodging() or GameManager.get_is_blocking()) and GameManager.get_is_attacking():
		sword_attack_change_back_to_movement_animation()
		reset_animation_timer = min_reset_animation_number
	calc_reset_sword_animation_timer(delta)
	calc_combo_timer(delta)
	calc_sword_rotation_timer(delta)

func sword_attack_1():
	if combo_number == 0:
		animation_tree.set("parameters/SwordAnimation/blend_amount", 1)
		sword_state_machine_playback.travel("SwordAttack1")
		sword_hit_box.get_child(1).stop()
		sword_hit_box.get_child(1).play("Attack1")
		reset_animation_timer = max_sword_animation_timer_sword_attack_1_and_2
		combo_timer = max_combo_timer_sword_attack_1
		combo_number = 1

func sword_attack_2():
	if combo_number == 1 and combo_timer <= 0:
		sword_state_machine_playback.travel("SwordAttack2")
		sword_hit_box.get_child(1).stop()
		sword_hit_box.get_child(1).play("Attack2")
		reset_animation_timer = max_sword_animation_timer_sword_attack_1_and_2
		combo_timer = max_combo_timer_sword_attack_2
		combo_number = 2

func sword_attack_3():
	if combo_number == 2 and combo_timer <= 0:
		sword_state_machine_playback.travel("SwordAttack3")
		sword_hit_box.get_child(1).stop()
		sword_hit_box.get_child(1).play("Attack3")
		reset_animation_timer = max_sword_animation_timer_sword_attack_3
		combo_number = 3

func calc_reset_sword_animation_timer(delta):
	if combo_number == 1 or combo_number == 2 or combo_number == 3:
		if reset_animation_timer > 0:
			reset_animation_timer -= delta
		elif reset_animation_timer <= 0:
			sword_attack_change_back_to_movement_animation()

func calc_combo_timer(delta):
	if combo_timer > 0:
		combo_timer -= delta

func calc_sword_rotation_timer(delta):
	if sword_rotation_timer > 0:
		sword_rotation_timer -= delta
		if sword_rotation_timer <= 0 and !GameManager.get_is_sword_hit():
			GameManager.set_is_sword_hit(true)

func set_sword_rotation_timer():
	if combo_timer <= 0 and combo_number != 3:
		GameManager.set_is_sword_hit(false)
		sword_rotation_timer = max_sword_rotation_timer

func sword_attack_change_back_to_movement_animation():
	sword_state_machine_playback.travel("Rest")
	animation_tree.set("parameters/SwordAnimation/blend_amount", 0)
	sword_hit_box.get_child(1).stop()
	combo_number = 0
	GameManager.set_is_attacking(false)
	GameManager.set_is_sword_hit(false)

#--------------------STAFF--------------------
func staff_attack(delta):
	if player_controller.velocity.length() > 0.2:
		staff_attack_blend.filter_enabled = true
	else:
		staff_attack_blend.filter_enabled = false
	if (
		Input.is_action_pressed("attack")
		and !GameManager.get_is_dodging() 
		and !GameManager.get_is_sneaking()
		and !GameManager.get_is_blocking()
		and reset_animation_timer <= 0
		and player.mana >= mana_cost_per_attack
		):
		staff_attack_animation()
	# Cancel Attack with Dodge or Block
	if (GameManager.get_is_dodging() or GameManager.get_is_blocking()) and GameManager.get_is_attacking():
		staff_attack_change_back_to_movement_animation()
		reset_animation_timer = min_reset_animation_number
	calc_reset_staff_animation_timer(delta)

func staff_attack_animation():
	animation_tree.set("parameters/StaffAnimation/blend_amount", 1)
	staff_state_machine_playback.travel("MagicAttack")
	staff_bullet_spawn.get_child(0).play("MagicAttack")
	reset_animation_timer = max_staff_animation_timer
	GameManager.set_is_attacking(true)

func staff_attack_change_back_to_movement_animation():
	staff_state_machine_playback.travel("Rest")
	staff_bullet_spawn.get_child(0).stop()
	animation_tree.set("parameters/StaffAnimation/blend_amount", 0)
	GameManager.set_is_attacking(false)

func calc_reset_staff_animation_timer(delta):
	if GameManager.get_is_attacking():
		if reset_animation_timer > 0:
			reset_animation_timer -= delta
			if reset_animation_timer <= 0:
				staff_attack_change_back_to_movement_animation()

#--------------------BOW--------------------
func bow_attack(delta):
	if player_controller.velocity.length() > 0.2:
		bow_attack_blend.filter_enabled = true
	else:
		bow_attack_blend.filter_enabled = false
	# Cancel Attack with Dodge or Block
	if (
		(GameManager.get_is_dodging() 
		or GameManager.get_is_blocking())
		and GameManager.get_is_attacking()
		):
		bow_attack_change_back_to_movement_animation()
	elif (
		Input.is_action_pressed("attack") 
		and !GameManager.get_is_dodging()
		and !GameManager.get_is_sneaking()
		and !GameManager.get_is_blocking()
		and bow_finished
		):
		walking_bow_and_hold_aim_animation()
		bow_aim_animation()
		calc_bow_hold_timer_for_dmg(delta)
	elif (
		(Input.is_action_just_released("attack")
		or !Input.is_action_pressed("attack"))
		and GameManager.get_is_attacking()
		and !GameManager.get_is_dodging()
		and !GameManager.get_is_sneaking()
		and !GameManager.get_is_blocking()
		and bow_aim_timer <= 0
		and bow_finished
		):
		bow_shot_animation()
	else:
		if is_walking_bow and bow_aim_timer <= 0 and bow_shot_timer <= 0:
			bow_attack_change_back_to_movement_animation()
	calc_bow_timers(delta)

func bow_aim_animation():
	if bow_aim_timer <= 0 and !GameManager.get_is_attacking():
		GameManager.set_is_attacking(true)
		bow_aim_timer = max_bow_aim_timer
		animation_tree.set("parameters/BowAnimation/blend_amount", 1)
		bow_state_machine_playback.travel("Bow Aim")
	elif bow_aim_timer <= 0 and GameManager.get_is_attacking():
		animation_tree.set("parameters/BowAnimation/blend_amount", 0)

func bow_shot_animation():
	animation_tree.set("parameters/BowAnimation/blend_amount", 1)
	bow_state_machine_playback.travel("Bow Shoot")
	bow_shot_timer = max_bow_shot_timer
	bow_finished = false
	aim_helper.visible = false
	bow_charged_indicator.visible = false
	calc_dmg_for_arrow(bow_hold_timer_for_dmg)
	GameManager.set_bow_attack_timer(bow_dmg)
	bow_bullet_spawn.spawn_bullet()

func calc_bow_timers(delta):
	if bow_aim_timer > 0:
		bow_aim_timer -= delta
	if bow_shot_timer > 0:
		bow_shot_timer -= delta

func walking_bow_and_hold_aim_animation():
	if !is_walking_bow:
		is_walking_bow = true
	if !GameManager.get_controller_input_device():
		walking_bow_and_hold_aim_with_kbm()
	elif GameManager.get_controller_input_device():
		walking_bow_and_hold_aim_with_controller()

func bow_attack_change_back_to_movement_animation():
	if GameManager.get_controller_input_device():
		aim_helper.visible = false
	is_walking_bow = false
	bow_finished = true
	bow_hold_timer_for_dmg = 0
	bow_dmg = 0
	animation_tree.set("parameters/BowWalkingAnimation/blend_amount", 0)
	animation_tree.set("parameters/BowAnimation/blend_amount", 0)
	bow_state_machine_playback.travel("Rest")
	GameManager.set_is_attacking(false)

func calc_bow_hold_timer_for_dmg(delta):
	if bow_hold_timer_for_dmg >= 0 and bow_hold_timer_for_dmg <= 3:
		bow_hold_timer_for_dmg += delta
	if bow_hold_timer_for_dmg > 0.1:
		aim_helper_active()
	if bow_hold_timer_for_dmg >= 3:
		bow_charged_indicator.visible = true

func calc_dmg_for_arrow(calc_bow_hold_timer_for_dmg):
	if calc_bow_hold_timer_for_dmg <= 0.3:
		bow_dmg = 1
	elif calc_bow_hold_timer_for_dmg > 0.3:
		bow_dmg = bow_dmg + 1 + calc_bow_hold_timer_for_dmg

func aim_helper_active():
	if GameManager.get_controller_input_device():
		aim_helper.visible = true

func walking_bow_and_hold_aim_with_kbm():
	animation_tree.set("parameters/BowWalkingAnimation/blend_amount", 1)
	walking_bow_state_machine_playback.travel("BowWalking")
	rel_vel_xz = animation_tree.rel_vel_xz
	animation_tree.set("parameters/StateMachine 4/BowWalking/blend_position", rel_vel_xz)

func walking_bow_and_hold_aim_with_controller():
	var look_input = Input.get_vector("look_left", "look_right", "look_forward", "look_backward")
	# Using the Right Stick and Left Stick
	if (look_input.x != 0 or look_input.y != 0):
		walking_bow_and_hold_aim_with_kbm()
	# Using the Left Stick only
	else:
		animation_tree.set("parameters/BowWalkingAnimation/blend_amount", 1)
		var move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		if (move_input.x != 0 or move_input.y != 0):
			walking_bow_state_machine_playback.travel("Bow Aim Forward")
		else: 
			walking_bow_state_machine_playback.travel("Bow Aim Hold")

#--------------------BLOCK--------------------
func block(delta):
	if GameManager.get_is_blocking() and GameManager.get_is_dodging():
		block_change_back_to_movement_animation()
	elif GameManager.get_is_blocking() and !GameManager.get_is_dodging():
		if player_controller.velocity.length() > 0.2:
			block_blend.filter_enabled = true
		else:
			block_blend.filter_enabled = false
		use_block = true
		block_walking_animation()
		if GameManager.get_first_weapon_name() == sword_name or GameManager.get_first_weapon_name() == staff_name:
			if GameManager.get_first_weapon_name() == sword_name and GameManager.get_second_weapon_name() == shield_name:
				left_block_animation()
			else:
				right_block_animation()
		if GameManager.get_first_weapon_name() == bow_name or GameManager.get_first_weapon_name() == shield_name:
			left_block_animation()
	elif !GameManager.get_is_blocking() and use_block:
		block_change_back_to_movement_animation()

func block_walking_animation():
	animation_tree.set("parameters/WalkBlockAnimation/blend_amount", 1)
	walking_block_state_machine_playback.travel("BlockWalking")
	rel_vel_xz = animation_tree.rel_vel_xz
	animation_tree.set("parameters/StateMachine 6/BlockWalking/blend_position", rel_vel_xz)

func block_change_back_to_movement_animation():
	use_block = false
	animation_tree.set("parameters/BlockAnimation/blend_amount", 0)
	block_state_machine_playback.travel("Rest")
	animation_tree.set("parameters/WalkBlockAnimation/blend_amount", 0)

func right_block_animation():
	animation_tree.set("parameters/BlockAnimation/blend_amount", 1)
	block_state_machine_playback.travel("Block_R")

func left_block_animation():
	animation_tree.set("parameters/BlockAnimation/blend_amount", 1)
	block_state_machine_playback.travel("Block_L")
