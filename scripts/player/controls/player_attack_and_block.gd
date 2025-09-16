extends Node3D

# Attack and Block Animations, Attack Logic but Block Logic inside player_controller
# and player_stats scripts
# Weapons also have their own logics and can be found in their scenes/scripts

@export_category("Important Nodes")
@export_subgroup("Logic Nodes")
@export var animation_tree: AnimationTree
@export var player_controller: CharacterBody3D
@export var sword_hit_box: Area3D
@export var shield_hix_box: Area3D
@export var staff_bullet_spawn: Node3D
@export var bow_bullet_spawn: Node3D
@export var aim_helper: MeshInstance3D
@export var bow_charged_indicator: MeshInstance3D

@export_category("Heavy Attack Cooldowns")
@export_subgroup("Sword")
@export var max_cooldown_heavy_attack_sword: float = 1
@export_subgroup("Staff")
@export var max_cooldown_heavy_attack_staff: float = 1
@export_subgroup("Bow")
@export var max_cooldown_heavy_attack_bow: float = 1
@export_subgroup("Shield")
@export var max_cooldown_heavy_attack_shield: float = 1

var min_reset_animation_number: float = 0
var reset_animation_timer: float = 0

#--------------------SWORD--------------------
var max_sword_animation_timer_sword_attack_1_and_2: float = 0.8
var max_sword_animation_timer_sword_attack_3: float = 0.8
var max_sword_animation_timer_sword_heavy_attack: float = 1.6667
var combo_number: int = 0
var combo_timer: float = 0
var max_combo_timer_sword_attack_1: float = 0.5
var max_combo_timer_sword_attack_2: float = 0.3
var max_combo_timer_sword_attack_3: float = 0.4
var sword_rotation_timer: float = 0
var max_sword_rotation_timer: float = 0.02
var max_sword_heavy_attack_rotation_timer: float = 1
var cooldown_heavy_attack_sword_timer: float = 0

#--------------------STAFF--------------------
var max_staff_animation_timer: float = 1.25
var mana_cost_per_attack: int = 60
var heavy_attack_staff_animation_timer: float = 0
var max_heavy_attack_staff_animation_timer: float = 1.6667
var cooldown_heavy_attack_staff_timer: float = 0
var staff_combo: int = 0
var reset_staff_animation_timer: float = 0
var delay_reset: float = 0.1

#--------------------BOW--------------------
var is_walking_bow: bool = false
var rel_vel_xz
var bow_aim_timer: float = 0
var max_bow_aim_timer: float = 0.33333
var bow_shot_timer: float = 0
var max_bow_shot_timer: float = 0.7
var bow_finished: bool = true
var bow_hold_timer_for_dmg: float = 0
var bow_dmg: float = 0
var heavy_attack_bow_animation_timer: float = 0
var max_heavy_attack_bow_animation_timer: float = 1.1 #1.25
var cooldown_heavy_attack_bow_timer: float = 0
var max_fix_aim_animation_during_walking_timer: float = 0.25
var fix_aim_animation_during_walking_timer: float = max_fix_aim_animation_during_walking_timer
var delay_reset_animations_timer: float = 0
var delay_reset_animations: bool = false
var max_delay_reset_animations_timer = 0.05
var walking_bow_kbm: bool = false
var walking_bow_controller: bool = false

#--------------------BLOCK--------------------
var use_block: bool = false

#--------------------SHIELD--------------------
var heavy_attack_shield_animation_timer: float = 0
var max_heavy_attack_shield_animation_timer: float = 0.8
var cooldown_heavy_attack_shield_timer: float = 0

#--------------------ETC--------------------
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
	if !GameManager.get_is_knockdown():
		attacks(delta)
		block()
	else:
		knockdown_reset_attack_and_block_animations(delta)

func attacks(delta):
	if GameManager.get_first_weapon():
		var weapon_name = GameManager.get_first_weapon_name()
		match weapon_name:
			sword_name:
				if GameManager.get_second_weapon_name() == shield_name:
					shield_heavy_attack(delta)
				if !GameManager.get_is_heavy_attack_shield_with_sword():
					sword_attack(delta)
			staff_name:
				staff_attack(delta)
			bow_name:
				bow_attack(delta)
			shield_name:
				shield_heavy_attack(delta)
		calc_cooldowns_for_heavy_attacks(delta)

func calc_cooldowns_for_heavy_attacks(delta):
	calc_cooldown_sword_heavy_attack(delta)
	calc_cooldown_staff_heavy_attack(delta)
	calc_cooldown_bow_heavy_attack(delta)
	calc_cooldown_heavy_attack_shield_timer(delta)

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
		and !GameManager.get_is_heavy_attacking()
		):
		set_sword_rotation_timer(max_sword_rotation_timer)
		sword_attack_1()
		sword_attack_2()
		sword_attack_3()
		GameManager.set_is_attacking(true)
	elif (
		Input.is_action_just_pressed("heavy_attack")
		and !GameManager.get_is_dodging()
		and !GameManager.get_is_sneaking()
		and !GameManager.get_is_blocking()
		and !GameManager.get_is_heavy_attacking()
		and combo_timer <= 0
		and cooldown_heavy_attack_sword_timer <= 0
		):
		sword_heavy_attack()
	# Cancel Attack with Dodge or Block
	if (GameManager.get_is_dodging() or GameManager.get_is_blocking()) and GameManager.get_is_attacking():
		sword_attack_change_back_to_movement_animation()
		reset_animation_timer = min_reset_animation_number
	calc_sword_timers(delta)

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
		combo_timer = max_combo_timer_sword_attack_3
		combo_number = 3

func sword_heavy_attack():
	GameManager.set_is_heavy_attacking(true)
	GameManager.set_is_attacking(true)
	set_sword_rotation_timer(max_sword_heavy_attack_rotation_timer)
	animation_tree.set("parameters/SwordAnimation/blend_amount", 1)
	sword_state_machine_playback.travel("Sword Heavy")
	sword_hit_box.get_child(1).stop()
	sword_hit_box.get_child(1).play("HeavyAttack")
	reset_animation_timer = max_sword_animation_timer_sword_heavy_attack

func calc_reset_sword_animation_timer(delta):
	if (
		combo_number == 1 
		or combo_number == 2 
		or combo_number == 3 
		or GameManager.get_is_heavy_attacking()
		):
		if reset_animation_timer > 0:
			reset_animation_timer -= delta
		if reset_animation_timer <= 0:
			sword_attack_change_back_to_movement_animation()

func calc_combo_timer(delta):
	if combo_timer > 0:
		combo_timer -= delta

func calc_sword_rotation_timer(delta):
	if sword_rotation_timer > 0:
		sword_rotation_timer -= delta
		if sword_rotation_timer <= 0 and !GameManager.get_is_sword_hit():
			GameManager.set_is_sword_hit(true)

func set_sword_rotation_timer(check):
	if combo_timer <= 0 and (combo_number != 3 or GameManager.get_is_heavy_attacking()):
		GameManager.set_is_sword_hit(false)
		sword_rotation_timer = check

func calc_cooldown_sword_heavy_attack(delta):
	if cooldown_heavy_attack_sword_timer > 0:
		cooldown_heavy_attack_sword_timer -= delta

func sword_attack_change_back_to_movement_animation():
	sword_state_machine_playback.travel("Rest")
	animation_tree.set("parameters/SwordAnimation/blend_amount", 0)
	sword_hit_box.get_child(1).stop()
	combo_number = 0
	GameManager.set_is_attacking(false)
	GameManager.set_is_sword_hit(false)
	if GameManager.get_is_heavy_attacking():
		cooldown_heavy_attack_sword_timer = max_cooldown_heavy_attack_sword
		GameManager.set_is_heavy_attacking(false)

func calc_sword_timers(delta):
	calc_reset_sword_animation_timer(delta)
	calc_combo_timer(delta)
	calc_sword_rotation_timer(delta)

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
		and !GameManager.get_is_heavy_attacking()
		#and !GameManager.get_is_attacking()
		and reset_animation_timer <= 0
		and player.mana >= mana_cost_per_attack
		):
		staff_attack_animation()
	elif (
		Input.is_action_pressed("heavy_attack")
		and !GameManager.get_is_dodging() 
		and !GameManager.get_is_sneaking()
		and !GameManager.get_is_blocking()
		and !GameManager.get_is_heavy_attacking()
		and !GameManager.get_is_attacking()
		and cooldown_heavy_attack_staff_timer <= 0
		):
		staff_heavy_attack_animation()
	# Cancel Attack with Dodge or Block
	if (
		(GameManager.get_is_dodging() or GameManager.get_is_blocking()) 
		and GameManager.get_is_attacking()
		):
		staff_attack_change_back_to_movement_animation()
		reset_animation_timer = min_reset_animation_number
		reset_staff_animation_timer = min_reset_animation_number
	calc_reset_staff_animation_timer(delta)

func staff_attack_animation():
	if staff_combo == 0:
		animation_tree.set("parameters/StaffAnimation/blend_amount", 1)
		staff_state_machine_playback.travel("MagicAttack")
		staff_bullet_spawn.get_child(0).play("MagicAttack")
		reset_animation_timer = max_staff_animation_timer
		reset_staff_animation_timer = max_staff_animation_timer + delay_reset
		GameManager.set_is_attacking(true)
		staff_combo = 1
	elif staff_combo == 1:
		animation_tree.set("parameters/StaffAnimation/blend_amount", 1)
		staff_state_machine_playback.travel("MagicAttack 2")
		staff_bullet_spawn.get_child(0).play("MagicAttack")
		reset_animation_timer = max_staff_animation_timer
		reset_staff_animation_timer = max_staff_animation_timer + delay_reset
		GameManager.set_is_attacking(true)
		staff_combo = 0

func staff_attack_change_back_to_movement_animation():
	animation_tree.set("parameters/StaffAnimation/blend_amount", 0)
	staff_state_machine_playback.travel("Rest")
	staff_bullet_spawn.get_child(0).stop()
	staff_combo = 0
	GameManager.set_is_attacking(false)

func heavy_staff_attack_change_back_to_movement_animation():
	reset_all_attack_staff_animation()
	rel_vel_xz = animation_tree.rel_vel_xz
	animation_tree.set("parameters/StateMachine/Walking/blend_position", rel_vel_xz)
	animation_tree.set("parameters/StateMachine/WalkingController/blend_position", rel_vel_xz)

func reset_all_attack_staff_animation():
	staff_attack_change_back_to_movement_animation()
	if GameManager.get_is_heavy_attacking():
		GameManager.set_is_heavy_attacking(false)
		cooldown_heavy_attack_staff_timer = max_cooldown_heavy_attack_staff

func calc_reset_staff_animation_timer(delta):
		# Resets Logic of Staff Attack
		if reset_animation_timer > 0:
			reset_animation_timer -= delta
		# Resets Animation of Staff Attack, this is delayed so animations can be
		# smoother
		if reset_staff_animation_timer > 0:
			reset_staff_animation_timer -= delta
			if reset_staff_animation_timer <= 0:
				staff_attack_change_back_to_movement_animation()
		elif heavy_attack_staff_animation_timer > 0:
			heavy_attack_staff_animation_timer -= delta
			if heavy_attack_staff_animation_timer <= 0:
				heavy_staff_attack_change_back_to_movement_animation()

func calc_cooldown_staff_heavy_attack(delta):
	if heavy_attack_staff_animation_timer <= 0 and cooldown_heavy_attack_staff_timer > 0:
		cooldown_heavy_attack_staff_timer -= delta

func staff_heavy_attack_animation():
	animation_tree.set("parameters/StaffAnimation/blend_amount", 1)
	staff_state_machine_playback.travel("MagicAOE")
	staff_bullet_spawn.get_child(0).play("HeavyAttack")
	heavy_attack_staff_animation_timer = max_heavy_attack_staff_animation_timer
	GameManager.set_is_attacking(true)
	GameManager.set_is_heavy_attacking(true)

#--------------------BOW--------------------
func bow_attack(delta):
	if (
		player_controller.velocity.length() > 0.2 
		and !GameManager.get_is_heavy_attacking() 
		and bow_finished 
		and fix_aim_animation_during_walking_timer <= 0
		):
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
		delay_reset_bow_shot_animation()
	elif (
		Input.is_action_pressed("attack") 
		and !GameManager.get_is_dodging()
		and !GameManager.get_is_sneaking()
		and !GameManager.get_is_blocking()
		and !GameManager.get_is_heavy_attacking()
		and bow_finished
		):
		bow_aim_animation()
		walking_bow_and_hold_aim_animation()
		calc_bow_hold_timer_for_dmg(delta)
	elif (
		(Input.is_action_just_released("attack")
		or !Input.is_action_pressed("attack"))
		and GameManager.get_is_attacking()
		and !GameManager.get_is_dodging()
		and !GameManager.get_is_sneaking()
		and !GameManager.get_is_blocking()
		and !GameManager.get_is_heavy_attacking()
		and bow_aim_timer <= 0
		and bow_finished
		):
		bow_shot_animation()
	elif (
		Input.is_action_pressed("heavy_attack")
		and !GameManager.get_is_dodging() 
		and !GameManager.get_is_sneaking()
		and !GameManager.get_is_blocking()
		and !GameManager.get_is_attacking()
		and cooldown_heavy_attack_bow_timer <= 0
		):
		bow_shotgun_animation()
	else:
		reset_bow_animations()
	
	# Delay Reset Animation for better Animation Flow
	if delay_reset_animations_timer <= 0 and delay_reset_animations and !GameManager.get_is_attacking():
		delay_reset_bow_shot_animation()
	
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
	#bow_charged_indicator.visible = false
	calc_dmg_for_arrow(bow_hold_timer_for_dmg)
	GameManager.set_bow_attack_timer(bow_dmg)
	bow_bullet_spawn.spawn_bullet()

func calc_bow_timers(delta):
	if bow_aim_timer > 0:
		bow_aim_timer -= delta
	if bow_shot_timer > 0:
		bow_shot_timer -= delta
	if heavy_attack_bow_animation_timer > 0:
		heavy_attack_bow_animation_timer -= delta
	if fix_aim_animation_during_walking_timer > 0 and GameManager.get_is_attacking():
		fix_aim_animation_during_walking_timer -= delta
	if delay_reset_animations_timer > 0:
		delay_reset_animations_timer -= delta

func calc_cooldown_bow_heavy_attack(delta):
	if cooldown_heavy_attack_bow_timer > 0:
		cooldown_heavy_attack_bow_timer -= delta

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
	walking_bow_state_machine_playback.travel("Rest")
	GameManager.set_is_attacking(false)
	fix_aim_animation_during_walking_timer = max_fix_aim_animation_during_walking_timer
	delay_reset_animations_timer = max_delay_reset_animations_timer
	delay_reset_animations = true
	walking_bow_kbm = false
	walking_bow_controller = false

func delay_reset_bow_shot_animation():
	animation_tree.set("parameters/BowAnimation/blend_amount", 0)
	bow_state_machine_playback.travel("Rest")
	delay_reset_animations = false

func calc_bow_hold_timer_for_dmg(delta):
	if bow_hold_timer_for_dmg >= 0 and bow_hold_timer_for_dmg <= 3:
		bow_hold_timer_for_dmg += delta
	if bow_hold_timer_for_dmg > 0.1:
		aim_helper_active()
	if bow_hold_timer_for_dmg >= 3:
		#bow_charged_indicator.visible = true
		pass

func calc_dmg_for_arrow(check):
	if check <= 0.3:
		bow_dmg = 1
	elif check > 0.3:
		bow_dmg = bow_dmg + 1 + check

func aim_helper_active():
	if GameManager.get_controller_input_device():
		aim_helper.visible = true

func walking_bow_and_hold_aim_with_kbm():
	if !walking_bow_kbm:
		animation_tree.set("parameters/BowWalkingAnimation/blend_amount", 1)
		walking_bow_state_machine_playback.travel("BowWalking")
		walking_bow_kbm = true
	rel_vel_xz = animation_tree.rel_vel_xz
	animation_tree.set("parameters/StateMachine 4/BowWalking/blend_position", rel_vel_xz)
	if walking_bow_controller:
		walking_bow_controller = false

func walking_bow_and_hold_aim_with_controller():
	var look_input = Input.get_vector("look_left", "look_right", "look_forward", "look_backward")
	# Using the Right Stick and Left Stick
	if (look_input.x != 0 or look_input.y != 0):
		walking_bow_and_hold_aim_with_kbm()
	# Using the Left Stick only
	else:
		animation_tree.set("parameters/BowWalkingAnimation/blend_amount", 1)
		var move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		rel_vel_xz = animation_tree.rel_vel_xz
		animation_tree.set("parameters/StateMachine 4/BowWalking/blend_position", rel_vel_xz)
		if (move_input.x != 0 or move_input.y != 0) and !walking_bow_controller:
			walking_bow_state_machine_playback.travel("Bow Aim Forward")
			walking_bow_controller = true
		elif (move_input.x == 0 and move_input.y == 0) and walking_bow_controller: 
			walking_bow_state_machine_playback.travel("Bow Aim Hold")
			walking_bow_controller = false
		if walking_bow_kbm:
			walking_bow_kbm = false

func bow_shotgun_animation():
	animation_tree.set("parameters/BowAnimation/blend_amount", 1)
	bow_state_machine_playback.travel("Bow ShotGunFullAttack")
	GameManager.set_is_attacking(true)
	GameManager.set_is_heavy_attacking(true)
	heavy_attack_bow_animation_timer = max_heavy_attack_bow_animation_timer
	bow_bullet_spawn.get_child(0).stop()
	bow_bullet_spawn.get_child(0).play("HeavyAttack")

func heavy_bow_attack_change_back_to_movement_animation():
	rel_vel_xz = animation_tree.rel_vel_xz
	animation_tree.set("parameters/StateMachine/Walking/blend_position", rel_vel_xz)
	animation_tree.set("parameters/StateMachine/WalkingController/blend_position", rel_vel_xz)
	animation_tree.set("parameters/BowWalkingAnimation/blend_amount", 0)
	animation_tree.set("parameters/BowAnimation/blend_amount", 0)
	bow_state_machine_playback.travel("Rest")
	bow_bullet_spawn.get_child(0).stop()
	GameManager.set_is_attacking(false)
	GameManager.set_is_heavy_attacking(false)
	cooldown_heavy_attack_bow_timer = max_cooldown_heavy_attack_bow

func reset_bow_animations():
	# After normal Bow Attack
	if is_walking_bow and bow_aim_timer <= 0 and bow_shot_timer <= 0:
		bow_attack_change_back_to_movement_animation()
	# After heavy Bow Attack
	if GameManager.get_is_heavy_attacking() and heavy_attack_bow_animation_timer <= 0:
		heavy_bow_attack_change_back_to_movement_animation()

#--------------------BLOCK--------------------
func block():
	#Cancel Block with Dodge (Animations)
	if GameManager.get_is_blocking() and GameManager.get_is_dodging():
		block_change_back_to_movement_animation()
	elif (
		GameManager.get_is_blocking() 
		and !GameManager.get_is_dodging() 
		):
		if player_controller.velocity.length() > 0.2:
			block_blend.filter_enabled = true
		else:
			block_blend.filter_enabled = false
		#use_block = true
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
	if !use_block:
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
	if !use_block:
		animation_tree.set("parameters/BlockAnimation/blend_amount", 1)
		block_state_machine_playback.travel("Block_R")
		use_block = true

func left_block_animation():
	if !use_block:
		animation_tree.set("parameters/BlockAnimation/blend_amount", 1)
		block_state_machine_playback.travel("Block_L")
		use_block = true

#--------------------SHIELD--------------------
func shield_heavy_attack(delta):
	if (
		Input.is_action_pressed("heavy_attack")
		and !GameManager.get_is_dodging() 
		and !GameManager.get_is_sneaking()
		and !GameManager.get_is_blocking()
		and !GameManager.get_is_heavy_attacking()
		and GameManager.get_first_weapon_name() == shield_name
		and cooldown_heavy_attack_shield_timer <= 0
		):
		shield_heavy_attack_animation()
	elif (
		Input.is_action_pressed("swap_weapon")
		and GameManager.get_first_weapon_name() == sword_name
		and GameManager.get_second_weapon_name() == shield_name
		and !GameManager.get_is_dodging() 
		and !GameManager.get_is_sneaking()
		and !GameManager.get_is_blocking()
		and !GameManager.get_is_heavy_attacking()
		and cooldown_heavy_attack_shield_timer <= 0
		and combo_timer <= 0
		):
		shield_heavy_attack_animation_with_sword()
	
	calc_shield_timer(delta)

func shield_heavy_attack_animation():
	animation_tree.set("parameters/ShieldAnimation/blend_amount", 1)
	animation_tree.set("parameters/ShieldAnimationTimeSeek/seek_request", 0)
	shield_hix_box.get_child(1).stop()
	shield_hix_box.get_child(1).play("HeavyAttack")
	GameManager.set_is_heavy_attacking(true)
	GameManager.set_is_attacking(true)
	heavy_attack_shield_animation_timer = max_heavy_attack_shield_animation_timer

func calc_heavy_attack_shield_animation_timer(delta):
	if heavy_attack_shield_animation_timer > 0:
		heavy_attack_shield_animation_timer -= delta
		heavy_attack_shield_change_back_to_movement_animation()

func heavy_attack_shield_change_back_to_movement_animation():
	if heavy_attack_shield_animation_timer <= 0:
		reset_heavy_attack_shield_animation()
		rel_vel_xz = animation_tree.rel_vel_xz
		animation_tree.set("parameters/StateMachine/Walking/blend_position", rel_vel_xz)
		animation_tree.set("parameters/StateMachine/WalkingController/blend_position", rel_vel_xz)

func calc_cooldown_heavy_attack_shield_timer(delta):
	if cooldown_heavy_attack_shield_timer > 0:
		cooldown_heavy_attack_shield_timer -= delta

func calc_shield_timer(delta):
	calc_heavy_attack_shield_animation_timer(delta)

func reset_sword_animations_with_shield_heavy_attack():
	if combo_number == 1 or combo_number == 2 or combo_number == 3:
		sword_state_machine_playback.travel("Rest")
		animation_tree.set("parameters/SwordAnimation/blend_amount", 0)
		sword_hit_box.get_child(1).stop()
		combo_number = 0
		GameManager.set_is_sword_hit(false)

func shield_heavy_attack_animation_with_sword():
	shield_heavy_attack_animation()
	reset_sword_animations_with_shield_heavy_attack()
	GameManager.set_is_heavy_attack_shield_with_sword(true)

func reset_heavy_attack_shield_animation():
	GameManager.set_is_heavy_attacking(false)
	GameManager.set_is_attacking(false)
	shield_hix_box.get_child(1).stop()
	animation_tree.set("parameters/ShieldAnimation/blend_amount", 0)
	cooldown_heavy_attack_shield_timer = max_cooldown_heavy_attack_shield
	if GameManager.get_is_heavy_attack_shield_with_sword():
		GameManager.set_is_heavy_attack_shield_with_sword(false)

#--------------------KNOCKDOWN RESET--------------------
func knockdown_reset_attack_and_block_animations(delta):
	knockdown_reset_attack_animations(delta)
	knockdown_reset_block_animations()

func knockdown_reset_attack_animations(delta):
	if GameManager.get_is_attacking() or GameManager.get_is_heavy_attacking():
		match GameManager.get_first_weapon_name():
			sword_name:
				if GameManager.get_is_heavy_attack_shield_with_sword():
					knockdown_reset_heavy_attack_shield_animation()
				else:
					knockdown_reset_attack_and_heavy_attack_sword_animation()
			staff_name:
				knockdown_reset_attack_and_heavy_attack_staff_animation()
			bow_name:
				knockdown_reset_attack_and_heavy_attack_bow_animation()
			shield_name:
				knockdown_reset_heavy_attack_shield_animation()
	calc_cooldowns_for_heavy_attacks(delta)

func knockdown_reset_block_animations():
	if !GameManager.get_is_blocking() and use_block:
		block_change_back_to_movement_animation()

func knockdown_reset_heavy_attack_shield_animation():
	reset_heavy_attack_shield_animation()
	heavy_attack_shield_animation_timer = min_reset_animation_number

func knockdown_reset_attack_and_heavy_attack_sword_animation():
	sword_attack_change_back_to_movement_animation()
	reset_animation_timer = min_reset_animation_number

func knockdown_reset_attack_and_heavy_attack_staff_animation():
	reset_all_attack_staff_animation()
	reset_staff_animation_timer = min_reset_animation_number
	reset_animation_timer = min_reset_animation_number
	heavy_attack_staff_animation_timer = min_reset_animation_number

func knockdown_reset_attack_and_heavy_attack_bow_animation():
	bow_attack_change_back_to_movement_animation()
	delay_reset_bow_shot_animation()
	bow_aim_timer = min_reset_animation_number
	bow_shot_timer = min_reset_animation_number
	heavy_attack_bow_animation_timer = min_reset_animation_number
	if GameManager.get_is_heavy_attacking():
		bow_bullet_spawn.get_child(0).stop()
		GameManager.set_is_heavy_attacking(false)
		cooldown_heavy_attack_bow_timer = max_cooldown_heavy_attack_bow
